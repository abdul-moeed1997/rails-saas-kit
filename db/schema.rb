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

ActiveRecord::Schema[8.1].define(version: 2026_06_02_120004) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "accounts", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.string "subdomain", null: false
    t.datetime "updated_at", null: false
    t.index ["subdomain"], name: "index_accounts_on_subdomain", unique: true
  end

  create_table "features", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.string "key", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_features_on_key", unique: true
  end

  create_table "invitations", force: :cascade do |t|
    t.datetime "accepted_at"
    t.bigint "account_id", null: false
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.datetime "expires_at", null: false
    t.bigint "invited_by_id", null: false
    t.string "token", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id", "email"], name: "index_invitations_on_account_id_and_email"
    t.index ["account_id"], name: "index_invitations_on_account_id"
    t.index ["invited_by_id"], name: "index_invitations_on_invited_by_id"
    t.index ["token"], name: "index_invitations_on_token", unique: true
  end

  create_table "plan_features", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.boolean "enabled", default: false, null: false
    t.bigint "feature_id", null: false
    t.integer "limit_value"
    t.bigint "plan_id", null: false
    t.datetime "updated_at", null: false
    t.index ["feature_id"], name: "index_plan_features_on_feature_id"
    t.index ["plan_id", "feature_id"], name: "index_plan_features_on_plan_id_and_feature_id", unique: true
    t.index ["plan_id"], name: "index_plan_features_on_plan_id"
  end

  create_table "plans", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.boolean "highlighted", default: false, null: false
    t.string "name", null: false
    t.integer "position", default: 0, null: false
    t.string "slug", null: false
    t.string "status", default: "active", null: false
    t.string "stripe_product_id"
    t.datetime "updated_at", null: false
    t.index ["position"], name: "index_plans_on_position"
    t.index ["slug"], name: "index_plans_on_slug", unique: true
  end

  create_table "prices", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.integer "amount_cents", default: 0, null: false
    t.datetime "created_at", null: false
    t.string "currency", default: "usd", null: false
    t.string "interval", null: false
    t.bigint "plan_id", null: false
    t.string "stripe_price_id"
    t.datetime "updated_at", null: false
    t.index ["plan_id", "interval"], name: "index_prices_on_plan_id_and_interval", unique: true
    t.index ["plan_id"], name: "index_prices_on_plan_id"
  end

  create_table "subscriptions", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.boolean "cancel_at_period_end", default: false, null: false
    t.datetime "canceled_at"
    t.datetime "created_at", null: false
    t.datetime "current_period_end"
    t.datetime "current_period_start"
    t.bigint "price_id", null: false
    t.string "status", default: "active", null: false
    t.string "stripe_customer_id"
    t.string "stripe_subscription_id"
    t.datetime "trial_ends_at"
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_subscriptions_on_account_id", unique: true
    t.index ["price_id"], name: "index_subscriptions_on_price_id"
    t.index ["stripe_subscription_id"], name: "index_subscriptions_on_stripe_subscription_id", unique: true, where: "(stripe_subscription_id IS NOT NULL)"
  end

  create_table "users", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.datetime "created_at", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_users_on_account_id"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "invitations", "accounts"
  add_foreign_key "invitations", "users", column: "invited_by_id"
  add_foreign_key "plan_features", "features"
  add_foreign_key "plan_features", "plans"
  add_foreign_key "prices", "plans"
  add_foreign_key "subscriptions", "accounts"
  add_foreign_key "subscriptions", "prices"
  add_foreign_key "users", "accounts"
end
