# 既存の献立から対象の1食（meal_timing）だけを削除して選び直すサービス
class MealRegenerateService
  def initialize(menu, meal_timing, tdee_profile)
    @menu         = menu
    @meal_timing  = meal_timing.to_sym
    @tdee_profile = tdee_profile
  end

  def regenerate!
    # 候補の選定はDB書き込みを伴わないためトランザクションの外で行う
    new_meals = generate_new_meals

    ApplicationRecord.transaction do
      @menu.meals.where(meal_timing: @meal_timing).destroy_all
      save_meals!(new_meals)
      @menu.update!(total_calories: @menu.meals.sum(:calories))
    end

    @menu
  end

  private

  def generate_new_meals
    MenuGeneratorService.new(
      excluded_meal_master_ids: excluded_meal_master_ids,
      target_calories: @tdee_profile.target_calories
    ).generate_for(@meal_timing)
  end

  # 現在の3食に使われている料理と、アレルギー食材を含む料理を候補から除外する（#164）
  def excluded_meal_master_ids
    @menu.meals.pluck(:meal_master_id) + AllergenExclusionService.new(@tdee_profile.user).excluded_meal_master_ids
  end

  def save_meals!(selected_meals)
    selected_meals.each do |selected|
      Meal.create!(
        menu:          @menu,
        meal_master:   selected.meal_master,
        meal_timing:   @meal_timing,
        portion_scale: selected.portion_scale,
        calories:      selected.calories
      )
    end
  end
end
