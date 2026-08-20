require 'rails_helper'

RSpec.describe "パスワード再設定", type: :request do
  let(:user) { create(:user, password: "password123") }

  describe "PUT /users/password" do
    context "有効なトークンで正しい新パスワードを送信した場合" do
      it "パスワードが更新され、マイページへリダイレクトされる" do
        token = user.send_reset_password_instructions

        put user_password_path, params: {
          user: {
            reset_password_token: token,
            password: "newpassword123",
            password_confirmation: "newpassword123"
          }
        }

        expect(response).to redirect_to(mypage_path)
        expect(user.reload.valid_password?("newpassword123")).to be true
      end
    end

    context "新パスワードが短すぎる場合" do
      it "更新に失敗し、パスワードは変更されない" do
        token = user.send_reset_password_instructions

        put user_password_path, params: {
          user: {
            reset_password_token: token,
            password: "abc12",
            password_confirmation: "abc12"
          }
        }

        expect(response).to have_http_status(:unprocessable_entity)
        expect(user.reload.valid_password?("password123")).to be true
      end
    end

    context "パスワード確認が一致しない場合" do
      it "更新に失敗し、パスワードは変更されない" do
        token = user.send_reset_password_instructions

        put user_password_path, params: {
          user: {
            reset_password_token: token,
            password: "newpassword123",
            password_confirmation: "differentpassword"
          }
        }

        expect(response).to have_http_status(:unprocessable_entity)
        expect(user.reload.valid_password?("password123")).to be true
      end
    end
  end

  describe "GET /users/password/edit" do
    context "reset_password_tokenが無い場合" do
      it "ログイン画面へリダイレクトされる" do
        get edit_user_password_path

        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end
