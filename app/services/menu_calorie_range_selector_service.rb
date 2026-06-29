class MenuCalorieRangeSelectorService
  # 許容範囲の下限（target_caloriesに対する割合）
  MIN_CALORIE_RATIO = 0.9
  # 再生成を試みる上限回数
  MAX_ATTEMPTS = 10

  def initialize(tdee_profile)
    @target_calories = tdee_profile.target_calories
    @min_calories = @target_calories * MIN_CALORIE_RATIO
  end

  def generate
    closest_menu = nil
    closest_diff = Float::INFINITY

    MAX_ATTEMPTS.times do
      menu = MenuGeneratorService.new.generate
      total_calories = total_calories_for(menu)

      return menu if within_range?(total_calories)

      diff = (@target_calories - total_calories).abs
      if diff < closest_diff
        closest_diff = diff
        closest_menu = menu
      end
    end

    closest_menu
  end

  private

  def total_calories_for(menu)
    menu.values.flatten.sum(&:calories)
  end

  def within_range?(total_calories)
    total_calories.between?(@min_calories, @target_calories)
  end
end
