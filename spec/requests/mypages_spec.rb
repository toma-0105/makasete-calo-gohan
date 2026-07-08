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

      it "献立履歴へのリンクが表示される" do
        expect(response.body).to include("献立履歴を見る")
      end
    end

    context "ゲストとしてログインしている場合" do
      before do
        sign_in create(:user, guest: true)
        get mypage_path
      end

      it "献立履歴へのリンクが表示されない" do
        expect(response.body).not_to include("献立履歴を見る")
      end
    end

    context "TDEE未診断のユーザーの場合" do
      let(:user) { create(:user) }

      before do
        sign_in user
        get mypage_path
      end

      it "「TDEE診断を始める」ボタンが表示される" do
        expect(response.body).to include("TDEE診断を始める")
        expect(response.body).to include(new_tdee_profile_path)
      end

      it "再診断リンクは表示されない" do
        expect(response.body).not_to include("TDEEを再診断する")
      end
    end

    context "TDEE診断済みのユーザーの場合" do
      let(:user) { create(:user) }

      before do
        create(:tdee_profile, user: user, tdee: 2200)
        sign_in user
        get mypage_path
      end

      it "「TDEEを再診断する」リンクが表示される" do
        expect(response.body).to include("TDEEを再診断する")
      end

      it "「TDEE診断を始める」ボタンは表示されない" do
        expect(response.body).not_to include("TDEE診断を始める")
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
