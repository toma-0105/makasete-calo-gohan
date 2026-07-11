# 豚汁・けんちん汁は味噌・豆腐を使うのに大豆アレルゲンの紐づけが漏れており、
# 大豆アレルギーのユーザーの献立に選ばれてしまうため、既存データに紐づけを追加する
# （新規環境ではseeds.rbが正しい紐づけを投入するため、このマイグレーションは何もしない）
class AddSoyAllergenToMisoSoups < ActiveRecord::Migration[7.2]
  SOUP_NAMES = [ "豚汁", "けんちん汁" ].freeze
  SOY_NAME = "大豆"

  # 移行専用モデル。アプリのモデルは将来の定義変更（enum追加等）で
  # この時点のテーブルとズレる可能性があるため使わない
  class MigrationMealMaster < ActiveRecord::Base
    self.table_name = "meal_masters"
  end

  class MigrationAllergenMaster < ActiveRecord::Base
    self.table_name = "allergen_masters"
  end

  class MigrationMealIngredient < ActiveRecord::Base
    self.table_name = "meal_ingredients"
  end

  def up
    soy = MigrationAllergenMaster.find_by(name: SOY_NAME)
    # マスタ未投入の新規環境では対象データが無いため何もしない
    return unless soy

    MigrationMealMaster.where(name: SOUP_NAMES).find_each do |meal_master|
      # 再実行しても重複しないよう、無ければ作成する
      MigrationMealIngredient.find_or_create_by!(
        meal_master_id: meal_master.id,
        allergen_master_id: soy.id
      )
    end
  end

  def down
    soy = MigrationAllergenMaster.find_by(name: SOY_NAME)
    return unless soy

    meal_master_ids = MigrationMealMaster.where(name: SOUP_NAMES).pluck(:id)
    MigrationMealIngredient.where(
      meal_master_id: meal_master_ids,
      allergen_master_id: soy.id
    ).delete_all
  end
end
