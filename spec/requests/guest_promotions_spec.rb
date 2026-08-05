require 'rails_helper'

RSpec.describe "GuestPromotions", type: :request do
  let(:guest) { create(:user, guest: true) }
  let(:member) { create(:user) }

  let(:valid_params) do
    {
      user: {
        name: "昇格ユーザー",
        email: "promoted@example.com",
        password: "newpassword123",
        password_confirmation: "newpassword123"
      }
    }
  end

  describe "GET /guest_promotion/new" do
    context "ログインしていない場合" do
      it "ログインページにリダイレクトされる" do
        get new_guest_promotion_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "正規会員でログインしている場合" do
      before { sign_in member }

      it "マイページにリダイレクトされる" do
        get new_guest_promotion_path
        expect(response).to redirect_to(mypage_path)
      end
    end

    context "ゲストでログインしている場合" do
      before { sign_in guest }

      it "200 OKを返す" do
        get new_guest_promotion_path
        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe "POST /guest_promotion" do
    context "ゲストが有効なパラメータで昇格する場合" do
      before { sign_in guest }

      it "マイページにリダイレクトされ、完了メッセージが表示される" do
        post guest_promotion_path, params: valid_params
        expect(response).to redirect_to(mypage_path)
        expect(flash[:notice]).to eq("会員登録が完了しました！")
      end

      it "guestフラグがfalseに更新される" do
        expect {
          post guest_promotion_path, params: valid_params
        }.to change { guest.reload.guest }.from(true).to(false)
      end
    end

    context "パスワードが一致しない場合" do
      before { sign_in guest }

      it "422を返し、guestフラグは変わらない" do
        post guest_promotion_path,
             params: { user: valid_params[:user].merge(password_confirmation: "mismatch") }
        # :unprocessable_entity は Rack で非推奨になったため新名称を使う（ステータスコードは同じ422）
        expect(response).to have_http_status(:unprocessable_content)
        expect(guest.reload.guest).to be true
      end
    end

    context "正規会員がリクエストした場合" do
      before { sign_in member }

      it "昇格処理は行われずマイページにリダイレクトされる" do
        expect {
          post guest_promotion_path, params: valid_params
        }.not_to change { member.reload.email } # 会員のデータが書き換えられないこと
        expect(response).to redirect_to(mypage_path)
      end
    end
  end
end
