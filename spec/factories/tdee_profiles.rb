FactoryBot.define do
  factory :tdee_profile do
    association :user
    height { 170.0 }
    weight { 100.0 }
    age { 20 }
    gender { :male }
    activity_level { :lightly_active }
    tdee { nil }
  end
end
