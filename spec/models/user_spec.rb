require 'rails_helper'

RSpec.describe User, type: :model do
  # FactoryBotでテストデータを作る
  let(:user) { build(:user) }

  describe "バリデーション" do
    context "正常な場合" do
      it "name・email・passwordがあれば登録できる" do
        expect(user).to be_valid
      end
    end

    context "nameがない場合" do
      it "登録できない" do
        user.name = nil
        expect(user).not_to be_valid
      end
    end

    context "emailがない場合" do
      it "登録できない" do
        user.email = nil
        expect(user).not_to be_valid
      end
    end

    context "emailが重複している場合" do
      it "登録できない" do
        create(:user, email: "test@example.com")
        user.email = "test@example.com"
        expect(user).not_to be_valid
      end
    end

    context "passwordが6文字未満の場合" do
      it "登録できない" do
        user.password = "abc"
        expect(user).not_to be_valid
      end
    end
  end
end
