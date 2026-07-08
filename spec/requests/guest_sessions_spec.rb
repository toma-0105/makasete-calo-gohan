require 'rails_helper'

RSpec.describe "GuestSessions", type: :request do
  describe "POST /guest_login" do
    it "ゲストユーザーが作成される" do
      expect { post guest_login_path }.to change(User.where(guest: true), :count).by(1)
    end

    it "ログイン状態になり、TDEE診断画面にリダイレクトされる" do
      post guest_login_path
      expect(response).to redirect_to(new_tdee_profile_path)

      # リダイレクト先にアクセスできる＝ログイン済み（未ログインならログイン画面へ飛ばされる）
      follow_redirect!
      expect(response).to have_http_status(:ok)
    end

    it "ゲストログインのフラッシュメッセージが設定される" do
      post guest_login_path
      expect(flash[:notice]).to eq("ゲストとしてログインしました")
    end
  end
end
