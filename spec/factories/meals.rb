FactoryBot.define do
  factory :meal do
    association :menu
    association :meal_master
    meal_timing { :breakfast }
  end
end
