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
end
