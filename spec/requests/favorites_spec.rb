require 'rails_helper'

RSpec.describe "Favorites", type: :request do
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
