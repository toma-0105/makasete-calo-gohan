class TdeeProfilesController < ApplicationController
  before_action :authenticate_user!

  def new
    @tdee_profile = TdeeProfile.new
  end

  def create
    @tdee_profile = TdeeProfile.new(tdee_profile_params)
    @tdee_profile.user = current_user
    if @tdee_profile.save
      TdeeCalculatorService.new(@tdee_profile).calculate
      redirect_to tdee_profile_path(@tdee_profile), notice: "TDEE診断が完了しました"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @tdee_profile = TdeeProfile.find(params[:id])
  end

  private

  def tdee_profile_params
    params.require(:tdee_profile).permit(:height, :weight, :age, :gender, :activity_level)
  end
end
