require 'rails_helper'

RSpec.describe MenuRegenerateService do
  let(:user)         { create(:user) }
  let(:tdee_profile) { create(:tdee_profile, user: user) }

  # 再生成前の献立（mealも1件ぶら下げておく）
  # 日付が再生成後も変わらないことを確かめるため、あえて今日以外にしている
  let(:menu_date) { Date.current + 3.days }
  let!(:menu)     { create(:menu, user: user, date: menu_date) }
  let!(:old_meal) { create(:meal, menu: menu) }

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

  subject(:service) { described_class.new(user, menu, tdee_profile) }

  before do
    # 献立候補の選定ロジック自体は MenuCalorieRangeSelectorService のテストで担保するため、
    # ここでは固定の menu_hash を返すようにスタブする
    selector = instance_double(MenuCalorieRangeSelectorService, generate: menu_hash)
    allow(MenuCalorieRangeSelectorService).to receive(:new).with(tdee_profile).and_return(selector)
  end

  describe '#regenerate!' do
    it '同じ献立を返す' do
      expect(service.regenerate!).to eq(menu)
    end

    it '献立は作り直されず、件数は変わらない' do
      expect { service.regenerate! }.not_to change(Menu, :count)
    end

    it '古い meals が削除される' do
      service.regenerate!
      expect(Meal.exists?(old_meal.id)).to be false
    end

    it '新しい内容の meals に差し替わる' do
      service.regenerate!
      expect(menu.reload.meals.map(&:meal_master)).to contain_exactly(breakfast_meal, lunch_meal, dinner_meal)
    end

    it '合計カロリーが新しい内容で再計算される' do
      service.regenerate!
      expect(menu.reload.total_calories).to eq(1400)
    end

    it '日付は変わらない（今日に戻らない）' do
      service.regenerate!
      expect(menu.reload.date).to eq(menu_date)
    end

    context '差し替えに失敗した場合' do
      before do
        allow(Meal).to receive(:create!).and_raise(ActiveRecord::RecordInvalid)
      end

      it '古い meals の削除もロールバックされ、献立が空にならない' do
        expect { service.regenerate! }.to raise_error(ActiveRecord::RecordInvalid)
        expect(Meal.exists?(old_meal.id)).to be true
      end
    end
  end
end
