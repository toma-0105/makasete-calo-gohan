module MenusHelper
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
end
