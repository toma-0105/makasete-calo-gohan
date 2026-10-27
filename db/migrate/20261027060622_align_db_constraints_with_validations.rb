class AlignDbConstraintsWithValidations < ActiveRecord::Migration[8.1]
  def change
    # 同じユーザーが同じアレルギーを重複して登録できないようにする
    add_index :user_allergens, %i[user_id allergen_master_id], unique: true

    # モデルで必須にしている項目を、DBでも必須にする
    # （tdee と target_calories は作成後に別の処理で埋めるので対象外）
    %i[height weight age gender activity_level].each do |column|
      change_column_null :tdee_profiles, column, false
    end

    change_column_null :allergen_masters, :name, false
  end
end

