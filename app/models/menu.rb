class Menu < ApplicationRecord
  self.ignored_columns += %w[saved]

  belongs_to :user
  has_many :meals, dependent: :destroy

  validates :date, presence: true, uniqueness: { scope: :user_id }
  validates :total_calories, presence: true, numericality: { greater_than: 0 }
end
