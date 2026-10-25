require 'rails_helper'

RSpec.describe "Favorites", type: :request do
  describe "GET /favorites（お気に入り一覧）" do
    let(:user)         { create(:user) }
    let(:other_user)   { create(:user) }
    let(:my_master)    { create(:meal_master, name: "自分のお気に入り料理") }
    let(:other_master) { create(:meal_master, name: "他人のお気に入り料理") }

    before do
      Favorite.create!(user: user, meal_master: my_master)
      Favorite.create!(user: other_user, meal_master: other_master)
      sign_in user
      get favorites_path
    end

    it "自分のお気に入りが表示される" do
      expect(response.body).to include(my_master.name)
    end

    it "他人のお気に入りは表示されない" do
      expect(response.body).not_to include(other_master.name)
    end
  end

  describe "POST /meal_masters/:meal_master_id/favorite" do
    let(:user)        { create(:user) }
    let(:other_user)  { create(:user) }
    let(:meal_master) { create(:meal_master) }

    before { sign_in user }

    it "自分のお気に入りとして登録される" do
      expect { post meal_master_favorite_path(meal_master) }
        .to change { user.favorites.count }.from(0).to(1)
    end

    it "他人のお気に入りは増えない" do
      expect { post meal_master_favorite_path(meal_master) }
        .not_to change { other_user.favorites.count }
    end
  end

  describe "DELETE /meal_masters/:meal_master_id/favorite" do
    context "会員としてログインしている場合" do
      let(:user)        { create(:user) }
      let(:other_user)  { create(:user) }
      let(:meal_master) { create(:meal_master) }

      before { sign_in user }

      it "自分のお気に入りは解除できる" do
        Favorite.create!(user: user, meal_master: meal_master)
        expect { delete meal_master_favorite_path(meal_master) }
          .to change { user.favorites.count }.from(1).to(0)
      end

      it "他人のお気に入りは解除されない" do
        other_favorite = Favorite.create!(user: other_user, meal_master: meal_master)
        delete meal_master_favorite_path(meal_master)
        expect(Favorite.exists?(other_favorite.id)).to be true
      end
    end
  end
end
