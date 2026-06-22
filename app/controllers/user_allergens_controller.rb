class UserAllergensController < ApplicationController
  before_action :authenticate_user!

  def new
    @allergen_masters = AllergenMaster.all
    @user_allergen = current_user.user_allergens.build
    @selected_allergen_ids = current_user.user_allergens.pluck(:allergen_master_id)
  end

  def create
    allergen_ids = params[:allergen_ids] || []

    ActiveRecord::Base.transaction do
      current_user.user_allergens.destroy_all
      allergen_ids.each do |id|
        current_user.user_allergens.create!(allergen_master_id: id)
      end
    end

    redirect_to mypage_path, notice: "アレルギー設定を保存しました"
  rescue ActiveRecord::ActiveRecordError
    @allergen_masters = AllergenMaster.all
    flash.now[:alert] = "保存に失敗しました"
    render :new, status: :unprocessable_entity
  end
end
