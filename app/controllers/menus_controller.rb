class MenusController < ApplicationController
  before_action :authenticate_user!

  # 保存済みの献立履歴一覧（新しい順）
  def index
    # 献立履歴は会員限定（ビューで非表示にした上で、直接アクセスもサーバー側で拒否する）
    if current_user.guest?
      return redirect_to mypage_path, alert: "献立履歴は会員限定の機能です"
    end

    # 同じ日付の献立が複数ある場合に備えて created_at でも並べる
    @menus = current_user.menus.saved.order(date: :desc, created_at: :desc)
  end

  def create
    tdee_profile = current_user.tdee_profiles.last
    unless tdee_profile
      return redirect_to new_tdee_profile_path, alert: "先にTDEE診断を行ってください"
    end

    menu_hash = MenuCalorieRangeSelectorService.new(tdee_profile).generate
    menu = MenuSaveService.new(current_user, menu_hash).save!
    redirect_to menu_path(menu)
  end

  def show
    @menu = current_user.menus.includes(meals: :meal_master).find(params[:id])
    @meals_by_timing = @menu.meals.group_by(&:meal_timing)
    @tdee_profile = current_user.tdee_profiles.last
  end

  # 献立に保存済みフラグを立てて履歴に残す（会員のみ）
  def save
    # ビューでは非表示だが、直接リクエストされた場合に備えてサーバー側でも拒否する
    if current_user.guest?
      return redirect_to menu_path(params[:id]), alert: "献立の保存は会員登録が必要です"
    end

    menu = current_user.menus.find(params[:id])
    menu.update!(saved: true)
    redirect_to menu_path(menu), notice: "献立を保存しました"
  end

  # 既存の献立を削除して新しい献立を生成し直す
  def regenerate
    old_menu = current_user.menus.find(params[:id])
    tdee_profile = current_user.tdee_profiles.last
    unless tdee_profile
      return redirect_to new_tdee_profile_path, alert: "先にTDEE診断を行ってください"
    end

    new_menu = MenuRegenerateService.new(current_user, old_menu, tdee_profile).regenerate!
    redirect_to menu_path(new_menu)
  end
end
