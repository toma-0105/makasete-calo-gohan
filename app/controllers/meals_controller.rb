class MealsController < ApplicationController
  before_action :authenticate_user!

  # 献立の中の1品だけを、同じカテゴリの別の料理に入れ替える
  def regenerate
    menu = current_user.menus.find(params[:menu_id])
    # menu経由で探すことで、他人の献立の品は見つからず404になる
    meal = menu.meals.find(params[:id])

    MealItemRegenerateService.new(meal).regenerate!
    redirect_to menu_path(menu)
  rescue MealItemRegenerateService::NotSwappableError
    redirect_to menu_path(menu), alert: "この品は入れ替えできません"
  rescue MealItemRegenerateService::NoCandidateError
    redirect_to menu_path(menu), alert: "他の候補がありません"
  end
end
