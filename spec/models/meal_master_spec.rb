require 'rails_helper'

RSpec.describe MealMaster, type: :model do
  let(:meal_master) { build(:meal_master) }

  describe "バリデーション" do
    context "正常な場合" do
      it "全項目が入力されていれば有効" do
        expect(meal_master).to be_valid
      end
    end

    context "名前が未入力の場合" do
      it "無効になる" do
        meal_master.name = nil
        expect(meal_master).not_to be_valid
      end
    end

    context "カロリーが未入力の場合" do
      it "無効になる" do
        meal_master.calories = nil
        expect(meal_master).not_to be_valid
      end
    end

    context "カロリーが0以下の場合" do
      it "無効になる" do
        meal_master.calories = 0
        expect(meal_master).not_to be_valid
      end
    end

    context "カロリーが小数の場合" do
      it "無効になる" do
        meal_master.calories = 500.5
        expect(meal_master).not_to be_valid
      end
    end

    context "meal_timingが未入力の場合" do
      it "無効になる" do
        meal_master.meal_timing = nil
        expect(meal_master).not_to be_valid
      end
    end

    context "categoryが未入力の場合" do
      it "無効になる" do
        meal_master.category = nil
        expect(meal_master).not_to be_valid
      end
    end
  end
end
