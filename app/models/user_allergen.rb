class UserAllergen < ApplicationRecord
  belongs_to :user
  belongs_to :allergen_master

  validates :user_id, :allergen_master_id, presence: true
  validates :user_id, uniqueness: { scope: :allergen_master_id }
end
