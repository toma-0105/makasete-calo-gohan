class MealMaster < ApplicationRecord
  enum :meal_timing, { breakfast: 0, lunch_or_dinner: 1 }
  enum :category, { staple: 0, main_dish: 1, side_dish: 2, soup: 3, one_dish: 4 }
  # one_dish: カレーライス・丼物・パスタ・ラーメンなど主食+主菜が一体化した料理

  validates :name, presence: true
  validates :calories, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :meal_timing, presence: true
  validates :category, presence: true
end
