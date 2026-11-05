require 'rails_helper'

RSpec.describe Menu, type: :model do
  describe 'バリデーション' do
    it 'Factoryのデフォルト値で有効である' do
      expect(build(:menu)).to be_valid
    end

    it 'date がない場合は無効である' do
      menu = build(:menu, date: nil)
      expect(menu).to be_invalid
      expect(menu.errors[:date]).to be_present
    end

    it 'total_calories がない場合は無効である' do
      menu = build(:menu, total_calories: nil)
      expect(menu).to be_invalid
      expect(menu.errors[:total_calories]).to be_present
    end

    it 'total_calories が0以下の場合は無効である' do
      menu = build(:menu, total_calories: 0)
      expect(menu).to be_invalid
      expect(menu.errors[:total_calories]).to be_present
    end
  end

    it '同じユーザーの同じ日付の献立は無効である' do
      user = create(:user)
      create(:menu, user: user, date: Date.new(2026, 11, 5))

      duplicate = build(:menu, user: user, date: Date.new(2026, 11, 5))
      expect(duplicate).to be_invalid
      expect(duplicate.errors[:date]).to be_present
    end

    it '別のユーザーなら同じ日付でも有効である' do
      create(:menu, date: Date.new(2026, 11, 5))

      expect(build(:menu, date: Date.new(2026, 11, 5))).to be_valid
    end

    it 'バリデーションをすり抜けても、DBの一意制約で重複を防ぐ' do
      user = create(:user)
      create(:menu, user: user, date: Date.new(2026, 11, 5))

      duplicate = build(:menu, user: user, date: Date.new(2026, 11, 5))
      expect { duplicate.save(validate: false) }.to raise_error(ActiveRecord::RecordNotUnique)
    end

  describe 'スコープ' do
    describe '.saved' do
      let!(:saved_menu)   { create(:menu, :saved) }
      let!(:unsaved_menu) { create(:menu) }

      it '保存済みの献立のみ取得できる' do
        expect(Menu.saved).to contain_exactly(saved_menu)
      end
    end
  end
end
