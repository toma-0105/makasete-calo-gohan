class GuestPromotionsController < ApplicationController
  before_action :authenticate_user!
  before_action :reject_member_user

  def new
    @user = current_user
  end

  def create
      @user = current_user
      if GuestPromotionService.new(@user, promotion_params).promote
        bypass_sign_in(@user)
        redirect_to mypage_path, notice: "会員登録が完了しました！"
      else
        render :new, status: :unprocessable_entity
      end
    end

    private

  def promotion_params
    params.require(:user).permit(:name, :email, :password, :password_confirmation)
  end

  # 会員が昇格ページに来ても意味がないのでマイページへ返す
  def reject_member_user
    redirect_to mypage_path unless current_user.guest?
  end
end
