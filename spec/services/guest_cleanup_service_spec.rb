require 'rails_helper'

RSpec.describe GuestCleanupService do
  subject(:service) { described_class.new }

  let(:retention_days) { GuestCleanupService::GUEST_RETENTION_DAYS }

  # 時刻を固定して、「ちょうど保持日数たった」境目を正確に確かめる
  around { |example| freeze_time { example.run } }

  describe '#cleanup!' do
    context '保持日数に達したゲストがいる場合' do
      let!(:expired_guest) { create(:user, guest: true, created_at: retention_days.days.ago) }

      it 'ゲストが削除される' do
        expect { service.cleanup! }.to change(User, :count).by(-1)
        expect(User.exists?(expired_guest.id)).to be(false)
      end

      it '削除した人数を返す' do
        expect(service.cleanup!).to eq(1)
      end
    end

    context '保持日数に達していないゲストがいる場合' do
      let!(:new_guest) { create(:user, guest: true, created_at: retention_days.days.ago + 1.minute) }

      it '削除されない' do
        expect { service.cleanup! }.not_to change(User, :count)
        expect(User.exists?(new_guest.id)).to be(true)
      end

      it '0を返す' do
        expect(service.cleanup!).to eq(0)
      end
    end

    # guest: true の条件が外れると、古い会員まで消えてしまう
    context '保持日数をとうに過ぎた会員がいる場合' do
      let!(:old_member) { create(:user, guest: false, created_at: (retention_days * 10).days.ago) }
      let!(:member_menu) { create(:menu, user: old_member) }

      it '会員もその関連データも削除されない' do
        expect { service.cleanup! }.not_to change(User, :count)
        expect(User.exists?(old_member.id)).to be(true)
        expect(Menu.exists?(member_menu.id)).to be(true)
      end
    end

    context '期限切れのゲストと、残るユーザーが混在する場合' do
      let!(:expired_guest) { create(:user, guest: true, created_at: retention_days.days.ago) }
      let!(:new_guest)     { create(:user, guest: true, created_at: 1.day.ago) }
      let!(:member)        { create(:user, guest: false, created_at: (retention_days * 10).days.ago) }

      it '期限切れのゲストだけが削除される' do
        service.cleanup!
        expect(User.where(id: [ expired_guest.id, new_guest.id, member.id ])).to contain_exactly(new_guest, member)
      end
    end

    # users への外部キーがあるため、関連データを先に消さないと削除できない
    context '期限切れのゲストが関連データを持っている場合' do
      let!(:expired_guest) { create(:user, guest: true, created_at: retention_days.days.ago) }
      let!(:menu)          { create(:menu, user: expired_guest) }

      before do
        create(:meal, menu: menu)
        create(:tdee_profile, user: expired_guest)
        create(:user_allergen, user: expired_guest)
        Favorite.create!(user: expired_guest, meal_master: create(:meal_master))
        create(:weight_record, user: expired_guest)
      end

      it '献立と、その中の料理も削除される' do
        expect { service.cleanup! }.to change(Menu, :count).by(-1).and change(Meal, :count).by(-1)
      end

      it 'TDEE診断・アレルギー設定・お気に入り・体重記録も削除される' do
        expect { service.cleanup! }
          .to change(TdeeProfile, :count).by(-1)
          .and change(UserAllergen, :count).by(-1)
          .and change(Favorite, :count).by(-1)
          .and change(WeightRecord, :count).by(-1)
      end
    end

    context '関連データの削除が途中で失敗した場合' do
      let!(:expired_guest) { create(:user, guest: true, created_at: retention_days.days.ago) }
      let!(:menu)          { create(:menu, user: expired_guest) }

      before do
        create(:weight_record, user: expired_guest)
        # 献立の削除が終わったあと（体重記録の削除）で失敗させる
        allow_any_instance_of(WeightRecord).to receive(:destroy).and_raise(ActiveRecord::RecordNotDestroyed)
      end

      it '例外が出て、ゲストも献立も元に戻る（一部だけ消えた状態にならない）' do
        expect { service.cleanup! }.to raise_error(ActiveRecord::RecordNotDestroyed)
        expect(User.exists?(expired_guest.id)).to be(true)
        expect(Menu.exists?(menu.id)).to be(true)
      end
    end
  end
end
