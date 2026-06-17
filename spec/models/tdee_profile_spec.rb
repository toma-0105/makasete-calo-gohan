require 'rails_helper'

RSpec.describe TdeeProfile, type: :model do
  let(:user) { create(:user) }
  let(:tdee_profile) do
    build(:tdee_profile, user: user)
  end

  describe "バリデーション" do
    context "正常な場合" do
      it "全項目が入力されていれば有効" do
        expect(tdee_profile).to be_valid
      end
    end

    context "身長が未入力の場合" do
      it "無効になる" do
        tdee_profile.height = nil
        expect(tdee_profile).not_to be_valid
      end
    end

    context "体重が未入力の場合" do
      it "無効になる" do
        tdee_profile.weight = nil
        expect(tdee_profile).not_to be_valid
      end
    end

    context "年齢が未入力の場合" do
      it "無効になる" do
        tdee_profile.age = nil
        expect(tdee_profile).not_to be_valid
      end
    end

    context "性別が未入力の場合" do
      it "無効になる" do
        tdee_profile.gender = nil
        expect(tdee_profile).not_to be_valid
      end
    end

    context "活動レベルが未入力の場合" do
      it "無効になる" do
        tdee_profile.activity_level = nil
        expect(tdee_profile).not_to be_valid
      end
    end

    context "身長が0以下の場合" do
      it "無効になる" do
        tdee_profile.height = 0
        expect(tdee_profile).not_to be_valid
      end
    end

    context "体重が0以下の場合" do
      it "無効になる" do
        tdee_profile.weight = 0
        expect(tdee_profile).not_to be_valid
      end
    end

    context "年齢が0以下の場合" do
      it "無効になる" do
        tdee_profile.age = 0
        expect(tdee_profile).not_to be_valid
      end
    end

    context "年齢が小数の場合" do
      it "無効になる" do
        tdee_profile.age = 20.5
        expect(tdee_profile).not_to be_valid
      end
    end 
  end
end
