FactoryBot.define do
  factory :meal do
    association :menu
    association :meal_master
    meal_timing   { :breakfast }
    portion_scale { 1.0 }
    calories      { 252 }
  end
end
