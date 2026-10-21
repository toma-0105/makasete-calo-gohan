require 'rails_helper'

RSpec.describe MenuHistorySaveService do
  let(:user) { create(:user) }
  let(:date) { Date.new(2026, 10, 21) }
  let(:menu) { create(:menu, user: user, date: date) }

  describe "#save!" do
    it "献立が保存済みになり、置き換え件数は0になる" do
      result = described_class.new(user, menu).save!
      expect(menu.reload.saved).to be true
      expect(result.replaced_count).to eq 0
    end

    context "同じ日付の保存済み献立がある場合" do
      let!(:old_menu) { create(:menu, :saved, user: user, date: date) }

      it "古い献立は未保存に戻り、新しい献立が保存済みになる" do
        described_class.new(user, menu).save!
        expect(old_menu.reload.saved).to be false
        expect(menu.reload.saved).to be true
      end

      it "置き換え件数が1になる" do
        result = described_class.new(user, menu).save!
        expect(result.replaced_count).to eq 1
      end
    end

    context "別の日付の保存済み献立がある場合" do
      let!(:other_date_menu) { create(:menu, :saved, user: user, date: date - 1) }

      it "その献立は保存済みのまま残る" do
        described_class.new(user, menu).save!
        expect(other_date_menu.reload.saved).to be true
      end
    end

    context "別ユーザーの同じ日付の保存済み献立がある場合" do
      let!(:other_user_menu) { create(:menu, :saved, date: date) }

      it "その献立は保存済みのまま残る" do
        described_class.new(user, menu).save!
        expect(other_user_menu.reload.saved).to be true
      end
    end

    context "すでに保存済みの献立を再度保存した場合" do
      let!(:saved_menu) { create(:menu, :saved, user: user, date: date) }

      it "自分自身は置き換えられず、保存済みのままになる" do
        result = described_class.new(user, saved_menu).save!
        expect(saved_menu.reload.saved).to be true
        expect(result.replaced_count).to eq 0
      end
    end
  end
end
