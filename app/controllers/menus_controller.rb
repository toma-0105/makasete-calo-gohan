class MenusController < ApplicationController
  before_action :authenticate_user!

  # 保存済みの献立履歴一覧（新しい順）
  def index
    # 献立履歴は会員限定（ビューで非表示にした上で、直接アクセスもサーバー側で拒否する）
    if current_user.guest?
      # マイページもゲスト拒否になったため、ループしないようゲスト用ホームへ逃がす
      return redirect_to home_path_for(current_user), alert: "献立履歴は会員限定の機能です"
    end

    # 同じ日付の献立が複数ある場合に備えて created_at でも並べる
    @menus = current_user.menus.saved.order(date: :desc, created_at: :desc)
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

  # 献立に保存済みフラグを立てて履歴に残す（会員のみ）
  def save
    # ビューでは非表示だが、直接リクエストされた場合に備えてサーバー側でも拒否する
    if current_user.guest?
      return redirect_to menu_path(params[:id]), alert: "献立の保存は会員登録が必要です"
    end

    menu = current_user.menus.find(params[:id])
    result = MenuHistorySaveService.new(current_user, menu).save!
    # 置き換えが起きたときだけ通知を足す
    notice = "献立を保存しました"
    notice += "。同じ日付の保存済み献立を置き換えました" if result.replaced_count.positive?
    redirect_to menu_path(menu), notice: notice
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
