class TdeeProfilesController < ApplicationController
  before_action :authenticate_user!

  def new
    @tdee_profile = TdeeProfile.new
  end

  def create
    @tdee_profile = TdeeProfile.new(tdee_profile_params)
    @tdee_profile.user = current_user
    if @tdee_profile.save
      redirect_to root_path, notice: "TDEE診断が完了しました"
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def tdee_profile_params
    params.require(:tdee_profile).permit(:height, :weight, :age, :gender, :activity_level)
  end
end
