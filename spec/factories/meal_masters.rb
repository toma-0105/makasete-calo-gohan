FactoryBot.define do
  factory :meal_master do
    name { "ご飯茶碗一杯(150g)" }
    calories { 252 }
    meal_timing { :breakfast }
    category { :staple }
    # meal_timing: breakfast / lunch_or_dinner の2値
    # category: staple(主食) / main_dish(主菜) / side_dish(副菜) / soup(汁物) の4値
  end
end
