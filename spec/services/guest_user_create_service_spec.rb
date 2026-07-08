require 'rails_helper'

RSpec.describe GuestUserCreateService do
  subject(:service) { described_class.new }

  describe '#create!' do
    it 'ゲストユーザーが1件作成される' do
      expect { service.create! }.to change(User.where(guest: true), :count).by(1)
    end

    it 'guestフラグと名前が設定される' do
      user = service.create!
      expect(user.guest).to be true
      expect(user.name).to eq('ゲストユーザー')
    end

    it 'メールアドレスが毎回異なる（衝突しない）' do
      emails = 3.times.map { service.create!.email }
      expect(emails.uniq.size).to eq(3)
    end
  end
end
