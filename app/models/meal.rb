class Meal < ApplicationRecord
  belongs_to :menu
  belongs_to :meal_master

  enum :meal_timing, { breakfast: 0, lunch: 1, dinner: 2 }

  validates :meal_timing, presence: true
end
