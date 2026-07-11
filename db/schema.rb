# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.2].define(version: 2026_07_11_015424) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "allergen_masters", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "category", default: 0, null: false
  end

  create_table "meal_ingredients", force: :cascade do |t|
    t.bigint "meal_master_id", null: false
    t.bigint "allergen_master_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["allergen_master_id"], name: "index_meal_ingredients_on_allergen_master_id"
    t.index ["meal_master_id", "allergen_master_id"], name: "index_meal_ingredients_on_meal_master_and_allergen", unique: true
    t.index ["meal_master_id"], name: "index_meal_ingredients_on_meal_master_id"
  end

  create_table "meal_masters", force: :cascade do |t|
    t.string "name", null: false
    t.integer "calories", null: false
    t.integer "meal_timing", null: false
    t.integer "category", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "scaling_type", default: 0, null: false
    t.integer "genre", default: 0, null: false
  end

  create_table "meals", force: :cascade do |t|
    t.bigint "menu_id", null: false
    t.bigint "meal_master_id", null: false
    t.integer "meal_timing", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.decimal "portion_scale", precision: 3, scale: 2, default: "1.0", null: false
    t.decimal "calories", null: false
    t.index ["meal_master_id"], name: "index_meals_on_meal_master_id"
    t.index ["menu_id"], name: "index_meals_on_menu_id"
  end

  create_table "menus", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.date "date", null: false
    t.decimal "total_calories", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "saved", default: false, null: false
    t.index ["user_id"], name: "index_menus_on_user_id"
  end

  create_table "tdee_profiles", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.decimal "height"
    t.decimal "weight"
    t.integer "age"
    t.integer "gender"
    t.integer "activity_level"
    t.decimal "tdee"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.decimal "target_calories"
    t.index ["user_id"], name: "index_tdee_profiles_on_user_id"
  end

  create_table "user_allergens", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "allergen_master_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["allergen_master_id"], name: "index_user_allergens_on_allergen_master_id"
    t.index ["user_id"], name: "index_user_allergens_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "name"
    t.boolean "guest", default: false, null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "meal_ingredients", "allergen_masters"
  add_foreign_key "meal_ingredients", "meal_masters"
  add_foreign_key "meals", "meal_masters"
  add_foreign_key "meals", "menus"
  add_foreign_key "menus", "users"
  add_foreign_key "tdee_profiles", "users"
  add_foreign_key "user_allergens", "allergen_masters"
  add_foreign_key "user_allergens", "users"
end
