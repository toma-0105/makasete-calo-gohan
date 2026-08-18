class MealsController < ApplicationController
  before_action :authenticate_user!

  # 対象の1食（meal_timing）だけを別の候補に入れ替える
  def regenerate
    menu = current_user.menus.find(params[:menu_id])
    tdee_profile = current_user.tdee_profiles.last
    unless tdee_profile
      return redirect_to new_tdee_profile_path, alert: "先にTDEE診断を行ってください"
    end

    MealRegenerateService.new(menu, params[:meal_timing], tdee_profile).regenerate!
    redirect_to menu_path(menu)
  end
end
