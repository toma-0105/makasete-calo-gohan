# 朝・昼・夕の献立をmeal_mastersから組み合わせ選出するサービス
# 目標カロリー（target_calories）が指定された場合は、朝・昼・夕に配分した
# カロリーに近づくよう、主食・主菜・一品料理へ分量倍率を適用して調整する
class MenuGeneratorService
  # 選出した料理と分量倍率のペア。確定カロリーは基準カロリー×倍率で算出する
  # id/name/categoryはMealMasterへ委譲し、料理そのものとして扱えるようにする
  SelectedMeal = Struct.new(:meal_master, :portion_scale) do
    delegate :id, :name, :category, to: :meal_master

    def calories
      (meal_master.calories * portion_scale).round
    end
  end

  # 一品料理（カレー・丼物など）が選ばれる確率
  ONE_DISH_SELECTION_PROBABILITY = 0.3
  # 基本形（主食+主菜+副菜）・one_dishに汁物を追加する確率
  SOUP_INCLUSION_PROBABILITY = 0.5
  # 昼食（お弁当想定）から除外するスープ系一品料理のキーワード
  LUNCH_EXCLUDED_ONE_DISH_KEYWORDS = %w[ラーメン スープ 汁 うどん].freeze
  # 目標カロリーの朝・昼・夕への配分比率
  MEAL_CALORIE_RATIOS = { breakfast: 0.25, lunch: 0.35, dinner: 0.40 }.freeze
  # 分量の変え方（scaling_type）ごとに適用できる倍率の候補
  # gram_scalable: グラム換算で細かく調整できる / unit_scalable: 2個分など現実に作れる量のみ / fixed: 調整不可
  PORTION_SCALES_BY_TYPE = {
    "fixed"         => [ 1.0 ].freeze,
    "gram_scalable" => [ 1.0, 1.25, 1.5, 2.0 ].freeze,
    "unit_scalable" => [ 1.0, 2.0 ].freeze
  }.freeze
  # 倍率を適用しない場合の値（副菜・汁物は常に等倍）
  DEFAULT_SCALE = 1.0

  def initialize(excluded_meal_master_ids: [], target_calories: nil)
    # 昼・夕は共通プールのため、選出済みIDを記録して重複を避ける
    @used_meal_master_ids = []
    # アレルギー食材を含む料理など、選出対象から除外するID（#26）
    @excluded_meal_master_ids = excluded_meal_master_ids
    @target_calories = target_calories
  end

  def generate
    {
      breakfast: generate_breakfast,
      lunch: generate_lunch_or_dinner(period: :lunch),
      dinner: generate_lunch_or_dinner(period: :dinner)
    }
  end

  private

  # その食事に配分するカロリー（目標未指定ならnil＝調整なし）
  def allocated_calories_for(meal_timing)
    return nil unless @target_calories

    @target_calories * MEAL_CALORIE_RATIOS[meal_timing]
  end

  def generate_breakfast
    select_basic_combo(
      MealMaster.breakfast.where.not(id: @excluded_meal_master_ids),
      include_soup: true,
      allocated_calories: allocated_calories_for(:breakfast)
    )
  end

  def generate_lunch_or_dinner(period:)
    pool = MealMaster.lunch_or_dinner.where.not(id: @used_meal_master_ids + @excluded_meal_master_ids)
    one_dish_candidates = one_dish_candidates_for(pool, period: period)
    allocated_calories = allocated_calories_for(period)

    meals =
      if one_dish_candidates.any? && select_one_dish?
        # one_dishは主食・主菜を追加しない。副菜は必ず添え、汁物は夕食のみ確率で追加（昼食=弁当想定）
        select_one_dish_combo(one_dish_candidates, pool,
                              include_soup: period == :dinner, allocated_calories: allocated_calories)
      else
        # 昼食は弁当想定のため、汁物（スープ系の単品含む）を候補から除く
        combo_pool = period == :lunch ? pool.where.not(category: :soup) : pool
        select_basic_combo(combo_pool, include_soup: period == :dinner, allocated_calories: allocated_calories)
      end

    @used_meal_master_ids.concat(meals.map(&:id))
    meals
  end

  def one_dish_candidates_for(pool, period:)
    candidates = pool.one_dish.to_a
    return candidates unless period == :lunch

    candidates.reject do |meal|
      LUNCH_EXCLUDED_ONE_DISH_KEYWORDS.any? { |keyword| meal.name.include?(keyword) }
    end
  end

  def select_basic_combo(pool, include_soup:, allocated_calories: nil)
    # 主菜を最初に選び、その食事のジャンルを確定させる（和洋混在を防ぐ #105）
    main = pick_random(pool.main_dish)
    # 副菜・汁物は倍率調整の対象外（先に確定させる）
    extras = [ SelectedMeal.new(pick_random(genre_matched(pool.side_dish, main)), DEFAULT_SCALE) ]
    extras << SelectedMeal.new(pick_random(genre_matched(pool.soup, main)), DEFAULT_SCALE) if include_soup && include_soup?

    staple_meal, main_meal = fit_staple_and_main(genre_matched(pool.staple, main).to_a, main, extras, allocated_calories)
    [ staple_meal, main_meal, *extras ]
  end

  def select_one_dish_combo(candidates, pool, include_soup:, allocated_calories: nil)
    one_dish = pick_random(candidates)
    # 品数バランスのため、一品料理にも副菜を必ず添える（最低2品を保証 #106）
    # 副菜・汁物は一品料理のジャンルに合わせる（#105）
    extras = [ SelectedMeal.new(pick_random(genre_matched(pool.side_dish, one_dish)), DEFAULT_SCALE) ]
    extras << SelectedMeal.new(pick_random(genre_matched(pool.soup, one_dish)), DEFAULT_SCALE) if include_soup && include_soup?

    scale = fit_one_dish_scale(one_dish, extras, allocated_calories)
    [ SelectedMeal.new(one_dish, scale), *extras ]
  end

  # 配分カロリーに最も近づく「主食×倍率」「主菜の倍率」の組み合わせを選ぶ
  # 目標未指定の場合は主食をランダムに選び、倍率は適用しない
  def fit_staple_and_main(staples, main, extras, allocated_calories)
    if allocated_calories.nil?
      return [ SelectedMeal.new(staples.sample, DEFAULT_SCALE), SelectedMeal.new(main, DEFAULT_SCALE) ]
    end

    extras_calories = extras.sum(&:calories)
    candidates = staples.flat_map do |staple|
      portion_scales_for(staple).flat_map do |staple_scale|
        portion_scales_for(main).map do |main_scale|
          [ SelectedMeal.new(staple, staple_scale), SelectedMeal.new(main, main_scale) ]
        end
      end
    end

    candidates.min_by do |staple_meal, main_meal|
      diff = (allocated_calories - (extras_calories + staple_meal.calories + main_meal.calories)).abs
      # 差が同じなら控えめな倍率を優先する
      [ diff, staple_meal.portion_scale + main_meal.portion_scale ]
    end
  end

  # 配分カロリーの残りに最も近づく一品料理の倍率を選ぶ
  def fit_one_dish_scale(one_dish, extras, allocated_calories)
    return DEFAULT_SCALE unless allocated_calories

    remaining = allocated_calories - extras.sum(&:calories)
    portion_scales_for(one_dish).min_by { |scale| ((one_dish.calories * scale) - remaining).abs }
  end

  # その料理に適用できる倍率の候補（分量の変え方の分類による）
  def portion_scales_for(meal_master)
    PORTION_SCALES_BY_TYPE.fetch(meal_master.scaling_type)
  end

  # 主役の料理（主菜・一品料理）とジャンルが合う候補に絞り込む
  # 汎用（neutral）はどのジャンルとも組み合わせ可能。主役が汎用なら絞り込まない
  # 絞り込むと候補がゼロになる場合は、献立を成立させることを優先して絞り込みを諦める
  def genre_matched(scope, lead_meal)
    return scope if lead_meal.nil? || lead_meal.neutral?

    matched = scope.where(genre: [ lead_meal.genre, :neutral ])
    matched.exists? ? matched : scope
  end

  def select_one_dish?
    rand < ONE_DISH_SELECTION_PROBABILITY
  end

  def include_soup?
    rand < SOUP_INCLUSION_PROBABILITY
  end

  def pick_random(meals)
    meals.to_a.sample
  end
end
