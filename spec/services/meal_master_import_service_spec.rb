require 'rails_helper'

RSpec.describe MealMasterImportService do
  subject(:service) { described_class.new }

  let(:recipe) do
    {
      "name" => "鶏むね肉のレモン塩麹グリル(100g)",
      "meal_timing" => "lunch_or_dinner",
      "category" => "main_dish",
      "scaling_type" => "gram_scalable",
      "genre" => "japanese",
      "calories" => 150,
      "protein" => 24,
      "fat" => 4,
      "carbohydrate" => 2,
      "ingredients" => [
        { "name" => "鶏むね肉", "amount" => "100g" }
      ],
      "steps" => [ "鶏むね肉を焼く" ],
      "allergens" => [ "鶏肉" ]
    }
  end

  before { create(:allergen_master, name: "鶏肉") }

  describe "#import" do
    it "MealMasterが作成される" do
      expect { service.import(recipe) }.to change(MealMaster, :count).by(1)
    end

    it "レシピの属性がそのまま保存される" do
      meal_master = service.import(recipe)
      expect(meal_master).to have_attributes(
        name: "鶏むね肉のレモン塩麹グリル(100g)",
        calories: 150,
        protein: 24,
        fat: 4,
        carbohydrate: 2,
        ingredients: [ { "name" => "鶏むね肉", "amount" => "100g" } ],
        steps: [ "鶏むね肉を焼く" ]
      )
    end

    it "allergensで指定したアレルゲンと紐づく" do
      meal_master = service.import(recipe)
      expect(meal_master.allergen_masters.pluck(:name)).to eq([ "鶏肉" ])
    end

    context "allergensが複数ある場合" do
      let(:recipe) { super().merge("allergens" => [ "鶏肉", "卵" ]) }

      before { create(:allergen_master, name: "卵") }

      it "複数のMealIngredientが作られる" do
        meal_master = service.import(recipe)
        expect(meal_master.allergen_masters.pluck(:name)).to contain_exactly("鶏肉", "卵")
      end
    end

    context "allergensが空配列の場合" do
      let(:recipe) { super().merge("allergens" => []) }

      it "MealIngredientは作られない" do
        expect { service.import(recipe) }.not_to change(MealIngredient, :count)
      end
    end
  end

  describe "#backfill" do
    let!(:meal_master) { create(:meal_master, name: "鶏むね肉のレモン塩麹グリル(100g)", meal_timing: :breakfast, calories: 150) }

    let(:backfill_recipe) do
      {
        "name" => "鶏むね肉のレモン塩麹グリル(100g)",
        "meal_timing" => "breakfast",
        "protein" => 24,
        "fat" => 4,
        "carbohydrate" => 2,
        "ingredients" => [ { "name" => "鶏むね肉", "amount" => "100g" } ],
        "steps" => [ "鶏むね肉を焼く" ]
      }
    end

    it "既存レコードのPFC・材料・手順が更新される" do
      service.backfill(backfill_recipe)
      expect(meal_master.reload).to have_attributes(
        protein: 24,
        fat: 4,
        carbohydrate: 2,
        ingredients: [ { "name" => "鶏むね肉", "amount" => "100g" } ],
        steps: [ "鶏むね肉を焼く" ]
      )
    end

    it "MealMasterの件数は増えない" do
      expect { service.backfill(backfill_recipe) }.not_to change(MealMaster, :count)
    end

    context "既にアレルゲンが紐づいている場合" do
      before { create(:meal_ingredient, meal_master: meal_master, allergen_master: create(:allergen_master, name: "鶏肉")) }

      it "MealIngredientの件数は変わらない（バックフィルはアレルゲンに触れないため）" do
        expect { service.backfill(backfill_recipe) }.not_to change(MealIngredient, :count)
      end
    end

    context "該当する名前のレコードが存在しない場合" do
      let(:backfill_recipe) { super().merge("name" => "存在しない料理") }

      it "RecordNotFoundが発生する" do
        expect { service.backfill(backfill_recipe) }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context "同じ名前で朝食用・昼夕用の2レコードが存在する場合（ご飯(100g)等を想定）" do
      let!(:breakfast_meal) { create(:meal_master, name: "ご飯(100g)", meal_timing: :breakfast, protein: nil) }
      let!(:lunch_meal) { create(:meal_master, name: "ご飯(100g)", meal_timing: :lunch_or_dinner, protein: nil) }
      let(:backfill_recipe) do
        {
          "name" => "ご飯(100g)",
          "meal_timing" => "lunch_or_dinner",
          "protein" => 3,
          "fat" => 0,
          "carbohydrate" => 37,
          "ingredients" => [],
          "steps" => []
        }
      end

      it "meal_timingが一致するレコードだけが更新される" do
        service.backfill(backfill_recipe)
        expect(lunch_meal.reload.protein).to eq(3)
      end

      it "meal_timingが異なるレコードは更新されない" do
        service.backfill(backfill_recipe)
        expect(breakfast_meal.reload.protein).to be_nil
      end
    end
  end
end
