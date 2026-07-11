# 一品料理の分量（グラム）表記が「親子丼(350g)」等と「ハヤシライス」等で不統一だったため、
# 表記のない料理名に分量を追記して統一する（#135）
# 完成された一皿として増量させないため、scaling_typeはfixedのまま変更しない
class AddGramNotationToOneDishNames < ActiveRecord::Migration[7.2]
  # 旧名 => 新名（分量はカロリーから逆算した現実的な一皿の目安量）
  RENAMES = {
    "ナポリタン"                       => "ナポリタン(300g)",
    "ペペロンチーノ"                   => "ペペロンチーノ(250g)",
    "天ぷらうどん"                     => "天ぷらうどん(400g)",
    "チャーハン"                       => "チャーハン(300g)",
    "オムライス"                       => "オムライス(350g)",
    "ハヤシライス"                     => "ハヤシライス(350g)",
    "麻婆豆腐丼"                       => "麻婆豆腐丼(350g)",
    "ツナとキャベツのトマトソースオートミール" => "ツナとキャベツのトマトソースオートミール(200g)",
    "キャベツのお好み焼き"             => "キャベツのお好み焼き(200g)",
    "ビビンバ"                         => "ビビンバ(350g)",
    "しらすと青じそのスパゲッティ"     => "しらすと青じそのスパゲッティ(250g)",
    "いわし缶の和風スパゲッティ"       => "いわし缶の和風スパゲッティ(300g)",
    "たらことえのきのパスタ"           => "たらことえのきのパスタ(300g)",
    "オートミールオムライス"           => "オートミールオムライス(250g)",
    "オートミール中華粥"               => "オートミール中華粥(300g)",
    "オートミールと鶏胸肉の中華粥"     => "オートミールと鶏胸肉の中華粥(300g)"
  }.freeze

  # 移行専用モデル。アプリのモデルは将来の定義変更（enum追加等）で
  # この時点のテーブルとズレる可能性があるため使わない
  class MigrationMealMaster < ActiveRecord::Base
    self.table_name = "meal_masters"
  end

  def up
    # 旧名のレコードだけを更新するため、再実行や新規環境（新名でseed済み）でも安全
    RENAMES.each do |old_name, new_name|
      MigrationMealMaster.where(name: old_name).update_all(name: new_name)
    end
  end

  def down
    RENAMES.each do |old_name, new_name|
      MigrationMealMaster.where(name: new_name).update_all(name: old_name)
    end
  end
end
