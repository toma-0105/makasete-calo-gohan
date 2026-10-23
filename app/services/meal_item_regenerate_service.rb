# 献立の中の1品（Meal）だけを、同じカテゴリの別の料理に入れ替えるサービス（#327）
class MealItemRegenerateService
  # 入れ替えられる候補が無かったときのエラー（コントローラーで通知に変換する）
  class NoCandidateError < StandardError; end

  # 食事のジャンルを決める主役のカテゴリ
  LEAD_CATEGORIES = %w[main_dish one_dish].freeze

  def initialize(meal)
    @meal = meal
    @menu = meal.menu
    @user = @menu.user
  end

  def regenerate!
    # 候補の選定はDB書き込みを伴わないためトランザクションの外で行う
    selected = select_replacement
    raise NoCandidateError unless selected

    # 品の差し替えと合計カロリーの再計算を同時に行い、片方だけ反映されるのを防ぐ
    ApplicationRecord.transaction do
      @meal.update!(meal_master: selected.meal_master, portion_scale: selected.portion_scale, calories: selected.calories)
      @menu.update!(total_calories: @menu.meals.sum(:calories))
    end

    @meal
  end

  private

  def select_replacement
    MenuGeneratorService.new(
      excluded_meal_master_ids: excluded_meal_master_ids,
      favorite_meal_master_ids: @user.favorites.pluck(:meal_master_id)
    ).generate_item_for(
      meal_timing: @meal.meal_timing,
      category: @meal.meal_master.category,
      lead_meal_master: genre_lead_meal_master,
      target_calories: @meal.calories
    )
  end

  # 現在の献立で使用済みの料理（入れ替え前の自分自身も含む）と、アレルギー食材を含む料理
  def excluded_meal_master_ids
    @menu.meals.pluck(:meal_master_id) + AllergenExclusionService.new(@user).excluded_meal_master_ids
  end

  # ジャンルを合わせる基準にする料理（同じ食の、入れ替え対象以外の品から選ぶ）
  # ・主菜/一品料理を入れ替えるとき：他の品のうちジャンルを持つもの（無ければnil＝絞り込まない）
  # ・主食/副菜/汁物を入れ替えるとき：同じ食の主菜（または一品料理）
  def genre_lead_meal_master
    others = other_meal_masters_in_same_timing
    if LEAD_CATEGORIES.include?(@meal.meal_master.category)
      others.find { |meal_master| !meal_master.neutral? }
    else
      others.find { |meal_master| LEAD_CATEGORIES.include?(meal_master.category) }
    end
  end

  # 同じ食（朝・昼・夕）にある、入れ替え対象以外の料理
  def other_meal_masters_in_same_timing
    @menu.meals.includes(:meal_master)
         .where(meal_timing: @meal.meal_timing)
         .where.not(id: @meal.id)
         .map(&:meal_master)
  end
end
