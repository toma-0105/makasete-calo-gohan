require 'rails_helper'

RSpec.describe "UserAllergens", type: :request do
  let(:user) { create(:user) }
  let!(:old_allergen) { create(:allergen_master, name: "えび") }
  let!(:other_allergen) { create(:allergen_master, name: "卵") }

  before { sign_in user }

  describe "GET /user_allergens/new" do
    context "既存のアレルギー設定がある場合" do
      before do
        create(:user_allergen, user: user, allergen_master: old_allergen)
        get new_user_allergen_path
      end

      it "200 OKを返す" do
        expect(response).to have_http_status(:ok)
      end

      it "既存の設定がチェックされた状態で表示される" do
        doc = Nokogiri::HTML(response.body)
        checkbox = doc.at("input[name='allergen_ids[]'][value='#{old_allergen.id}']")
        expect(checkbox['checked']).to eq('checked')
      end

      it "設定していないアレルゲンはチェックされない" do
        doc = Nokogiri::HTML(response.body)
        checkbox = doc.at("input[name='allergen_ids[]'][value='#{other_allergen.id}']")
        expect(checkbox['checked']).to be_nil
      end
    end

    context "アレルギー設定がない場合" do
      before { get new_user_allergen_path }

      it "チェックボックスは全て未チェックで表示される" do
        doc = Nokogiri::HTML(response.body)
        expect(doc.css("input[name='allergen_ids[]'][checked]")).to be_empty
      end
    end
  end

  describe "POST /user_allergens" do
    context "既存の設定を変更する場合（TDEE診断済み）" do
      before do
        # TDEE診断済み＝オンボーディング完了後の設定変更として扱われる
        create(:tdee_profile, user: user)
        create(:user_allergen, user: user, allergen_master: old_allergen)
      end

      it "古い設定が削除され新しい設定に置き換わる" do
        post user_allergens_path, params: { allergen_ids: [ other_allergen.id ] }
        expect(user.reload.user_allergens.pluck(:allergen_master_id)).to eq([ other_allergen.id ])
      end

      it "マイページへリダイレクトされる" do
        post user_allergens_path, params: { allergen_ids: [ other_allergen.id ] }
        expect(response).to redirect_to(mypage_path)
      end
    end

    context "TDEE未診断（初回オンボーディング中）の場合" do
      it "TDEE診断画面へリダイレクトされる" do
        post user_allergens_path, params: { allergen_ids: [ old_allergen.id ] }
        expect(response).to redirect_to(new_tdee_profile_path)
      end
    end
  end
end
