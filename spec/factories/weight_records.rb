FactoryBot.define do
  factory :weight_record do
    user
    weight { 65.0 }
    recorded_on { Date.current }
  end
end
