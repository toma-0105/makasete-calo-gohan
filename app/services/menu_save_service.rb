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
    @menu_hash.each do |meal_timing, meal_masters|
      meal_masters.each do |meal_master|
        Meal.create!(
          menu:        menu,
          meal_master: meal_master,
          meal_timing: meal_timing
        )
      end
    end
  end
end
