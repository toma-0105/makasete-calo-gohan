FactoryBot.define do
  factory :tdee_profile do
    user { nil }
    height { "9.99" }
    weight { "9.99" }
    age { 1 }
    gender { 1 }
    activity_level { 1 }
    tdee { "9.99" }
  end
end
