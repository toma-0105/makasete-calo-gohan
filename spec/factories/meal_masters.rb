FactoryBot.define do
  factory :meal_master do
    name { "ご飯茶碗一杯(150g)" }
    calories { 252 }
    meal_timing { :breakfast }
    category { :staple }
    scaling_type { :gram_scalable }
    # meal_timing: breakfast / lunch_or_dinner の2値
    # category: staple(主食) / main_dish(主菜) / side_dish(副菜) / soup(汁物) の4値
    # scaling_type: fixed(調整不可) / gram_scalable(グラム調整可) / unit_scalable(個数調整のみ) の3値
  end
end
