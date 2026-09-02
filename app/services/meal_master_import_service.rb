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
end
