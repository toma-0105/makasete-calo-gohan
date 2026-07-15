# ゲストログイン（アカウントを自動生成してそのままログインする）
class GuestSessionsController < ApplicationController
  def create
    user = GuestUserCreateService.new.create!
    sign_in(user)
    # ゲストも会員登録と同じオンボーディング（アレルギー設定 → TDEE診断）へ直行させる
    redirect_to new_user_allergen_path, notice: "ゲストとしてログインしました"
  end
end
