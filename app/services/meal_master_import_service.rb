# 検証済みのレシピ(Hash)から MealMaster とアレルゲン紐付け(MealIngredient)を作成するサービス
class MealMasterImportService
  def initialize
    @allergen_master_by_name = AllergenMaster.all.index_by(&:name)
  end

  # 検証済みレシピ1件からMealMasterとMealIngredientを作成する
  def import(recipe)
    meal_master = MealMaster.create!(
      name: recipe["name"],
      meal_timing: recipe["meal_timing"],
      category: recipe["category"],
      scaling_type: recipe["scaling_type"],
      genre: recipe["genre"],
      calories: recipe["calories"],
      protein: recipe["protein"],
      fat: recipe["fat"],
      carbohydrate: recipe["carbohydrate"],
      ingredients: recipe["ingredients"],
      steps: recipe["steps"]
    )

    recipe["allergens"].each do |allergen_name|
      allergen_master = @allergen_master_by_name.fetch(allergen_name)
      MealIngredient.create!(meal_master: meal_master, allergen_master: allergen_master)
    end

    meal_master
  end

  # 既存のMealMasterにPFC・材料・手順をバックフィルする（名前で既存レコードを特定する）
  # アレルゲン紐付け(meal_ingredients)はseeds.rb作成時点で登録済みのため更新しない
  # 「ご飯(100g)」等は朝食用・昼夕用で同名の別レコードが存在するため、
  # meal_timingも条件に含めないと誤って別のレコードを更新してしまう
  def backfill(recipe)
    meal_master = MealMaster.find_by!(name: recipe["name"], meal_timing: recipe["meal_timing"])
    meal_master.update!(
      protein: recipe["protein"],
      fat: recipe["fat"],
      carbohydrate: recipe["carbohydrate"],
      ingredients: recipe["ingredients"],
      steps: recipe["steps"]
    )
  end
end
