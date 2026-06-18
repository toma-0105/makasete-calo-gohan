class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

         validates :name, presence: true, unless: :guest?

         has_many :user_allergens
         has_many :allergens, through: :user_allergens
end
