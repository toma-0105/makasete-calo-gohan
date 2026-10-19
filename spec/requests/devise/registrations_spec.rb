require "rails_helper"

RSpec.describe "会員登録まわりのルート", type: :request do
  describe "閉じたルート（登録情報の編集・退会）" do
    let(:user) { create(:user) }

    # ログイン済みでもアクセスできないことを確認する（未ログインだと認証エラーと区別できないため）
    before { sign_in user }

    it "編集画面（GET /users/edit）は存在しない" do
      get "/users/edit"
      expect(response).to have_http_status(:not_found)
    end

    it "登録情報の更新（PATCH /users）は存在せず、名前も変わらない" do
      patch "/users", params: { user: { name: "変更後の名前" } }
      expect(response).to have_http_status(:not_found)
      expect(user.reload.name).not_to eq("変更後の名前")
    end

    it "退会（DELETE /users）は存在せず、ユーザーも削除されない" do
      expect { delete "/users" }.not_to change(User, :count)
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "残したルート（新規登録）" do
    it "新規登録画面（GET /users/sign_up）を表示できる" do
      get new_user_registration_path
      expect(response).to have_http_status(:ok)
    end
  end
end
