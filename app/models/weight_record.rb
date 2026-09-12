# 体重記録（1ユーザー・1日につき1件）
class WeightRecord < ApplicationRecord
  belongs_to :user

  validates :weight, presence: true, numericality: { greater_than: 0 }
  validates :recorded_on, presence: true, uniqueness: { scope: :user_id }
end
