class Menu < ApplicationRecord
  belongs_to :user
  has_many :meals, dependent: :destroy

  validates :date, presence: true
  validates :total_calories, presence: true, numericality: { greater_than: 0 }

  # 保存済みの献立のみ（献立履歴一覧で使用）
  scope :saved, -> { where(saved: true) }
end
