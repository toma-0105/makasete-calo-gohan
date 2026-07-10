class AddGenreToMealMasters < ActiveRecord::Migration[7.2]
  # enumの整数値（MealMaster側の定義と一致させる）
  NEUTRAL  = 0
  JAPANESE = 1
  WESTERN  = 2
  CHINESE  = 3

  # 料理名からジャンルを判定するキーワード（シードと同じルール）
  CHINESE_KEYWORDS  = /中華|麻婆|チンジャオ|酢豚|エビチリ|チリソース|春雨|チャプチェ|ナムル|キムチ|ビビンバ|チヂミ|オイスター|甘酢|ごまだれ|チャーハン/
  WESTERN_KEYWORDS  = /トースト|食パン|スパゲッティ|パスタ|ソテー|ムニエル|グリル|クリーム|チーズ|タンドリー|ロースト|マリネ|ピクルス|カプレーゼ|コールスロー|ポテト|ラペ|ズッキーニ|コンソメ|ハニーマスタード|ベーコン|ウインナー|ハヤシ|ナポリタン|ペペロンチーノ|オムライス|カレー|ガーリック|スクランブル|トマトソース|トマト煮|ヨーグルト|バナナ|りんご/
  JAPANESE_KEYWORDS = /味噌|みそ|照り焼き|塩焼き|塩麹|南蛮|生姜焼き|しぐれ煮|煮|お浸し|和え物|和風|きんぴら|ひじき|切り干し|浅漬け|もずく|梅|しそ|つくね|そぼろ|茶碗蒸し|蒸し|おろし|納豆|豚汁|けんちん|かきたま|丼|うどん|そば|お好み焼き|とんぺい|甘辛|唐揚げ|しゃぶ|厚揚げ|チャンプルー|昆布|小松菜|なす|醤油|卵焼き|鮭|鯖|ぶり|さんま|いわし|あじ|たら|白身魚|ごぼう|れんこん|蓮根|豆腐|挟み焼き|鶏団子/

  # 移行専用モデル。アプリのモデルは将来の定義変更（enum追加等）で
  # この時点のテーブルとズレる可能性があるため使わない
  class MigrationMealMaster < ActiveRecord::Base
    self.table_name = "meal_masters"
  end

  def up
    # 料理のジャンル（neutral: 汎用 / japanese: 和 / western: 洋 / chinese: 中華・アジア）
    add_column :meal_masters, :genre, :integer, null: false, default: NEUTRAL

    # 既存レコードを料理名のキーワードで分類する
    MigrationMealMaster.reset_column_information
    MigrationMealMaster.find_each do |meal_master|
      meal_master.update_column(:genre, genre_for(meal_master.name))
    end
  end

  def down
    remove_column :meal_masters, :genre
  end

  private

  # 判定順序が重要：味噌汁を最優先（具材名の洋風キーワードに誤反応させない）、
  # 次に中華→洋→和の順（「レモンクリーム煮」を洋に、「しらすのスパゲッティ」を洋に倒すため）
  def genre_for(name)
    return JAPANESE if name.include?("味噌汁")

    case name
    when CHINESE_KEYWORDS then CHINESE
    when WESTERN_KEYWORDS then WESTERN
    when JAPANESE_KEYWORDS then JAPANESE
    else NEUTRAL
    end
  end
end
