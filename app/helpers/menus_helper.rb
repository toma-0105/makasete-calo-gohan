module MenusHelper
  # 食事タイミングの表示順とラベル（朝 → 昼 → 夕）
  MEAL_TIMING_LABELS = { "breakfast" => "朝食", "lunch" => "昼食", "dinner" => "夕食" }.freeze
  # 料理カテゴリの表示順（主食 → 主菜 → 一品料理 → 副菜 → 汁物）
  MEAL_CATEGORY_DISPLAY_ORDER = %w[staple main_dish one_dish side_dish soup].freeze

  # 分量倍率を反映した料理の表示名を返す
  # グラム調整可の料理は、名前中のグラム数を換算値に置き換える（例: ご飯(150g) → ご飯(225g)）
  def meal_display_name(meal)
    name = meal.meal_master.name
    return name unless meal.portion_scale > 1 && meal.meal_master.gram_scalable?

    name.gsub(/(\d+)g/) { "#{(Regexp.last_match(1).to_i * meal.portion_scale).round}g" }
  end

  # 個数調整の料理に付ける倍量ラベル（例: ×2）。それ以外はnil
  def meal_scale_label(meal)
    return unless meal.portion_scale > 1 && meal.meal_master.unit_scalable?

    "×#{meal.portion_scale.to_i}"
  end

  # 1日分の料理を [ラベル, 料理の配列] の形で、朝・昼・夕の順に返す
  # 料理はカテゴリの表示順に並べる。料理がない食事は含めない
  def meals_grouped_by_timing(menu)
    # includes済みのmealsをメモリ上で処理する（.order等を使うと再クエリになりN+1の原因になる）
    grouped = menu.meals.group_by(&:meal_timing)

    MEAL_TIMING_LABELS.filter_map do |timing, label|
      meals = grouped[timing]
      next if meals.blank?

      [ label, meals.sort_by { |meal| MEAL_CATEGORY_DISPLAY_ORDER.index(meal.meal_master.category) || MEAL_CATEGORY_DISPLAY_ORDER.size } ]
    end
  end
end
