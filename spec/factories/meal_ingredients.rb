FactoryBot.define do
  factory :meal_ingredient do
    association :meal_master
    association :allergen_master
  end
end
