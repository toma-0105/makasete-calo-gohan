# LLMで生成したレシピJSON（db/data/recipes.json 等）の内容を検証するサービス
# MealMaster自身のバリデーション（#225）は「1件の形式」しか見ないため、
# 「JSON全体の必須項目」「DBに実在するアレルゲン名か」といった検証をここで行う
class RecipeImportService
  # level: :error（投入不可） または :warning（投入はするが要確認）
  Issue = Struct.new(:recipe_name, :level, :message)

  REQUIRED_KEYS = %w[
    name meal_timing category scaling_type genre calories protein fat carbohydrate ingredients steps allergens
  ].freeze

  VALID_MEAL_TIMINGS = %w[breakfast lunch_or_dinner].freeze
  VALID_CATEGORIES = %w[staple main_dish side_dish soup one_dish].freeze
  VALID_SCALING_TYPES = %w[fixed gram_scalable unit_scalable].freeze
  VALID_GENRES = %w[neutral japanese western chinese].freeze
  # 材料名から取り除く修飾語（「生鮭」→「鮭」のように中心的な名詞で手順との一致を見るため）
  INGREDIENT_MODIFIER_PREFIXES = %w[生 むき 絹 無調整 焼き 和風 乾燥].freeze

  def initialize(recipes)
    @recipes = recipes
  end

  # 検証結果を返す。errorが1件でもあるレシピはvalid_recipesに含めない
  def call
    issues = @recipes.flat_map { |recipe| validate_recipe(recipe) }
    invalid_names = issues.select { |issue| issue.level == :error }.map(&:recipe_name).to_set
    valid_recipes = @recipes.reject { |recipe| invalid_names.include?(recipe["name"]) }

    { valid_recipes: valid_recipes, issues: issues }
  end

  private

  def validate_recipe(recipe)
    name = recipe["name"] || "(name未設定)"
    missing_keys = REQUIRED_KEYS - recipe.keys
    return [ Issue.new(name, :error, "必須項目が不足しています: #{missing_keys.join('、')}") ] if missing_keys.any?

    [
      *validate_enum(name, "meal_timing", recipe["meal_timing"], VALID_MEAL_TIMINGS),
      *validate_enum(name, "category", recipe["category"], VALID_CATEGORIES),
      *validate_enum(name, "scaling_type", recipe["scaling_type"], VALID_SCALING_TYPES),
      *validate_enum(name, "genre", recipe["genre"], VALID_GENRES),
      *validate_allergens(name, recipe["allergens"]),
      *validate_ingredients_format(name, recipe["ingredients"]),
      *validate_ingredients_appear_in_steps(name, recipe["ingredients"], recipe["steps"])
    ]
  end

  def validate_enum(name, key, value, allowed_values)
    return [] if allowed_values.include?(value)

    [ Issue.new(name, :error, "#{key}の値が不正です: #{value.inspect}") ]
  end

  def validate_allergens(name, allergens)
    unknown = allergens - known_allergen_names
    return [] if unknown.empty?

    [ Issue.new(name, :error, "未知のアレルゲン名です: #{unknown.join('、')}") ]
  end

  def validate_ingredients_format(name, ingredients)
    invalid = ingredients.reject { |ingredient| ingredient["name"].present? && ingredient["amount"].present? }
    return [] if invalid.empty?

    [ Issue.new(name, :error, "name・amountが欠けている材料があります") ]
  end

  # 材料名が手順の文章に登場するかを確認する。日本語の表記ゆれ（生鮭→鮭 等）があるため
  # 検出精度は完全ではなく、投入は妨げずwarningとして報告するに留める
  def validate_ingredients_appear_in_steps(name, ingredients, steps)
    steps_text = steps.join
    missing = ingredients.reject { |ingredient| steps_text.include?(core_name(ingredient["name"])) }
    return [] if missing.empty?

    missing_names = missing.map { |ingredient| ingredient["name"] }
    [ Issue.new(name, :warning, "手順に登場しない材料があります（表記ゆれの可能性あり）: #{missing_names.join('、')}") ]
  end

  def core_name(ingredient_name)
    without_prefix = ingredient_name.sub(/\A(#{INGREDIENT_MODIFIER_PREFIXES.join('|')})/, "")
    without_prefix.split(/[(・]/).first
  end

  def known_allergen_names
    @known_allergen_names ||= AllergenMaster.pluck(:name)
  end
end
