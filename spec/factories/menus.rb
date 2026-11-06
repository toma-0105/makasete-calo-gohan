FactoryBot.define do
  factory :menu do
    association :user
    date           { Date.current }
    total_calories { 2000 }
  end
end
