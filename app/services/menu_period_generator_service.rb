class MenuPeriodGeneratorService
  # 生成できる日数の下限・上限
  MIN_GENERATION_DAYS = 1
  MAX_GENERATION_DAYS = 7

  def initialize(user, tdee_profile, days:)
    @user = user
    @tdee_profile = tdee_profile
    @days = days
  end

  # 指定日数分のMenuを生成・保存し、生成したMenuの配列を返す
  def generate!
    unless (MIN_GENERATION_DAYS..MAX_GENERATION_DAYS).cover?(@days)
    raise ArgumentError, "daysは#{MIN_GENERATION_DAYS}〜#{MAX_GENERATION_DAYS}の範囲で指定してください"
    end

    used_meal_master_ids = []

    Array.new(@days) do |i|
      menu_hash = MenuCalorieRangeSelectorService.new(
        @tdee_profile,
        additional_excluded_meal_master_ids: used_meal_master_ids
      ).generate

      used_meal_master_ids.concat(menu_hash.values.flatten.map { |selected| selected.meal_master.id })

      MenuSaveService.new(@user, menu_hash, date: Date.today + i.days).save!
    end
  end
end
