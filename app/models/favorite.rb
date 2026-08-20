class Favorite < ApplicationRecord
  belongs_to :user
  belongs_to :meal_master

  validates :user_id, uniqueness: { scope: :meal_master_id }
end
