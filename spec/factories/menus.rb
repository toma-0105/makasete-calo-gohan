FactoryBot.define do
  factory :menu do
    association :user
    date           { Date.today }
    total_calories { 2000 }
    saved          { false }

    # 保存済みの献立
    trait :saved do
      saved { true }
    end
  end
end
