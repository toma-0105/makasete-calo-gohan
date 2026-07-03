class MenusController < ApplicationController
  before_action :authenticate_user!

  def create
    tdee_profile = current_user.tdee_profiles.last
    unless tdee_profile
      return redirect_to new_tdee_profile_path, alert: "先にTDEE診断を行ってください"
    end

    menu_hash = MenuCalorieRangeSelectorService.new(tdee_profile).generate
    menu = MenuSaveService.new(current_user, menu_hash).save!
    redirect_to menu_path(menu)
  end

  def show
    @menu = current_user.menus.includes(meals: :meal_master).find(params[:id])
    @meals_by_timing = @menu.meals.group_by(&:meal_timing)
    @tdee_profile = current_user.tdee_profiles.last
  end

  # 既存の献立を削除して新しい献立を生成し直す
  def regenerate
    old_menu = current_user.menus.find(params[:id])
    tdee_profile = current_user.tdee_profiles.last
    unless tdee_profile
      return redirect_to new_tdee_profile_path, alert: "先にTDEE診断を行ってください"
    end

    new_menu = MenuRegenerateService.new(current_user, old_menu, tdee_profile).regenerate!
    redirect_to menu_path(new_menu)
  end
end
