class AllergenMaster < ApplicationRecord
  has_many :user_allergens
  has_many :users, through: :user_allergens
  has_many :meal_ingredients
  has_many :meal_masters, through: :meal_ingredients

  enum :category, { mandatory: 0, recommended: 1 }
end
