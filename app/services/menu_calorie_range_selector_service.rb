class MenuCalorieRangeSelectorService
  # 許容範囲の下限（target_caloriesに対する割合）
  MIN_CALORIE_RATIO = 0.9
  # 再生成を試みる上限回数
  MAX_ATTEMPTS = 10

  def initialize(tdee_profile, additional_excluded_meal_master_ids: [])
    @target_calories = tdee_profile.target_calories
    @min_calories = @target_calories * MIN_CALORIE_RATIO
    @excluded_meal_master_ids =
      AllergenExclusionService.new(tdee_profile.user).excluded_meal_master_ids +
      additional_excluded_meal_master_ids
    @favorite_meal_master_ids = tdee_profile.user.favorites.pluck(:meal_master_id)
  end

  def generate
    closest_menu = nil
    closest_diff = Float::INFINITY

    MAX_ATTEMPTS.times do
      menu = generate_menu
      total_calories = total_calories_for(menu)

      return menu if within_range?(total_calories)

      diff = (@target_calories - total_calories).abs
      next unless diff < closest_diff

      closest_menu = menu
      closest_diff = diff
    end

    # 許容範囲に収まらなかった場合は、最も目標に近かった献立を返す
    closest_menu
  end

  private

  # 目標カロリーを渡し、生成側で配分・倍率調整を行う
  def generate_menu
    MenuGeneratorService.new(
      excluded_meal_master_ids: @excluded_meal_master_ids,
      target_calories: @target_calories,
      favorite_meal_master_ids: @favorite_meal_master_ids
    ).generate
  end

  def total_calories_for(menu)
    menu.values.flatten.sum(&:calories)
  end

  def within_range?(total_calories)
    total_calories.between?(@min_calories, @target_calories)
  end
end
