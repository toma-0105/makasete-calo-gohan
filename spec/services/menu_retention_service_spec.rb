require 'rails_helper'

RSpec.describe MenuRetentionService do
  # 日本時間 2026-11-07 12:00 に固定する（昨日は 11/6、おとといは 11/5）
  # UTCで指定しているのは、config.time_zone の設定に左右されないようにするため
  let(:now)          { Time.utc(2026, 11, 7, 3, 0) }
  let(:today)        { Date.new(2026, 11, 7) }
  let(:yesterday)    { Date.new(2026, 11, 6) }
  let(:two_days_ago) { Date.new(2026, 11, 5) }

  around { |example| travel_to(now) { example.run } }

  describe '.oldest_kept_date' do
    it '日本の昨日を返す' do
      expect(described_class.oldest_kept_date).to eq(yesterday)
    end

    context '日本時間の0時を過ぎた直後（UTCではまだ前日）の場合' do
      # UTC 11/6 15:30 = 日本時間 11/7 0:30
      let(:now) { Time.utc(2026, 11, 6, 15, 30) }

      it '日本の昨日を返す' do
        expect(described_class.oldest_kept_date).to eq(yesterday)
      end
    end
  end

  describe '.recent_menus' do
    let(:user) { create(:user) }

    let!(:old_menu)       { create(:menu, user: user, date: two_days_ago) }
    let!(:yesterday_menu) { create(:menu, user: user, date: yesterday) }
    let!(:today_menu)     { create(:menu, user: user, date: today) }
    let!(:future_menu)    { create(:menu, user: user, date: today + 3.days) }
    let!(:other_menu)     { create(:menu, date: today) }

    it '自分の献立のうち、昨日以降のものだけを返す（昨日は残す）' do
      expect(described_class.recent_menus(user)).to contain_exactly(yesterday_menu, today_menu, future_menu)
    end
  end

  describe '#cleanup!' do
    subject(:service) { described_class.new }

    context '昨日より前の献立がある場合' do
      let!(:old_menu)       { create(:menu, date: two_days_ago) }
      let!(:yesterday_menu) { create(:menu, date: yesterday) }
      let!(:today_menu)     { create(:menu, date: today) }
      let!(:future_menu)    { create(:menu, date: today + 3.days) }

      it '昨日より前の献立だけが削除される（昨日・今日・未来は残る）' do
        service.cleanup!
        expect(Menu.all).to contain_exactly(yesterday_menu, today_menu, future_menu)
      end

      it '削除した件数を返す' do
        expect(service.cleanup!).to eq(1)
      end
    end

    context '複数のユーザーに、昨日より前の献立がある場合' do
      before do
        create(:menu, date: two_days_ago)
        create(:menu, date: two_days_ago - 5.days)
      end

      it '全員分が削除される' do
        expect { service.cleanup! }.to change(Menu, :count).by(-2)
      end
    end

    context '昨日より前の献立が、料理を持っている場合' do
      let!(:old_menu)  { create(:menu, date: two_days_ago) }
      let!(:kept_menu) { create(:menu, date: today) }

      before do
        create_list(:meal, 2, menu: old_menu)
        create(:meal, menu: kept_menu)
      end

      it '料理も一緒に削除され、残す献立の料理は消えない' do
        expect { service.cleanup! }.to change(Meal, :count).by(-2)
        expect(kept_menu.meals.count).to eq(1)
      end
    end

    context '削除する献立がない場合' do
      let!(:today_menu) { create(:menu, date: today) }

      it '何も削除せず、0を返す' do
        expect { service.cleanup! }.not_to change(Menu, :count)
        expect(service.cleanup!).to eq(0)
      end
    end

    context '日本時間の0時を過ぎた直後（UTCではまだ前日）の場合' do
      # UTC 11/6 15:30 = 日本時間 11/7 0:30。日本の「昨日」は 11/6
      let(:now) { Time.utc(2026, 11, 6, 15, 30) }

      let!(:yesterday_menu) { create(:menu, date: yesterday) }
      let!(:old_menu)       { create(:menu, date: two_days_ago) }

      it '日本の昨日の献立は残し、それより前だけを削除する' do
        service.cleanup!
        expect(Menu.all).to contain_exactly(yesterday_menu)
      end
    end

    context '料理の削除が途中で失敗した場合' do
      let!(:old_menu) { create(:menu, date: two_days_ago) }

      before do
        create_list(:meal, 2, menu: old_menu)

        # 1つ目の料理は削除できて、2つ目で失敗させる（削除が途中まで進んだ状態を作る）
        calls = 0
        allow_any_instance_of(Meal).to receive(:destroy).and_wrap_original do |original, *args|
          calls += 1
          raise ActiveRecord::RecordNotDestroyed if calls == 2

          original.call(*args)
        end
      end

      it '例外が出て、献立も料理も元に戻る（一部だけ消えた状態にならない）' do
        expect { service.cleanup! }.to raise_error(ActiveRecord::RecordNotDestroyed)
        expect(Menu.exists?(old_menu.id)).to be(true)
        expect(old_menu.meals.count).to eq(2)
      end
    end
  end
end
