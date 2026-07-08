# ゲストログイン（アカウントを自動生成してそのままログインする）
class GuestSessionsController < ApplicationController
  def create
    user = GuestUserCreateService.new.create!
    sign_in(user)
    # ゲストは必ず未診断のため、会員登録と同様にTDEE診断へ直行させる
    redirect_to new_tdee_profile_path, notice: "ゲストとしてログインしました"
  end
end
