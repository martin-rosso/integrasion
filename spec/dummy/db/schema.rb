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
  create_table "integrasion_third_party_clients", force: :cascade do |t|
    t.integer "service"
    t.json "secret"
    t.integer "tcp_status"
    t.integer "brand_name"
    t.boolean "user_integrations_allowed"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "integrasion_third_party_integrations", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "third_party_client_id", null: false
    t.string "name"
    t.string "scope"
    t.datetime "expires_at"
    t.datetime "discarded_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["third_party_client_id"], name: "idx_on_third_party_client_id_60c15e2e2b"
    t.index ["user_id"], name: "index_integrasion_third_party_integrations_on_user_id"
  end

  create_table "integrasion_third_party_tokens", force: :cascade do |t|
    t.integer "third_party_integration_id", null: false
    t.json "secret"
    t.integer "tpt_status", null: false
    t.string "environment", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["third_party_integration_id"], name: "idx_on_third_party_integration_id_48c9ddba1c"
  end

  create_table "users", force: :cascade do |t|
    t.string "email"
    t.string "password"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_foreign_key "integrasion_third_party_integrations", "integrasion_third_party_clients", column: "third_party_client_id"
  add_foreign_key "integrasion_third_party_integrations", "users"
  add_foreign_key "integrasion_third_party_tokens", "integrasion_third_party_integrations", column: "third_party_integration_id"
end
