# ゲストログイン（アカウントを自動生成してそのままログインする）
class GuestSessionsController < ApplicationController
  # ログイン中に実行されると、会員のセッションがゲストに置き換わったり、
  # ゲストのデータが見えなくなったりするため、アカウントを作る前にホームへ戻す（#358）
  before_action :redirect_signed_in_user, only: :create

  def create
    user = GuestUserCreateService.new.create!
    sign_in(user)
    # ゲストも会員登録と同じオンボーディング（アレルギー設定 → TDEE診断）へ直行させる
    redirect_to new_user_allergen_path, notice: "ゲストとしてログインしました"
  end

  private

  def redirect_signed_in_user
    redirect_to home_path_for(current_user) if user_signed_in?
  end
end
