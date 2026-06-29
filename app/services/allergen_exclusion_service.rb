class AllergenExclusionService
  def initialize(user)
    @user = user
  end

  def excluded_meal_master_ids
    return [] if allergen_master_ids.empty?

    MealIngredient.where(allergen_master_id: allergen_master_ids).pluck(:meal_master_id)
  end

  private

  def allergen_master_ids
    @allergen_master_ids ||= @user.allergens.pluck(:id)
  end
end
