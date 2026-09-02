require 'rails_helper'

RSpec.describe RecipeImportService do
  subject(:service) { described_class.new(recipes) }

  let(:result) { service.call }

  let(:valid_recipe) do
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
        { "name" => "鶏むね肉", "amount" => "100g" },
        { "name" => "塩麹", "amount" => "小さじ1(6g)" }
      ],
      "steps" => [
        "鶏むね肉に塩麹をもみ込む",
        "フライパンで焼く"
      ],
      "allergens" => [ "鶏肉" ]
    }
  end

  before { create(:allergen_master, name: "鶏肉") }

  describe "#call" do
    context "正常なレシピの場合" do
      let(:recipes) { [ valid_recipe ] }

      it "valid_recipesに含まれる" do
        expect(result[:valid_recipes]).to eq([ valid_recipe ])
      end

      it "issuesは空になる" do
        expect(result[:issues]).to be_empty
      end
    end

    context "必須項目が欠けている場合" do
      let(:recipes) { [ valid_recipe.except("calories") ] }

      it "valid_recipesに含まれない" do
        expect(result[:valid_recipes]).to be_empty
      end

      it "errorレベルのissueが返る" do
        expect(result[:issues].first.level).to eq(:error)
      end
    end

    context "meal_timingが不正な値の場合" do
      let(:recipes) { [ valid_recipe.merge("meal_timing" => "midnight") ] }

      it "valid_recipesに含まれない" do
        expect(result[:valid_recipes]).to be_empty
      end
    end

    context "未知のアレルゲン名が含まれる場合" do
      let(:recipes) { [ valid_recipe.merge("allergens" => [ "未登録アレルゲン" ]) ] }

      it "valid_recipesに含まれない" do
        expect(result[:valid_recipes]).to be_empty
      end

      it "errorレベルのissueが返る" do
        expect(result[:issues].first.level).to eq(:error)
      end
    end

    context "材料にamountが欠けている場合" do
      let(:recipes) do
        [ valid_recipe.merge("ingredients" => [ { "name" => "鶏むね肉", "amount" => "" } ]) ]
      end

      it "valid_recipesに含まれない" do
        expect(result[:valid_recipes]).to be_empty
      end
    end

    context "材料名が手順に登場しない場合" do
      let(:recipes) do
        [ valid_recipe.merge("ingredients" => valid_recipe["ingredients"] + [ { "name" => "こしょう", "amount" => "少々" } ]) ]
      end

      it "valid_recipesには含まれる（warningは投入を妨げない）" do
        expect(result[:valid_recipes]).to eq(recipes)
      end

      it "warningレベルのissueが返る" do
        expect(result[:issues].first.level).to eq(:warning)
      end
    end

    context "複数レシピのうち一部だけ不正な場合" do
      let(:invalid_recipe) { valid_recipe.except("calories").merge("name" => "不正なレシピ") }
      let(:recipes) { [ valid_recipe, invalid_recipe ] }

      it "有効なレシピだけがvalid_recipesに残る" do
        expect(result[:valid_recipes]).to eq([ valid_recipe ])
      end
    end
  end
end
