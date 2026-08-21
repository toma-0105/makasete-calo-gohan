require 'rails_helper'

RSpec.describe MealRegenerateService do
  let(:user)         { create(:user) }
  let(:tdee_profile) { create(:tdee_profile, user: user) }
  let!(:menu)        { create(:menu, user: user, total_calories: 1800) }

  # 入れ替え前の3食
  let!(:breakfast_meal)  { create(:meal, menu: menu, meal_timing: :breakfast, calories: 500) }
  let!(:old_lunch_meal)  { create(:meal, menu: menu, meal_timing: :lunch,     calories: 600) }
  let!(:old_dinner_meal) { create(:meal, menu: menu, meal_timing: :dinner,   calories: 700) }

  # 差し替え後の新しい夕食候補
  let(:new_dinner_master) { create(:meal_master, meal_timing: :lunch_or_dinner, category: :main_dish, calories: 650) }
  let(:new_dinner_meals)  { [ MenuGeneratorService::SelectedMeal.new(new_dinner_master, 1.0) ] }

  subject(:service) { described_class.new(menu, :dinner, tdee_profile) }

  before do
    # 候補選定ロジック自体はMenuGeneratorServiceのテストで担保するため、ここでは固定の結果を返すようスタブする
    generator = instance_double(MenuGeneratorService, generate_for: new_dinner_meals)
    allow(MenuGeneratorService).to receive(:new).and_return(generator)
  end

  describe '#regenerate!' do
    it '対象timing（dinner）の古いmealが削除される' do
      service.regenerate!
      expect(Meal.exists?(old_dinner_meal.id)).to be false
    end

    it '対象外のtiming（breakfast, lunch）のmealは残る' do
      service.regenerate!
      expect(Meal.exists?(breakfast_meal.id)).to be true
      expect(Meal.exists?(old_lunch_meal.id)).to be true
    end

    it '新しいdinnerのmealが作成される' do
      service.regenerate!
      new_dinner = menu.meals.dinner.first
      expect(new_dinner.meal_master).to eq(new_dinner_master)
      expect(new_dinner.calories).to eq(650)
    end

    it 'menuのtotal_caloriesが入れ替え後の合計に更新される' do
      service.regenerate!
      # breakfast(500) + lunch(600) + 新dinner(650)
      expect(menu.reload.total_calories).to eq(1750)
    end

    it 'menu自体は削除・再作成されず同じidのまま更新される' do
      expect { service.regenerate! }.not_to change(menu, :id)
    end

    it '現在の3食のmeal_master_idとアレルギー除外IDを候補から除外する' do
      allergen_service = instance_double(AllergenExclusionService, excluded_meal_master_ids: [ 999 ])
      allow(AllergenExclusionService).to receive(:new).with(user).and_return(allergen_service)

      current_ids = menu.meals.pluck(:meal_master_id)
      expect(MenuGeneratorService).to receive(:new)
        .with(excluded_meal_master_ids: match_array(current_ids + [ 999 ]), target_calories: tdee_profile.target_calories, favorite_meal_master_ids: [])
        .and_return(instance_double(MenuGeneratorService, generate_for: new_dinner_meals))

      service.regenerate!
    end

    context '新しいmealの保存に失敗した場合' do
      before do
        allow(Meal).to receive(:create!).and_raise(ActiveRecord::RecordInvalid)
      end

      it '古いdinnerのmealも削除されず元のまま残る（ロールバック）' do
        expect { service.regenerate! }.to raise_error(ActiveRecord::RecordInvalid)
        expect(Meal.exists?(old_dinner_meal.id)).to be true
      end

      it 'menuのtotal_caloriesも変更されない' do
        original_total = menu.total_calories
        expect { service.regenerate! }.to raise_error(ActiveRecord::RecordInvalid)
        expect(menu.reload.total_calories).to eq(original_total)
      end
    end
  end
end
