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
        menus = service.generate!.menus
        expect(menus.map(&:date)).to eq([ Date.current, Date.current + 1.day, Date.current + 2.days ])
      end

      it '既存の献立がないので、スキップした献立は無い' do
        expect(service.generate!.skipped_menus).to be_empty
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

    # 日本時間の0〜9時は、UTCではまだ前日。この時間帯でも、日本の今日から数えて保存されることを確かめる
    context '日本時間の朝（UTCでは前日）に2日分を生成する場合' do
      let(:days) { 2 }
      let(:selector) { instance_double(MenuCalorieRangeSelectorService) }

      before do
        allow(MenuCalorieRangeSelectorService).to receive(:new).and_return(selector)
        allow(selector).to receive(:generate).and_return(menu_hash_for(day1_master))
      end

      it '日本の今日から数えた日付で保存される' do
        # UTC 11/5 23:00 = 日本時間 11/6 8:00
        travel_to(Time.utc(2026, 11, 5, 23, 0)) do
          dates = service.generate!.menus.map(&:date)
          expect(dates).to eq([ Date.new(2026, 11, 6), Date.new(2026, 11, 7) ])
        end
      end
    end

    # 今日の分だけ、すでに献立がある場合
    context '3日分を生成し、今日の献立がすでにある場合' do
      let(:days) { 3 }
      let(:selector) { instance_double(MenuCalorieRangeSelectorService) }
      let(:existing_master) { create(:meal_master, calories: 280) }
      let!(:existing_menu) { create(:menu, user: user, date: Date.current, total_calories: 280) }

      before do
        create(:meal, menu: existing_menu, meal_master: existing_master)
        allow(MenuCalorieRangeSelectorService).to receive(:new).and_return(selector)
        allow(selector).to receive(:generate).and_return(menu_hash_for(day1_master), menu_hash_for(day2_master))
      end

      it '足りない2日分だけ作成される' do
        expect { service.generate! }.to change(Menu, :count).by(2)
      end

      it '生成した献立は明日以降の日付になる' do
        result = service.generate!
        expect(result.menus.map(&:date)).to eq([ Date.current + 1.day, Date.current + 2.days ])
      end

      it 'スキップした既存の献立を返す' do
        expect(service.generate!.skipped_menus).to eq([ existing_menu ])
      end

      it '既存の献立の中身は変更されない' do
        service.generate!
        expect(existing_menu.reload.total_calories).to eq(280)
        expect(existing_menu.meals.map(&:meal_master)).to eq([ existing_master ])
      end

      it '既存の献立の料理も使用済みとして、追加除外IDに含まれる' do
        service.generate!
        expect(MenuCalorieRangeSelectorService).to have_received(:new)
          .with(tdee_profile, additional_excluded_meal_master_ids: [ existing_master.id ])
        expect(MenuCalorieRangeSelectorService).to have_received(:new)
          .with(tdee_profile, additional_excluded_meal_master_ids: [ existing_master.id, day1_master.id ])
      end
    end

    context '指定した日数すべてに献立がすでにある場合' do
      let(:days) { 2 }
      let!(:existing_menus) { Array.new(days) { |i| create(:menu, user: user, date: Date.current + i.days) } }

      before do
        allow(MenuCalorieRangeSelectorService).to receive(:new)
      end

      it '何も作成されない' do
        expect { service.generate! }.not_to change(Menu, :count)
      end

      it '生成した献立は無く、既存の献立が日付順にスキップとして返る' do
        result = service.generate!
        expect(result.menus).to be_empty
        expect(result.skipped_menus).to eq(existing_menus)
      end

      it '献立の選定自体を行わない' do
        service.generate!
        expect(MenuCalorieRangeSelectorService).not_to have_received(:new)
      end
    end

    context '他のユーザーが同じ日付の献立を持っている場合' do
      let(:days) { 1 }
      let(:selector) { instance_double(MenuCalorieRangeSelectorService) }

      before do
        create(:menu, date: Date.current)
        allow(MenuCalorieRangeSelectorService).to receive(:new).and_return(selector)
        allow(selector).to receive(:generate).and_return(menu_hash_for(day1_master))
      end

      it 'スキップされず、自分の献立が作成される' do
        result = service.generate!
        expect(result.menus.size).to eq(1)
        expect(result.skipped_menus).to be_empty
      end
    end

    context '途中の日の生成に失敗した場合' do
      let(:days) { 2 }

      before do
        selector = instance_double(MenuCalorieRangeSelectorService)
        allow(MenuCalorieRangeSelectorService).to receive(:new).and_return(selector)
        allow(selector).to receive(:generate).and_invoke(
          -> { menu_hash_for(day1_master) },
          -> { raise ActiveRecord::RecordInvalid }
        )
      end

      it '1日目も保存されず、ロールバックされる' do
        expect { service.generate! }.to raise_error(ActiveRecord::RecordInvalid)
        expect(Menu.count).to eq(0)
      end
    end

    # 生成している間に別のリクエストが同じ日付の献立を先に作った場合を想定する
    context '1回目の生成が日付の重複エラーで失敗した場合（別リクエストとの競合）' do
      let(:days) { 1 }
      let(:selector) { instance_double(MenuCalorieRangeSelectorService) }

      before do
        allow(MenuCalorieRangeSelectorService).to receive(:new).and_return(selector)
      end

      [ ActiveRecord::RecordNotUnique, ActiveRecord::RecordInvalid ].each do |error_class|
        it "#{error_class.name}でも、1回だけやり直して献立を生成する" do
          allow(selector).to receive(:generate).and_invoke(
            -> { raise error_class },
            -> { menu_hash_for(day1_master) }
          )

          result = service.generate!
          expect(result.menus.size).to eq(1)
        end
      end

      it '2回続けて失敗した場合は、そのまま例外にする' do
        allow(selector).to receive(:generate).and_raise(ActiveRecord::RecordNotUnique)

        expect { service.generate! }.to raise_error(ActiveRecord::RecordNotUnique)
        expect(selector).to have_received(:generate).twice
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
