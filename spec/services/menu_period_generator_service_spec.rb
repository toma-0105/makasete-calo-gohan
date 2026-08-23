require 'rails_helper'

RSpec.describe MenuPeriodGeneratorService do
  let(:user)         { create(:user) }
  let(:tdee_profile) { create(:tdee_profile, user: user, target_calories: 2000) }

  let(:day1_master) { create(:meal_master, calories: 300) }
  let(:day2_master) { create(:meal_master, calories: 320) }
  let(:day3_master) { create(:meal_master, calories: 340) }

  def menu_hash_for(meal_master)
    { breakfast: [ MenuGeneratorService::SelectedMeal.new(meal_master, 1.0) ], lunch: [], dinner: [] }
  end

  subject(:service) { described_class.new(user, tdee_profile, days: days) }

  describe '#generate!' do
    context '3日分を生成する場合' do
      let(:days) { 3 }
      let(:selector) { instance_double(MenuCalorieRangeSelectorService) }

      before do
        allow(MenuCalorieRangeSelectorService).to receive(:new).and_return(selector)
        allow(selector).to receive(:generate).and_return(
          menu_hash_for(day1_master), menu_hash_for(day2_master), menu_hash_for(day3_master)
        )
      end

      it 'menusが3件作成される' do
        expect { service.generate! }.to change(Menu, :count).by(3)
      end

      it '日付が今日から1日ずつずれて保存される' do
        menus = service.generate!
        expect(menus.map(&:date)).to eq([ Date.today, Date.today + 1.day, Date.today + 2.days ])
      end

      it '1日目は追加除外IDなしで呼ばれる' do
        service.generate!
        expect(MenuCalorieRangeSelectorService).to have_received(:new)
          .with(tdee_profile, additional_excluded_meal_master_ids: [])
      end

      it '2日目は1日目で選出されたIDが追加除外リストに渡る' do
        service.generate!
        expect(MenuCalorieRangeSelectorService).to have_received(:new)
          .with(tdee_profile, additional_excluded_meal_master_ids: [ day1_master.id ])
      end

      it '3日目は1〜2日目で選出されたIDが累積して渡る' do
        service.generate!
        expect(MenuCalorieRangeSelectorService).to have_received(:new)
          .with(tdee_profile, additional_excluded_meal_master_ids: [ day1_master.id, day2_master.id ])
      end
    end

    context 'daysが範囲外（0日）の場合' do
      let(:days) { 0 }

      it 'ArgumentErrorになる' do
        expect { service.generate! }.to raise_error(ArgumentError)
      end
    end

    context 'daysが範囲外（8日）の場合' do
      let(:days) { 8 }

      it 'ArgumentErrorになる' do
        expect { service.generate! }.to raise_error(ArgumentError)
      end
    end
  end
end
