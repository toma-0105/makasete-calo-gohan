FactoryBot.define do
  factory :menu do
    association :user
    date           { Date.today }
    total_calories { 2000 }
  end
end
