require 'rails_helper'

RSpec.describe MenuSaveService do
  let(:user)         { create(:user) }
  let(:breakfast_meal) { create(:meal_master, meal_timing: :breakfast,    category: :staple,     calories: 300) }
  let(:lunch_meal)     { create(:meal_master, meal_timing: :lunch_or_dinner, category: :staple,  calories: 500) }
  let(:dinner_meal)    { create(:meal_master, meal_timing: :lunch_or_dinner, category: :main_dish, calories: 600) }

  let(:menu_hash) do
    {
      breakfast: [ breakfast_meal ],
      lunch:     [ lunch_meal ],
      dinner:    [ dinner_meal ]
    }
  end

  subject(:service) { described_class.new(user, menu_hash) }

  describe '#save!' do
    it 'menus に1件レコードが作成される' do
      expect { service.save! }.to change(Menu, :count).by(1)
    end

    it 'meals に3件レコードが作成される' do
      expect { service.save! }.to change(Meal, :count).by(3)
    end

    it 'total_calories が正しく計算・保存される' do
      menu = service.save!
      expect(menu.total_calories).to eq(1400)
    end

    it '朝・昼・夕それぞれの meal_timing で保存される' do
      service.save!
      expect(Meal.pluck(:meal_timing)).to contain_exactly('breakfast', 'lunch', 'dinner')
    end

    context '保存に失敗した場合' do
      before do
        allow(Meal).to receive(:create!).and_raise(ActiveRecord::RecordInvalid)
      end

      it 'Menu も作成されずロールバックされる' do
        expect { service.save! }.to raise_error(ActiveRecord::RecordInvalid)
        expect(Menu.count).to eq(0)
      end
    end
  end
end
