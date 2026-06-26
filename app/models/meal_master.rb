class MealMaster < ApplicationRecord
  has_many :meal_ingredients
  has_many :allergen_masters, through: :meal_ingredients

  enum :meal_timing, { breakfast: 0, lunch_or_dinner: 1 }
  enum :category, { staple: 0, main_dish: 1, side_dish: 2, soup: 3, one_dish: 4 }


  validates :name, presence: true
  validates :calories, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :meal_timing, presence: true
  validates :category, presence: true
end
