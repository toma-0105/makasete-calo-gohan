class MypagesController < ApplicationController
  before_action :authenticate_user!
  before_action :reject_guest_user

  def show
    @user = current_user
    @tdee_profile = current_user.tdee_profiles.last
  end

  private

  # マイページは会員限定（ビューでリンクを非表示にした上で、URL直打ちもサーバー側で拒否する）
  def reject_guest_user
    return unless current_user.guest?

    redirect_to home_path_for(current_user), alert: "マイページは会員限定の機能です"
  end
end
