require 'rails_helper'

RSpec.describe MealIngredient, type: :model do
  describe 'バリデーション' do
    let(:meal_master) { create(:meal_master) }
    let(:allergen) { create(:allergen_master) }

    it 'meal_master_id と allergen_master_id があれば有効' do
      meal_ingredient = build(:meal_ingredient, meal_master:, allergen_master: allergen)
      expect(meal_ingredient).to be_valid
    end

    it 'meal_master がなければ無効' do
      meal_ingredient = build(:meal_ingredient, meal_master: nil, allergen_master: allergen)
      expect(meal_ingredient).not_to be_valid
    end

    it 'allergen_master がなければ無効' do
      meal_ingredient = build(:meal_ingredient, meal_master:, allergen_master: nil)
      expect(meal_ingredient).not_to be_valid
    end

    it '同じ料理に同じアレルゲンを2回紐づけられない' do
      create(:meal_ingredient, meal_master:, allergen_master: allergen)
      duplicate = build(:meal_ingredient, meal_master:, allergen_master: allergen)
      expect(duplicate).not_to be_valid
    end
  end
end
