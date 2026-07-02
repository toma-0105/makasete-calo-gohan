class MypagesController < ApplicationController
  before_action :authenticate_user!

  def show
    @user = current_user
    @tdee_profile = current_user.tdee_profiles.last
  end
end
