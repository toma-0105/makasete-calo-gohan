class Meal < ApplicationRecord
  belongs_to :menu
  belongs_to :meal_master

  enum :meal_timing, { breakfast: 0, lunch: 1, dinner: 2 }

  validates :meal_timing, presence: true
  validates :calories, presence: true, numericality: { greater_than: 0 }
  validates :portion_scale, presence: true, numericality: { greater_than: 0 }
end
