class TdeeProfile < ApplicationRecord
  belongs_to :user

  enum :gender, { male: 0, female: 1 }
  enum :activity_level, {
    sedentary: 0,
    lightly_active: 1,
    moderately_active: 2,
    very_active: 3,
    super_active: 4
  }

  validates :height, presence: true, numericality: { greater_than: 0 }
  validates :weight, presence: true, numericality: { greater_than: 0 }
  validates :age, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :gender, presence: true
  validates :activity_level, presence: true
end
