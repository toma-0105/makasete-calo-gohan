# 体重グラフの縦軸の表示範囲（最小値・最大値）を、記録データに合わせて算出する
class WeightChartRangeService
  # 記録の最小値・最大値の外側に確保する余白（kg）
  MARGIN_KG = 1

  def initialize(weights)
    @weights = weights.compact
  end

  def call
    return if @weights.empty?

    {
      min: (@weights.min - MARGIN_KG).floor,
      max: (@weights.max + MARGIN_KG).ceil
    }
  end
end
