require 'rails_helper'

RSpec.describe "Mypages", type: :request do
  describe "GET /mypage" do
    context "ログインしている場合" do
      let(:user) { create(:user, name: "テストユーザー", email: "test@example.com") }

      before do
        sign_in user
        get mypage_path
      end

      it "200 OKを返す" do
        expect(response).to have_http_status(:ok)
      end

      it "ログインユーザーの名前が表示される" do
        expect(response.body).to include("テストユーザー")
      end

      it "ログインユーザーのメールアドレスが表示される" do
        expect(response.body).to include("test@example.com")
      end

      it "アレルギー設定変更へのリンクが表示される" do
        expect(response.body).to include(new_user_allergen_path)
      end
    end

    context "ログインしていない場合" do
      before { get mypage_path }

      it "ログインページにリダイレクトされる" do
        expect(response).to redirect_to(new_user_session_path)
      end

      it "302 Foundを返す" do
        expect(response).to have_http_status(:found)
      end
    end
  end
end
