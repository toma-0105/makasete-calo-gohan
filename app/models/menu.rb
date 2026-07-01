class Menu < ApplicationRecord
  belongs_to :user
  has_many :meals, dependent: :destroy

  validates :date, presence: true
  validates :total_calories, presence: true, numericality: { greater_than: 0 }
end
