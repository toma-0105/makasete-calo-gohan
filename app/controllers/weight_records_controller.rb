class WeightRecordsController < ApplicationController
  before_action :authenticate_user!
  before_action :reject_guest_user

  def index
    @weight_record = current_user.weight_records.new
    @weight_records = current_user.weight_records.order(:recorded_on)
    @chart_data = current_user.weight_records.group_by_day(:recorded_on).average(:weight)
  end

  def create
    WeightRecordSaveService.new(
      current_user,
      weight: weight_record_params[:weight],
      recorded_on: weight_record_params[:recorded_on]
    ).save!
    redirect_to weight_records_path, notice: "体重を記録しました"
  rescue ActiveRecord::RecordInvalid
    redirect_to weight_records_path, alert: "体重の記録に失敗しました"
  end

  private

  def weight_record_params
    params.require(:weight_record).permit(:weight, :recorded_on)
  end

  # 体重記録は会員限定（マイページ・お気に入りと同じ方針）
  def reject_guest_user
    return unless current_user.guest?

    redirect_to home_path_for(current_user), alert: "体重記録は会員限定の機能です"
  end
end