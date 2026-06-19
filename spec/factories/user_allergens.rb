FactoryBot.define do
  factory :user_allergen do
    association :user
    association :allergen_master
  end
end
