require 'rails_helper'

RSpec.describe OmniauthUserService do
  let(:provider) { 'google_oauth2' }
  let(:uid) { 'google-uid-123' }
  let(:email) { 'taro@example.com' }
  let(:name) { 'Taro' }

  # Googleから届く認証情報の代わり（実際にGoogleとは通信しない）
  let(:auth) do
    OmniAuth::AuthHash.new(
      provider: provider,
      uid: uid,
      info: { email: email, name: name }
    )
  end

  # テスト対象の戻り値（ログインさせるユーザー）。参照された時点で初めて実行される
  subject(:result) { described_class.new(auth).find_or_create }

  describe '#find_or_create' do
    context 'providerとuidが一致するユーザーがいる場合（2回目以降のログイン）' do
      let!(:user) { create(:user, provider: provider, uid: uid) }

      it '既存ユーザーを返す' do
        expect(result).to eq(user)
      end

      it 'ユーザーは増えない' do
        expect { result }.not_to change(User, :count)
      end
    end

    context 'Google側のメールアドレスが変わっていてもuidが同じ場合' do
      let!(:user) { create(:user, provider: provider, uid: uid, email: 'old@example.com') }

      it 'uidを優先して同じユーザーを返し、メールアドレスは書き換えない' do
        expect(result).to eq(user)
        expect(user.reload.email).to eq('old@example.com')
      end
    end

    context 'メールアドレスだけ一致する既存ユーザーがいる場合（メール登録済みでGoogleは初めて）' do
      let!(:user) { create(:user, email: email) }

      it '既存ユーザーを返す' do
        expect(result).to eq(user)
      end

      it 'providerとuidが紐付く' do
        result
        expect(user.reload).to have_attributes(provider: provider, uid: uid)
      end

      it 'ユーザーは増えない' do
        expect { result }.not_to change(User, :count)
      end

      it 'パスワードは上書きされない（メール＋パスワードでのログインを壊さない）' do
        expect { result }.not_to change { user.reload.encrypted_password }
      end
    end

    context 'Google側のメールアドレスに大文字が含まれる場合' do
      let(:email) { 'Taro@Example.com' }
      let!(:user) { create(:user, email: 'taro@example.com') }

      it '小文字に揃えて、既存ユーザーに紐付く' do
        expect(result).to eq(user)
        expect(user.reload.uid).to eq(uid)
      end
    end

    context '初めてのユーザーの場合' do
      it 'ユーザーが1人増える' do
        expect { result }.to change(User, :count).by(1)
      end

      it 'Googleの情報で保存される' do
        expect(result).to be_persisted
        expect(result).to have_attributes(
          provider: provider,
          uid: uid,
          email: email,
          name: name,
          guest: false
        )
      end

      it '本人が知らないランダムなパスワードが設定される' do
        expect(result.password).to be_present
        expect(result.valid_password?(result.password)).to be true
      end
    end

    context 'メールアドレスが取得できない場合' do
      let(:email) { nil }
      let!(:other_user) { create(:user) }

      it '保存されない' do
        expect(result).not_to be_persisted
        expect(result.errors[:email]).to be_present
      end

      it 'ユーザーは増えない' do
        expect { result }.not_to change(User, :count)
      end

      it '他のユーザーに紐付けられない' do
        result
        expect(other_user.reload.provider).to be_nil
      end
    end
  end
end
