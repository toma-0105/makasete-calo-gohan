class MealIngredient < ApplicationRecord
  belongs_to :meal_master
  belongs_to :allergen_master

  validates :meal_master_id, uniqueness: { scope: :allergen_master_id }
end
