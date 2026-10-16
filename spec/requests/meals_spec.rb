require 'rails_helper'

RSpec.describe "Meals", type: :request do
  # 1食の入れ替え：他人の献立には触れない
  describe "POST /menus/:menu_id/meals/:meal_timing/regenerate" do
    context "会員としてログインしている場合" do
      let(:user)       { create(:user) }
      let(:other_menu) { create(:menu) }

      before { sign_in user }

      it "他人の献立の1食は入れ替えできず404になる" do
        post regenerate_menu_meal_path(menu_id: other_menu.id, meal_timing: "breakfast")
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
