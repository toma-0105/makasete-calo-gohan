class MoveBreadToBreakfastAndAddOatmealDishes < ActiveRecord::Migration[7.2]
  BREAD_NAME    = "食パン8枚切り1枚(45g)"
  ONIGIRI_NAME  = "オートミールの枝豆とチーズの塩昆布おにぎり1個"
  PORRIDGE_NAME = "オートミールと鶏胸肉の中華粥"

  # 移行専用モデル（マスタ投入済みかどうかの判定のみに使用）
  class MigrationAllergenMaster < ActiveRecord::Base
    self.table_name = "allergen_masters"
  end

  def up
    # このマイグレーションは「旧シードで構築済みの既存データ」を更新するためのもの。
    # 新規環境（マスタ未投入）では対象データが無く、アレルゲンの紐づけも失敗するため何もしない
    # （食パンの朝食化・オートミール料理は現在のseeds.rbに反映済みで、seedで投入される）
    return if MigrationAllergenMaster.none?

    # トースト（食パン）は朝食専用にする（夕食にトーストが出る違和感の解消）
    # 献立履歴が参照している可能性があるため、削除ではなく朝食プールへ移動する
    MealMaster.lunch_or_dinner.find_by(name: BREAD_NAME)&.update!(meal_timing: :breakfast)

    # オートミールのレシピを追加
    onigiri = MealMaster.create!(
      name: ONIGIRI_NAME, calories: 180,
      meal_timing: :lunch_or_dinner, category: :staple,
      scaling_type: :unit_scalable, genre: :japanese
    )
    porridge = MealMaster.create!(
      name: PORRIDGE_NAME, calories: 250,
      meal_timing: :lunch_or_dinner, category: :one_dish,
      scaling_type: :fixed, genre: :chinese
    )

    # アレルギー食材の紐づけ（チーズ→乳 / 枝豆→大豆 / 鶏胸肉→鶏肉）
    link_allergens(onigiri, %w[乳 大豆])
    link_allergens(porridge, %w[鶏肉])
  end

  def down
    MealMaster.breakfast.find_by(name: BREAD_NAME)&.update!(meal_timing: :lunch_or_dinner)
    MealMaster.where(name: [ ONIGIRI_NAME, PORRIDGE_NAME ]).find_each do |meal_master|
      MealIngredient.where(meal_master: meal_master).delete_all
      meal_master.destroy!
    end
  end

  private

  def link_allergens(meal_master, allergen_names)
    allergen_names.each do |allergen_name|
      allergen = AllergenMaster.find_by!(name: allergen_name)
      MealIngredient.create!(meal_master: meal_master, allergen_master: allergen)
    end
  end
end
