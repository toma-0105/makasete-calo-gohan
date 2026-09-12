require "rails_helper"

RSpec.describe WeightRecord, type: :model do
  it "有効なファクトリを持つこと" do
    expect(build(:weight_record)).to be_valid
  end

  it "体重がないと無効であること" do
    weight_record = build(:weight_record, weight: nil)
    expect(weight_record).to be_invalid
  end

  it "同じユーザー・同じ記録日の組み合わせは無効であること" do
    existing = create(:weight_record)
    duplicated = build(:weight_record, user: existing.user, recorded_on: existing.recorded_on)
    expect(duplicated).to be_invalid
  end
end
