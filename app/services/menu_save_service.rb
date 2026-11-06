class MenuSaveService
  def initialize(user, menu_hash, date: Date.current)
    @user      = user
    @menu_hash = menu_hash
    @date      = date
  end

  def save!
    ApplicationRecord.transaction do
      menu = Menu.create!(
        user:           @user,
        date:           @date,
        total_calories: total_calories
      )
      save_meals!(menu)
      menu
    end
  end

  # 既存の献立の中身（meals・合計カロリー）を、menu_hashの内容に差し替える
  # Menu自体は作り直さないため、id・日付・作成日時は変わらない
  def replace!(menu)
    # with_lockで献立の行をロックし、トランザクションも兼ねる
    # ・連打などで同時に再生成されても順番に処理され、mealsが二重に作られるのを防ぐ
    # ・途中で失敗したら削除もロールバックされ、献立が空になるのを防ぐ
    menu.with_lock do
      menu.meals.destroy_all
      menu.update!(total_calories: total_calories)
      save_meals!(menu)
    end
    menu
  end

  private

  def total_calories
    @menu_hash.values.flatten.sum(&:calories)
  end

  def save_meals!(menu)
    @menu_hash.each do |meal_timing, selected_meals|
      selected_meals.each do |selected|
        Meal.create!(
          menu:          menu,
          meal_master:   selected.meal_master,
          meal_timing:   meal_timing,
          portion_scale: selected.portion_scale,
          calories:      selected.calories
        )
      end
    end
  end
end
