require "rails_helper"

RSpec.describe TdeeReminderService do
  let(:user) { create(:user) }
  let(:service) { described_class.new(user) }
  # 日数をspecに直書きしないよう、サービスの定数を基準にする
  let(:interval) { described_class::REMINDER_INTERVAL_DAYS }

  describe "#needed?" do
    context "未診断のユーザーの場合" do
      it "falseを返す" do
        expect(service.needed?).to be false
      end
    end

    context "最後の手動診断から期間が経っていない場合" do
      it "falseを返す" do
        create(:tdee_profile, user: user, created_at: (interval - 1).days.ago)
        expect(service.needed?).to be false
      end
    end

    context "最後の手動診断から期間が経っている場合" do
      it "trueを返す" do
        create(:tdee_profile, user: user, created_at: interval.days.ago)
        expect(service.needed?).to be true
      end
    end

    context "古い手動診断のあとに体重記録の自動再計算があった場合" do
      it "自動再計算は数えず、trueを返す" do
        create(:tdee_profile, user: user, created_at: (interval + 1).days.ago)
        create(:tdee_profile, user: user, source: :weight_sync, created_at: 1.day.ago)
        expect(service.needed?).to be true
      end
    end

    context "古い手動診断のあとに、新しい手動診断があった場合" do
      it "falseを返す" do
        create(:tdee_profile, user: user, created_at: (interval + 1).days.ago)
        create(:tdee_profile, user: user, created_at: 1.day.ago)
        expect(service.needed?).to be false
      end
    end
  end

  describe "#days_since_diagnosis" do
    it "経過日数を切り捨てて返す" do
      create(:tdee_profile, user: user, created_at: (interval.days + 3.hours).ago)
      expect(service.days_since_diagnosis).to eq interval
    end

    it "未診断ならnilを返す" do
      expect(service.days_since_diagnosis).to be_nil
    end
  end
end
