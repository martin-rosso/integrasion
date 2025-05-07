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

ActiveRecord::Schema[7.2].define(version: 2025_05_06_125057) do
  create_table "nexo_clients", force: :cascade do |t|
    t.integer "service"
    t.json "secret"
    t.integer "tcp_status"
    t.integer "brand_name"
    t.boolean "user_integrations_allowed"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "nexo_integrations", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "client_id", null: false
    t.string "name"
    t.string "scope"
    t.datetime "expires_at"
    t.datetime "discarded_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["client_id"], name: "index_nexo_integrations_on_client_id"
    t.index ["user_id"], name: "index_nexo_integrations_on_user_id"
  end

  create_table "nexo_tokens", force: :cascade do |t|
    t.integer "integration_id", null: false
    t.json "secret"
    t.integer "tpt_status", null: false
    t.string "environment", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["integration_id"], name: "index_nexo_tokens_on_integration_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email"
    t.string "password"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_foreign_key "nexo_integrations", "nexo_clients", column: "client_id"
  add_foreign_key "nexo_integrations", "users"
  add_foreign_key "nexo_tokens", "nexo_integrations", column: "integration_id"
end
