# 朝・昼・夕の献立をmeal_mastersから組み合わせ選出するサービス
# カロリー範囲判定（#24）・アレルギー除外（#26）・DB保存（#25）は別issueの責務のため、
# このクラスでは「カテゴリ構成が正しい組み合わせを選ぶ」ことのみを担う
class MenuGeneratorService
  # 一品料理（カレー・丼物など）が選ばれる確率
  ONE_DISH_SELECTION_PROBABILITY = 0.3
  # 基本形（主食+主菜+副菜）・one_dishに汁物を追加する確率
  SOUP_INCLUSION_PROBABILITY = 0.5
  # one_dishに副菜・サラダを追加する確率
  ONE_DISH_SIDE_DISH_INCLUSION_PROBABILITY = 0.5
  # 昼食（お弁当想定）から除外するスープ系一品料理のキーワード
  LUNCH_EXCLUDED_ONE_DISH_KEYWORDS = %w[ラーメン スープ 汁 うどん].freeze

  def initialize
    # 昼・夕は共通プールのため、選出済みIDを記録して重複を避ける
    @used_meal_master_ids = []
  end

  def generate
    {
      breakfast: generate_breakfast,
      lunch: generate_lunch_or_dinner(period: :lunch),
      dinner: generate_lunch_or_dinner(period: :dinner)
    }
  end

  private

  def generate_breakfast
    select_basic_combo(MealMaster.breakfast, include_soup: true)
  end

  def generate_lunch_or_dinner(period:)
    pool = MealMaster.lunch_or_dinner.where.not(id: @used_meal_master_ids)
    one_dish_candidates = one_dish_candidates_for(pool, period: period)

    meals =
      if one_dish_candidates.any? && select_one_dish?
        # one_dishは主食・主菜を追加しないが、副菜・汁物は追加可能（汁物は昼食=弁当想定のため夕食限定）
        select_one_dish_combo(one_dish_candidates, pool, include_soup: period == :dinner)
      else
        # 昼食は弁当想定のため、汁物（スープ系の単品含む）を候補から除く
        combo_pool = period == :lunch ? pool.where.not(category: :soup) : pool
        select_basic_combo(combo_pool, include_soup: period == :dinner)
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

  def select_basic_combo(pool, include_soup:)
    meals = [
      pick_random(pool.staple),
      pick_random(pool.main_dish),
      pick_random(pool.side_dish)
    ]
    add_soup_if_needed(meals, pool, include_soup: include_soup)
  end

  def select_one_dish_combo(candidates, pool, include_soup:)
    meals = [ pick_random(candidates) ]
    meals << pick_random(pool.side_dish) if include_side_dish?
    add_soup_if_needed(meals, pool, include_soup: include_soup)
  end

  def add_soup_if_needed(meals, pool, include_soup:)
    meals << pick_random(pool.soup) if include_soup && include_soup?
    meals
  end

  def select_one_dish?
    rand < ONE_DISH_SELECTION_PROBABILITY
  end

  def include_soup?
    rand < SOUP_INCLUSION_PROBABILITY
  end

  def include_side_dish?
    rand < ONE_DISH_SIDE_DISH_INCLUSION_PROBABILITY
  end

  def pick_random(meals)
    meals.to_a.sample
  end
end
