require_relative "../config/environment"

# 献立生成の成功率を計測する（#378）
# 何回目の生成で合計カロリーが目標の90〜100%に収まったかを、目標カロリー別に集計してMarkdownの表で出力する
# 計測条件: アレルギー・お気に入りなし（すべての料理が候補）
# 実行方法: docker compose exec web bin/rails runner script/measure_menu_success.rb

# 計測する目標カロリー（kcal）。Issueの例に、小柄な人の目標になりやすい1200を足している
TARGET_CALORIES_LIST = [ 1200, 1500, 2000, 2500, 3200 ].freeze
# 目標カロリー1つあたりの計測回数
TRIALS_PER_TARGET = 100
# 上限回数と許容範囲の下限はアプリ本体の定数を参照し、本体を変えたときに計測とずれないようにする
MAX_ATTEMPTS = MenuCalorieRangeSelectorService::MAX_ATTEMPTS
MIN_CALORIE_RATIO = MenuCalorieRangeSelectorService::MIN_CALORIE_RATIO

# MenuCalorieRangeSelectorService#generate の再試行ループを再現し、何回目で範囲内に収まったかを返す
# （本体は回数を返さないため）
# 収まらなかった場合は、本体が代わりに採用する「最も目標に近い献立」が
# 目標を超えていれば :over、目標の90%に届かなければ :under を返す
# 本体の判定方法を変えたら、ここも合わせて直す
def trial_result(target_calories)
  totals = []
  (1..MAX_ATTEMPTS).each do |attempt|
    menu = MenuGeneratorService.new(target_calories: target_calories).generate
    totals << menu.values.flatten.sum(&:calories)
    return attempt if totals.last.between?(target_calories * MIN_CALORIE_RATIO, target_calories)
  end

  closest_total = totals.min_by { |total| (target_calories - total).abs }
  closest_total > target_calories ? :over : :under
end

def markdown_row(label, cells)
  "| #{label} | #{cells.join(" | ")} |"
end

# 目標カロリーごとに { 何回目で成功したか => 件数 } を集計する（失敗は :over / :under => 件数）
results = TARGET_CALORIES_LIST.index_with do |target_calories|
  Array.new(TRIALS_PER_TARGET) { trial_result(target_calories) }.tally
end

# 成功率は料理データの件数で変わるため、計測時点の件数も出力する
puts "料理データ: #{MealMaster.count}件 / 目標カロリーごとに#{TRIALS_PER_TARGET}回計測"
puts markdown_row("何回目で成功", TARGET_CALORIES_LIST.map { |target_calories| "#{target_calories}kcal" })
puts markdown_row("---", Array.new(TARGET_CALORIES_LIST.size, "---"))
(1..MAX_ATTEMPTS).each do |attempt|
  puts markdown_row("#{attempt}回目", results.values.map { |tally| tally.fetch(attempt, 0) })
end
puts markdown_row("失敗（目標を超えた）", results.values.map { |tally| tally.fetch(:over, 0) })
puts markdown_row("失敗（目標の90%に届かない）", results.values.map { |tally| tally.fetch(:under, 0) })
