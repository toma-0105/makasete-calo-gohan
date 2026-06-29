require 'rails_helper'

RSpec.describe AllergenExclusionService do
  subject(:service) { described_class.new(user) }

  let(:user) { create(:user) }
  let(:allergen) { create(:allergen_master, name: 'エビ') }
  let(:meal_with_allergen) { create(:meal_master) }
  let(:meal_without_allergen) { create(:meal_master) }

  before do
    create(:meal_ingredient, meal_master: meal_with_allergen, allergen_master: allergen)
  end

  describe '#excluded_meal_master_ids' do
    context 'ユーザーがアレルギーを設定している場合' do
      before { create(:user_allergen, user: user, allergen_master: allergen) }

      it 'アレルギー食材を含む料理のIDが返る' do
        expect(service.excluded_meal_master_ids).to contain_exactly(meal_with_allergen.id)
      end

      it 'アレルギーを含まない料理のIDは含まれない' do
        expect(service.excluded_meal_master_ids).not_to include(meal_without_allergen.id)
      end
    end

    context 'ユーザーがアレルギーを設定していない場合' do
      it '空配列が返る' do
        expect(service.excluded_meal_master_ids).to eq([])
      end
    end
  end
end
