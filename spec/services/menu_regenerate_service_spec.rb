require 'rails_helper'

RSpec.describe MenuRegenerateService do
  let(:user)         { create(:user) }
  let(:tdee_profile) { create(:tdee_profile, user: user) }

  # 再生成前の古い献立（mealも1件ぶら下げておく）
  let!(:old_menu) { create(:menu, user: user) }
  let!(:old_meal) { create(:meal, menu: old_menu) }

  let(:breakfast_meal) { create(:meal_master, meal_timing: :breakfast,       category: :staple,    calories: 300) }
  let(:lunch_meal)     { create(:meal_master, meal_timing: :lunch_or_dinner, category: :staple,    calories: 500) }
  let(:dinner_meal)    { create(:meal_master, meal_timing: :lunch_or_dinner, category: :main_dish, calories: 600) }

  let(:menu_hash) do
    {
      breakfast: [ MenuGeneratorService::SelectedMeal.new(breakfast_meal, 1.0) ],
      lunch:     [ MenuGeneratorService::SelectedMeal.new(lunch_meal, 1.0) ],
      dinner:    [ MenuGeneratorService::SelectedMeal.new(dinner_meal, 1.0) ]
    }
  end

  subject(:service) { described_class.new(user, old_menu, tdee_profile) }

  before do
    # 献立候補の選定ロジック自体は MenuCalorieRangeSelectorService のテストで担保するため、
    # ここでは固定の menu_hash を返すようにスタブする
    selector = instance_double(MenuCalorieRangeSelectorService, generate: menu_hash)
    allow(MenuCalorieRangeSelectorService).to receive(:new).with(tdee_profile).and_return(selector)
  end

  describe '#regenerate!' do
    it '古い献立が削除される' do
      service.regenerate!
      expect(Menu.exists?(old_menu.id)).to be false
    end

    it '古い献立の meals も一緒に削除される' do
      service.regenerate!
      expect(Meal.exists?(old_meal.id)).to be false
    end

    it '新しい献立が作成され、全体の件数は変わらない' do
      # 1件削除 + 1件作成のため、差し引きゼロになる
      expect { service.regenerate! }.not_to change(Menu, :count)
    end

    it '新しい献立を返す' do
      new_menu = service.regenerate!
      expect(new_menu).to be_persisted
      expect(new_menu.id).not_to eq(old_menu.id)
      expect(new_menu.total_calories).to eq(1400)
    end

    context '新しい献立の保存に失敗した場合' do
      before do
        allow(Meal).to receive(:create!).and_raise(ActiveRecord::RecordInvalid)
      end

      it '古い献立の削除もロールバックされる' do
        expect { service.regenerate! }.to raise_error(ActiveRecord::RecordInvalid)
        expect(Menu.exists?(old_menu.id)).to be true
      end
    end
  end
end
