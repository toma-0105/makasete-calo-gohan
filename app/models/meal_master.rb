class MealMaster < ApplicationRecord
  has_many :meal_ingredients
  has_many :allergen_masters, through: :meal_ingredients

  enum :meal_timing, { breakfast: 0, lunch_or_dinner: 1 }
  enum :category, { staple: 0, main_dish: 1, side_dish: 2, soup: 3, one_dish: 4 }
  # 分量の変え方（fixed: 調整不可 / gram_scalable: グラム調整可 / unit_scalable: 個数調整のみ）
  enum :scaling_type, { fixed: 0, gram_scalable: 1, unit_scalable: 2 }
  # 料理のジャンル（neutral: 汎用＝どのジャンルとも組み合わせ可 / japanese: 和 / western: 洋 / chinese: 中華・アジア）
  enum :genre, { neutral: 0, japanese: 1, western: 2, chinese: 3 }

  validates :name, presence: true
  validates :calories, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :meal_timing, presence: true
  validates :category, presence: true
  validates :scaling_type, presence: true
  validates :genre, presence: true
end
