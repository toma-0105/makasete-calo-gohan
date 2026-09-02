namespace :recipes do
  desc "LLM生成レシピJSONを検証してDBに投入する。例: rails recipes:import[db/data/recipes.json]"
  task :import, [ :path ] => :environment do |_task, args|
    path = args[:path] || Rails.root.join("db/data/recipes.json")
    recipes = JSON.parse(File.read(path))["recipes"]

    result = RecipeImportService.new(recipes).call
    result[:issues].each do |issue|
      puts "[#{issue.level}] #{issue.recipe_name}: #{issue.message}"
    end

    existing_names = MealMaster.where(name: result[:valid_recipes].map { |recipe| recipe["name"] }).pluck(:name)
    new_recipes = result[:valid_recipes].reject { |recipe| existing_names.include?(recipe["name"]) }
    puts "#{existing_names.size}件は登録済みのためスキップしました" if existing_names.any?

    importer = MealMasterImportService.new
    ActiveRecord::Base.transaction do
      new_recipes.each { |recipe| importer.import(recipe) }
    end

    puts "#{new_recipes.size}件のレシピを投入しました"
  end
end
