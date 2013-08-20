# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20130820204024) do

  create_table "appliance_sets", force: true do |t|
    t.string   "name"
    t.string   "context_id",                                 null: false
    t.integer  "priority",           default: 50,            null: false
    t.string   "appliance_set_type", default: "development", null: false
    t.integer  "user_id",                                    null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "appliance_sets", ["context_id"], name: "index_appliance_sets_on_context_id", unique: true, using: :btree
  add_index "appliance_sets", ["user_id"], name: "index_appliance_sets_on_user_id", using: :btree

  create_table "appliance_types", force: true do |t|
    t.string   "name",                                            null: false
    t.text     "description"
    t.boolean  "shared",            default: false,               null: false
    t.boolean  "scalable",          default: false,               null: false
    t.string   "visibility",        default: "under_development", null: false
    t.float    "preference_cpu"
    t.integer  "preference_memory"
    t.integer  "preference_disk"
    t.integer  "security_proxy_id"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "appliance_types", ["name"], name: "index_appliance_types_on_name", unique: true, using: :btree
  add_index "appliance_types", ["user_id"], name: "appliance_types_user_id_fk", using: :btree

  create_table "appliances", force: true do |t|
    t.integer  "appliance_set_id"
    t.integer  "appliance_type_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "security_policies", force: true do |t|
    t.string   "name"
    t.text     "payload"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "security_policies", ["name"], name: "index_security_policies_on_name", unique: true, using: :btree

  create_table "security_policies_users", force: true do |t|
    t.integer "user_id"
    t.integer "security_policy_id"
  end

  create_table "security_proxies", force: true do |t|
    t.string   "name"
    t.text     "payload"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "security_proxies", ["name"], name: "index_security_proxies_on_name", unique: true, using: :btree

  create_table "security_proxies_users", force: true do |t|
    t.integer "user_id"
    t.integer "security_proxy_id"
  end

  create_table "users", force: true do |t|
    t.string   "login",                  default: "", null: false
    t.string   "encrypted_password",     default: "", null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          default: 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.string   "authentication_token"
    t.string   "email",                  default: "", null: false
    t.string   "full_name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "users", ["authentication_token"], name: "index_users_on_authentication_token", unique: true, using: :btree
  add_index "users", ["email"], name: "index_users_on_email", unique: true, using: :btree
  add_index "users", ["login"], name: "index_users_on_login", unique: true, using: :btree

  add_foreign_key "appliance_sets", "users", :name => "appliance_sets_user_id_fk"

  add_foreign_key "appliance_types", "users", :name => "appliance_types_user_id_fk"

end
