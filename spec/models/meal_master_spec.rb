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
        describe "ingredients（材料）のバリデーション" do
      context "未設定（空配列）の場合" do
        it "有効になる" do
          meal_master.ingredients = []
          expect(meal_master).to be_valid
        end
      end

      context "配列以外が保存された場合" do
        it "無効になる" do
          meal_master.ingredients = "鶏むね肉100g"
          expect(meal_master).not_to be_valid
        end
      end

      context "nameが欠けている材料がある場合" do
        it "無効になる" do
          meal_master.ingredients = [ { "name" => "", "amount" => "100g" } ]
          expect(meal_master).not_to be_valid
        end
      end

      context "amountが欠けている材料がある場合" do
        it "無効になる" do
          meal_master.ingredients = [ { "name" => "鶏むね肉", "amount" => "" } ]
          expect(meal_master).not_to be_valid
        end
      end

      context "name・amountが揃っている場合" do
        it "有効になる" do
          meal_master.ingredients = [ { "name" => "鶏むね肉", "amount" => "100g" } ]
          expect(meal_master).to be_valid
        end
      end
    end

    describe "steps（手順）のバリデーション" do
      context "未設定（空配列）の場合" do
        it "有効になる" do
          meal_master.steps = []
          expect(meal_master).to be_valid
        end
      end

      context "配列以外が保存された場合" do
        it "無効になる" do
          meal_master.steps = "フライパンで焼く"
          expect(meal_master).not_to be_valid
        end
      end

      context "空の手順が含まれる場合" do
        it "無効になる" do
          meal_master.steps = [ "鶏肉を切る", "" ]
          expect(meal_master).not_to be_valid
        end
      end

      context "すべての手順に内容がある場合" do
        it "有効になる" do
          meal_master.steps = [ "鶏肉を切る", "焼く" ]
          expect(meal_master).to be_valid
        end
      end
    end
  end
end
