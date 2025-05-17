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

ActiveRecord::Schema[7.2].define(version: 2025_05_12_120945) do
  create_table "events", force: :cascade do |t|
    t.date "date_from"
    t.date "date_to"
    t.time "time_from"
    t.time "time_to"
    t.string "summary"
    t.string "description"
    t.integer "sequence"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "nexo_clients", force: :cascade do |t|
    t.integer "service"
    t.string "secret"
    t.integer "tcp_status"
    t.integer "brand_name"
    t.boolean "user_integrations_allowed"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "nexo_element_versions", force: :cascade do |t|
    t.integer "element_id", null: false
    t.string "payload"
    t.string "etag"
    t.integer "sequence"
    t.integer "origin", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["element_id"], name: "index_nexo_element_versions_on_element_id"
  end

  create_table "nexo_elements", force: :cascade do |t|
    t.integer "folder_id", null: false
    t.integer "synchronizable_id", null: false
    t.string "synchronizable_type", null: false
    t.string "uuid"
    t.boolean "flag_deletion", null: false
    t.integer "deletion_reason"
    t.boolean "conflicted", default: false, null: false
    t.datetime "discarded_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["discarded_at"], name: "index_nexo_elements_on_discarded_at"
    t.index ["folder_id"], name: "index_nexo_elements_on_folder_id"
    t.index ["synchronizable_id"], name: "index_nexo_elements_on_synchronizable_id"
    t.index ["synchronizable_type"], name: "index_nexo_elements_on_synchronizable_type"
  end

  create_table "nexo_folders", force: :cascade do |t|
    t.integer "integration_id", null: false
    t.integer "protocol", null: false
    t.string "external_identifier"
    t.string "name"
    t.string "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["integration_id"], name: "index_nexo_folders_on_integration_id"
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
    t.string "secret"
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

  add_foreign_key "nexo_element_versions", "nexo_elements", column: "element_id"
  add_foreign_key "nexo_elements", "nexo_folders", column: "folder_id"
  add_foreign_key "nexo_folders", "nexo_integrations", column: "integration_id"
  add_foreign_key "nexo_integrations", "nexo_clients", column: "client_id"
  add_foreign_key "nexo_integrations", "users"
  add_foreign_key "nexo_tokens", "nexo_integrations", column: "integration_id"
end
