require 'rails_helper'

RSpec.describe UserAllergen, type: :model do
  describe 'バリデーション' do
    let(:user) { create(:user) }
    let(:allergen) { create(:allergen_master) }

    it 'user_id と allergen_master_id があれば有効' do
      user_allergen = build(:user_allergen, user:, allergen_master: allergen)
      expect(user_allergen).to be_valid
    end

    it 'user_id がなければ無効' do
      user_allergen = build(:user_allergen, user: nil, allergen_master: allergen)
      expect(user_allergen).not_to be_valid
    end

    it '同じユーザーが同じアレルギーを2回保存できない' do
      create(:user_allergen, user:, allergen_master: allergen)
      duplicate = build(:user_allergen, user:, allergen_master: allergen)
      expect(duplicate).not_to be_valid
    end
  end
end