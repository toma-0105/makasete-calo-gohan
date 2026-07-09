module ApplicationHelper
  # ボタンのスタイルは全ページ共通のため、ここで一元管理する
  # （同じクラスの羅列を各ビューに重複させない・変更を1箇所で済ませるため）
  # 幅や余白などのレイアウトは画面ごとに異なるので、引数 extra で受け取る

  # 主役ボタン（黄色塗りつぶし）：1画面に1つが原則
  def primary_button_classes(extra = "")
    class_names(
      "bg-[#F9C639] text-[#3a3820] text-center py-3.5 rounded-lg text-[14px] font-semibold cursor-pointer",
      primary_button_feedback,
      extra
    )
  end

  # 脇役ボタン（アウトライン型）
  def secondary_button_classes(extra = "")
    class_names(
      "border border-[#D8D4A8] text-[#5a5530] text-center py-3.5 rounded-lg text-[14px] cursor-pointer",
      secondary_button_feedback,
      extra
    )
  end

  # クリックフィードバック（ホバーで色変化・押下で縮小・変化は滑らかに）
  # ヘッダーのナビチップなどサイズが異なるボタンは、動きだけこちらを共通利用する

  # 主役ボタン用：ホバーで黄色を一段濃くする
  def primary_button_feedback
    "hover:bg-[#EAB52C] active:scale-95 transition"
  end

  # 脇役ボタン用：ホバーでうっすら黄色がかる
  def secondary_button_feedback
    "hover:bg-[#FFF8C4] active:scale-95 transition"
  end
end
