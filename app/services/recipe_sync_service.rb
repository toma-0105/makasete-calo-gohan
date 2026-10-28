# db/data のレシピJSONを、まとめてDBに反映するサービス
# - recipes_backfill_batch*.json: 既存の料理に PFC・材料・手順を書き込む（バックフィル）
# - recipes.json: まだ登録されていない新しい料理を作成する
# 何回実行しても結果が同じ（冪等）なので、デプロイのたびに実行しても安全
class RecipeSyncService
  BACKFILL_FILE_PATTERN = Rails.root.join("db/data/recipes_backfill_batch*.json")
  IMPORT_FILE_PATH = Rails.root.join("db/data/recipes.json")

  # warnings: 検証で見つかった警告（手順に登場しない材料など。反映は妨げない）
  Result = Struct.new(:backfilled_count, :imported_count, :warnings)

  # 検証エラーのあるレシピが見つかったときに発生する（何も反映せずに止めるため）
  class InvalidRecipeError < StandardError; end

  def call
    backfill_result = validate(Dir.glob(BACKFILL_FILE_PATTERN))
    import_result = validate([ IMPORT_FILE_PATH ])
    importer = MealMasterImportService.new
    new_recipes = unregistered(import_result[:valid_recipes])

    # 途中で失敗しても一部だけ反映された状態にならないよう、全体を1つのトランザクションにまとめる
    ApplicationRecord.transaction do
      backfill_result[:valid_recipes].each { |recipe| importer.backfill(recipe) }
      new_recipes.each { |recipe| importer.import(recipe) }
    end

    Result.new(backfill_result[:valid_recipes].size, new_recipes.size, backfill_result[:issues] + import_result[:issues])
  end

  private

  # 複数のJSONをまとめて検証する。エラーが1件でもあれば、何も反映せずに止める
  def validate(paths)
    recipes = paths.flat_map { |path| JSON.parse(File.read(path))["recipes"] }
    result = RecipeImportService.new(recipes).call

    errors = result[:issues].select { |issue| issue.level == :error }
    if errors.any?
      messages = errors.map { |issue| "#{issue.recipe_name}: #{issue.message}" }
      raise InvalidRecipeError, messages.join("\n")
    end

    result
  end

  # 登録済みの料理名を除く（再実行しても二重に登録しないため）
  def unregistered(recipes)
    registered_names = MealMaster.where(name: recipes.map { |recipe| recipe["name"] }).pluck(:name)
    recipes.reject { |recipe| registered_names.include?(recipe["name"]) }
  end
end
