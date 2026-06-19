class AllergenMaster < ApplicationRecord
  has_many :user_allergens
  has_many :users, through: :user_allergens

  enum :category, { mandatory: 0, recommended: 1 }
end
