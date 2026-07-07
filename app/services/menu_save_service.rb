class MenuSaveService
  def initialize(user, menu_hash)
    @user      = user
    @menu_hash = menu_hash
  end

  def save!
    ApplicationRecord.transaction do
      menu = Menu.create!(
        user:           @user,
        date:           Date.today,
        total_calories: total_calories
      )
      save_meals!(menu)
      menu
    end
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
