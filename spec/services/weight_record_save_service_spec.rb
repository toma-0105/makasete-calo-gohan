require "rails_helper"

RSpec.describe WeightRecordSaveService do
  describe "#save!" do
    let(:user) { create(:user) }

    context "TDEE診断済みのユーザーの場合" do
      before { create(:tdee_profile, user: user) }

      it "体重連動のプロフィール（weight_sync）が1件増える" do
        expect {
          described_class.new(user, weight: 60.0, recorded_on: Date.current).save!
        }.to change { user.tdee_profiles.weight_sync.count }.by(1)
      end

      it "手動診断のプロフィール（diagnosis）は増えない" do
        expect {
          described_class.new(user, weight: 60.0, recorded_on: Date.current).save!
        }.not_to change { user.tdee_profiles.diagnosis.count }
      end
    end
  end
end
