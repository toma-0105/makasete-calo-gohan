require 'rails_helper'

RSpec.describe "認証後のリダイレクト", type: :request do
  let(:user) { create(:user, password: "password123") }

  describe "ログイン後" do
    it "マイページにリダイレクトされる" do
      post user_session_path, params: {
        user: { email: user.email, password: "password123" }
      }
      expect(response).to redirect_to(mypage_path)
    end
  end

  describe "会員登録後" do
    it "TDEE診断画面にリダイレクトされる" do
      post user_registration_path, params: {
        user: {
          name:                  "新規ユーザー",
          email:                 "new_user@example.com",
          password:              "password123",
          password_confirmation: "password123"
        }
      }
      expect(response).to redirect_to(new_tdee_profile_path)
    end
  end
end
