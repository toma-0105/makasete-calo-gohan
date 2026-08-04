require 'rails_helper'

RSpec.describe GuestPromotionService do
  let(:guest) { create(:user, guest: true) }

  # 昇格フォームで入力される想定のパラメータ
  let(:valid_params) do
    {
      name: '昇格ユーザー',
      email: 'promoted@example.com',
      password: 'newpassword123',
      password_confirmation: 'newpassword123'
    }
  end

  describe '#promote' do
    context '有効なパラメータの場合' do
      it 'trueを返す' do
        expect(described_class.new(guest, valid_params).promote).to be true
      end

      it 'guestフラグがfalseになり、入力値が反映される' do
        described_class.new(guest, valid_params).promote
        guest.reload
        expect(guest.guest).to be false
        expect(guest.name).to eq('昇格ユーザー')
        expect(guest.email).to eq('promoted@example.com')
      end
    end

    context 'パスワードが一致しない場合' do
      let(:invalid_params) { valid_params.merge(password_confirmation: 'mismatch') }

      it 'falseを返し、guestフラグはtrueのまま変わらない' do
        expect(described_class.new(guest, invalid_params).promote).to be false
        expect(guest.reload.guest).to be true
      end
    end

    context '名前が空の場合' do
      # guest: false に変わると name の presence バリデーションが働くことを確認する
      let(:invalid_params) { valid_params.merge(name: '') }

      it 'falseを返し、昇格されない' do
        expect(described_class.new(guest, invalid_params).promote).to be false
        expect(guest.reload.guest).to be true
      end
    end
  end
end
