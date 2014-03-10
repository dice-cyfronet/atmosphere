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

ActiveRecord::Schema.define(version: 20140310130146) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "appliance_configuration_instances", force: true do |t|
    t.text     "payload"
    t.integer  "appliance_configuration_template_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "appliance_configuration_instances", ["appliance_configuration_template_id"], name: "index_ac_instance_on_ac_template_id", using: :btree

  create_table "appliance_configuration_templates", force: true do |t|
    t.string   "name",              null: false
    t.text     "payload"
    t.integer  "appliance_type_id", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "appliance_configuration_templates", ["appliance_type_id"], name: "index_appliance_configuration_templates_on_appliance_type_id", using: :btree

  create_table "appliance_sets", force: true do |t|
    t.string   "name"
    t.integer  "priority",           default: 50,         null: false
    t.string   "appliance_set_type", default: "workflow", null: false
    t.integer  "user_id",                                 null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "appliance_sets", ["user_id"], name: "index_appliance_sets_on_user_id", using: :btree

  create_table "appliance_types", force: true do |t|
    t.string   "name",                                 null: false
    t.text     "description"
    t.boolean  "shared",             default: false,   null: false
    t.boolean  "scalable",           default: false,   null: false
    t.string   "visible_to",         default: "owner", null: false
    t.float    "preference_cpu"
    t.integer  "preference_memory"
    t.integer  "preference_disk"
    t.integer  "security_proxy_id"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "metadata_global_id"
  end

  add_index "appliance_types", ["name"], name: "index_appliance_types_on_name", unique: true, using: :btree

  create_table "appliances", force: true do |t|
    t.integer  "appliance_set_id",                                        null: false
    t.integer  "appliance_type_id",                                       null: false
    t.integer  "user_key_id"
    t.integer  "appliance_configuration_instance_id",                     null: false
    t.string   "state",                               default: "new",     null: false
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "fund_id"
    t.datetime "last_billing"
    t.string   "state_explanation"
    t.integer  "amount_billed",                       default: 0,         null: false
    t.string   "billing_state",                       default: "prepaid", null: false
    t.datetime "prepaid_until",                       default: "now()",   null: false
  end

  create_table "billing_logs", force: true do |t|
    t.datetime "timestamp",                                        null: false
    t.string   "appliance",     default: "unknown appliance",      null: false
    t.string   "fund",          default: "unknown fund",           null: false
    t.string   "actor",         default: "unknown billing actor",  null: false
    t.string   "message",       default: "appliance prolongation", null: false
    t.string   "currency",      default: "EUR",                    null: false
    t.integer  "amount_billed", default: 0,                        null: false
    t.integer  "user_id"
  end

  create_table "compute_sites", force: true do |t|
    t.string   "site_id",                                   null: false
    t.string   "name"
    t.string   "location"
    t.string   "site_type",             default: "private"
    t.string   "technology"
    t.boolean  "regenerate_proxy_conf", default: false
    t.string   "http_proxy_url"
    t.string   "https_proxy_url"
    t.text     "config"
    t.text     "template_filters"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "wrangler_url"
    t.string   "wrangler_username"
    t.string   "wrangler_password"
  end

  create_table "deployments", force: true do |t|
    t.integer "virtual_machine_id"
    t.integer "appliance_id"
  end

  create_table "dev_mode_property_sets", force: true do |t|
    t.string   "name",                              null: false
    t.text     "description"
    t.boolean  "shared",            default: false, null: false
    t.boolean  "scalable",          default: false, null: false
    t.float    "preference_cpu"
    t.integer  "preference_memory"
    t.integer  "preference_disk"
    t.integer  "appliance_id",                      null: false
    t.integer  "security_proxy_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "endpoints", force: true do |t|
    t.string   "name",                                     null: false
    t.text     "description"
    t.text     "descriptor"
    t.string   "endpoint_type",            default: "ws",  null: false
    t.string   "invocation_path",                          null: false
    t.integer  "port_mapping_template_id",                 null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "secured",                  default: false, null: false
  end

  create_table "funds", force: true do |t|
    t.string  "name",               default: "unnamed fund", null: false
    t.integer "balance",            default: 0,              null: false
    t.string  "currency_label",     default: "EUR",          null: false
    t.integer "overdraft_limit",    default: 0,              null: false
    t.string  "termination_policy", default: "suspend",      null: false
  end

  create_table "http_mappings", force: true do |t|
    t.string   "application_protocol",     default: "http", null: false
    t.string   "url",                      default: "",     null: false
    t.integer  "appliance_id"
    t.integer  "port_mapping_template_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "port_mapping_properties", force: true do |t|
    t.string   "key",                      null: false
    t.string   "value",                    null: false
    t.integer  "port_mapping_template_id"
    t.integer  "compute_site_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "port_mapping_templates", force: true do |t|
    t.string   "transport_protocol",       default: "tcp",        null: false
    t.string   "application_protocol",     default: "http_https", null: false
    t.string   "service_name",                                    null: false
    t.integer  "target_port",                                     null: false
    t.integer  "appliance_type_id"
    t.integer  "dev_mode_property_set_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "port_mappings", force: true do |t|
    t.string   "public_ip",                null: false
    t.integer  "source_port",              null: false
    t.integer  "port_mapping_template_id", null: false
    t.integer  "virtual_machine_id",       null: false
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

  create_table "user_funds", force: true do |t|
    t.integer "user_id"
    t.integer "fund_id"
    t.boolean "default", default: false
  end

  create_table "user_keys", force: true do |t|
    t.string   "name",        null: false
    t.string   "fingerprint", null: false
    t.text     "public_key",  null: false
    t.integer  "user_id",     null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "user_keys", ["user_id", "name"], name: "index_user_keys_on_user_id_and_name", unique: true, using: :btree

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
    t.integer  "roles_mask"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "users", ["authentication_token"], name: "index_users_on_authentication_token", unique: true, using: :btree
  add_index "users", ["email"], name: "index_users_on_email", unique: true, using: :btree
  add_index "users", ["login"], name: "index_users_on_login", unique: true, using: :btree

  create_table "virtual_machine_flavors", force: true do |t|
    t.string  "flavor_name",     null: false
    t.float   "cpu"
    t.float   "memory"
    t.float   "hdd"
    t.integer "hourly_cost",     null: false
    t.integer "compute_site_id"
    t.string  "id_at_site"
  end

  create_table "virtual_machine_templates", force: true do |t|
    t.string   "id_at_site",                            null: false
    t.string   "name",                                  null: false
    t.string   "state",                                 null: false
    t.boolean  "managed_by_atmosphere", default: false, null: false
    t.integer  "compute_site_id",                       null: false
    t.integer  "virtual_machine_id"
    t.integer  "appliance_type_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "virtual_machine_templates", ["compute_site_id", "id_at_site"], name: "index_vm_tmpls_on_cs_id_and_id_at_site", unique: true, using: :btree

  create_table "virtual_machines", force: true do |t|
    t.string   "id_at_site",                                  null: false
    t.string   "name",                                        null: false
    t.string   "state",                                       null: false
    t.string   "ip"
    t.boolean  "managed_by_atmosphere",       default: false, null: false
    t.integer  "compute_site_id",                             null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "virtual_machine_template_id"
    t.integer  "virtual_machine_flavor_id"
  end

  add_index "virtual_machines", ["compute_site_id", "id_at_site"], name: "index_virtual_machines_on_compute_site_id_and_id_at_site", unique: true, using: :btree
  add_index "virtual_machines", ["virtual_machine_template_id"], name: "index_virtual_machines_on_virtual_machine_template_id", using: :btree

  add_foreign_key "appliance_configuration_instances", "appliance_configuration_templates", name: "ac_instances_ac_template_id_fk"

  add_foreign_key "appliance_configuration_templates", "appliance_types", name: "appliance_configuration_templates_appliance_type_id_fk"

  add_foreign_key "appliance_sets", "users", name: "appliance_sets_user_id_fk"

  add_foreign_key "appliance_types", "security_proxies", name: "appliance_types_security_proxy_id_fk"
  add_foreign_key "appliance_types", "users", name: "appliance_types_user_id_fk"

  add_foreign_key "appliances", "appliance_configuration_instances", name: "appliances_appliance_configuration_instance_id_fk"
  add_foreign_key "appliances", "appliance_sets", name: "appliances_appliance_set_id_fk"
  add_foreign_key "appliances", "appliance_types", name: "appliances_appliance_type_id_fk"
  add_foreign_key "appliances", "user_keys", name: "appliances_user_key_id_fk"

  add_foreign_key "dev_mode_property_sets", "appliances", name: "dev_mode_property_sets_appliance_id_fk"
  add_foreign_key "dev_mode_property_sets", "security_proxies", name: "dev_mode_property_sets_security_proxy_id_fk"

  add_foreign_key "endpoints", "port_mapping_templates", name: "endpoints_port_mapping_template_id_fk"

  add_foreign_key "http_mappings", "appliances", name: "http_mappings_appliance_id_fk"
  add_foreign_key "http_mappings", "port_mapping_templates", name: "http_mappings_port_mapping_template_id_fk"

  add_foreign_key "port_mapping_properties", "compute_sites", name: "port_mapping_properties_compute_site_id_fk"
  add_foreign_key "port_mapping_properties", "port_mapping_templates", name: "port_mapping_properties_port_mapping_template_id_fk"

  add_foreign_key "port_mapping_templates", "appliance_types", name: "port_mapping_templates_appliance_type_id_fk"
  add_foreign_key "port_mapping_templates", "dev_mode_property_sets", name: "port_mapping_templates_dev_mode_property_set_id_fk"

  add_foreign_key "port_mappings", "port_mapping_templates", name: "port_mappings_port_mapping_template_id_fk"
  add_foreign_key "port_mappings", "virtual_machines", name: "port_mappings_virtual_machine_id_fk"

  add_foreign_key "user_keys", "users", name: "user_keys_user_id_fk"

  add_foreign_key "virtual_machine_flavors", "compute_sites", name: "virtual_machine_flavors_compute_site_id_fk"

  add_foreign_key "virtual_machine_templates", "appliance_types", name: "virtual_machine_templates_appliance_type_id_fk", dependent: :nullify
  add_foreign_key "virtual_machine_templates", "compute_sites", name: "virtual_machine_templates_compute_site_id_fk"
  add_foreign_key "virtual_machine_templates", "virtual_machines", name: "virtual_machine_templates_virtual_machine_id_fk"

  add_foreign_key "virtual_machines", "compute_sites", name: "virtual_machines_compute_site_id_fk"
  add_foreign_key "virtual_machines", "virtual_machine_templates", name: "virtual_machines_virtual_machine_template_id_fk"

end
