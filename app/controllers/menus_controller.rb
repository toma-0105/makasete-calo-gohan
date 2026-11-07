class MenusController < ApplicationController
  before_action :authenticate_user!

  # 直近の献立（昨日以降の献立を、日付の古い順に表示する）
  def index
    # 直近の献立は会員限定（ビューで非表示にした上で、直接アクセスもサーバー側で拒否する）
    if current_user.guest?
      # マイページもゲスト拒否になったため、ループしないようゲスト用ホームへ逃がす
      return redirect_to home_path_for(current_user), alert: "直近の献立は会員限定の機能です"
    end

    @menus = MenuRetentionService.recent_menus(current_user).order(:date)
  end

  def create
    tdee_profile = current_user.tdee_profiles.last
    unless tdee_profile
      return redirect_to new_tdee_profile_path, alert: "先にTDEE診断を行ってください"
    end

    days = params[:days].presence&.to_i || 1
    result = MenuPeriodGeneratorService.new(current_user, tdee_profile, days: days).generate!
    # すでに献立がある日はスキップされるため、生成した分と既存の分をまとめて表示する
    redirect_to period_menus_path(menu_ids: result.all_menus.map(&:id).join(",")), **skipped_flash(result)
  end

  # 複数日分の生成結果をまとめて表示する
  def period
    menu_ids = params[:menu_ids].to_s.split(",").map(&:to_i)
    @menus = current_user.menus.includes(meals: :meal_master).where(id: menu_ids).order(:date)
  end

  def show
    @menu = current_user.menus.includes(meals: { meal_master: :allergen_masters }).find(params[:id])
    @tdee_profile = current_user.tdee_profiles.last
    @favorite_meal_master_ids = current_user.favorites.pluck(:meal_master_id)
  end

  # 既存の献立の中身を新しく生成し直す（献立自体は同じまま）
  def regenerate
    menu = current_user.menus.find(params[:id])
    tdee_profile = current_user.tdee_profiles.last
    unless tdee_profile
      return redirect_to new_tdee_profile_path, alert: "先にTDEE診断を行ってください"
    end

    MenuRegenerateService.new(current_user, menu, tdee_profile).regenerate!
    redirect_to menu_path(menu)
  end

  private

  # スキップした日がある場合の通知を返す
  # 何も生成できなかったときは目立つ alert、一部だけスキップしたときは notice にする
  def skipped_flash(result)
    return {} if result.skipped_menus.empty?

    dates_label = helpers.menu_dates_label(result.skipped_menus.map(&:date))
    if result.menus.empty?
      { alert: "#{dates_label}の献立はすでにあります" }
    else
      { notice: "#{dates_label}の献立はすでにあるため、スキップして残りの日を生成しました" }
    end
  end
end
