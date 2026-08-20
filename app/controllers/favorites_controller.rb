class FavoritesController < ApplicationController
  before_action :authenticate_user!
  before_action :reject_guest_user

  # お気に入り登録した料理の一覧（新しい順）
  def index
    @favorites = current_user.favorites.includes(:meal_master).order(created_at: :desc)
  end

  def create
    current_user.favorites.create!(meal_master_id: params[:meal_master_id])
    redirect_back fallback_location: favorites_path, notice: "お気に入りに登録しました"
  rescue ActiveRecord::ActiveRecordError
    # 連打などで既に登録済み・不正なIDの場合は何もせず戻る
    redirect_back fallback_location: favorites_path
  end

  def destroy
    current_user.favorites.find_by(meal_master_id: params[:meal_master_id])&.destroy
    redirect_back fallback_location: favorites_path, notice: "お気に入りを解除しました"
  end

  private

  # お気に入りは会員限定（ビューでは非表示にした上で、URL直打ちもサーバー側で拒否する）
  def reject_guest_user
    return unless current_user.guest?

    redirect_to home_path_for(current_user), alert: "お気に入り機能は会員限定です"
  end
end
