require 'rails_helper'

RSpec.describe Meal, type: :model do
  describe 'バリデーション' do
    it 'Factoryのデフォルト値で有効である' do
      expect(build(:meal)).to be_valid
    end

    it 'calories がない場合は無効である' do
      meal = build(:meal, calories: nil)
      expect(meal).to be_invalid
      expect(meal.errors[:calories]).to be_present
    end

    it 'calories が0以下の場合は無効である' do
      meal = build(:meal, calories: 0)
      expect(meal).to be_invalid
      expect(meal.errors[:calories]).to be_present
    end

    it 'portion_scale がない場合は無効である' do
      meal = build(:meal, portion_scale: nil)
      expect(meal).to be_invalid
      expect(meal.errors[:portion_scale]).to be_present
    end
  end
end
