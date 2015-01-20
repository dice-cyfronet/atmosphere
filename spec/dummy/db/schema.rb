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

ActiveRecord::Schema.define(version: 20150113100404) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "atmosphere_appliance_compute_sites", force: true do |t|
    t.integer "appliance_id"
    t.integer "compute_site_id"
  end

  create_table "atmosphere_appliance_configuration_instances", force: true do |t|
    t.text     "payload"
    t.integer  "appliance_configuration_template_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "atmosphere_appliance_configuration_instances", ["appliance_configuration_template_id"], name: "index_ac_instance_on_ac_template_id", using: :btree

  create_table "atmosphere_appliance_configuration_templates", force: true do |t|
    t.string   "name",              null: false
    t.text     "payload"
    t.integer  "appliance_type_id", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "atmosphere_appliance_configuration_templates", ["appliance_type_id"], name: "atmo_act_appliance_type_id_ix", using: :btree

  create_table "atmosphere_appliance_sets", force: true do |t|
    t.string   "name"
    t.integer  "priority",            default: 50,         null: false
    t.string   "appliance_set_type",  default: "workflow", null: false
    t.integer  "user_id",                                  null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "optimization_policy"
  end

  add_index "atmosphere_appliance_sets", ["user_id"], name: "index_atmosphere_appliance_sets_on_user_id", using: :btree

  create_table "atmosphere_appliance_types", force: true do |t|
    t.string   "name",                                        null: false
    t.text     "description"
    t.boolean  "shared",                    default: false,   null: false
    t.boolean  "scalable",                  default: false,   null: false
    t.string   "visible_to",                default: "owner", null: false
    t.float    "preference_cpu"
    t.integer  "preference_memory"
    t.integer  "preference_disk"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "atmosphere_os_families_id"
  end

  add_index "atmosphere_appliance_types", ["atmosphere_os_families_id"], name: "index_atmosphere_appliance_types_on_atmosphere_os_families_id", using: :btree
  add_index "atmosphere_appliance_types", ["name"], name: "index_atmosphere_appliance_types_on_name", unique: true, using: :btree

  create_table "atmosphere_appliances", force: true do |t|
    t.integer  "appliance_set_id",                                    null: false
    t.integer  "appliance_type_id",                                   null: false
    t.integer  "user_key_id"
    t.integer  "appliance_configuration_instance_id",                 null: false
    t.string   "state",                               default: "new", null: false
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "fund_id"
    t.datetime "last_billing"
    t.string   "state_explanation"
    t.integer  "amount_billed",                       default: 0,     null: false
    t.text     "description"
    t.string   "optimization_policy"
    t.text     "optimization_policy_params"
  end

  create_table "atmosphere_billing_logs", force: true do |t|
    t.datetime "timestamp",                                        null: false
    t.string   "appliance",     default: "unknown appliance",      null: false
    t.string   "fund",          default: "unknown fund",           null: false
    t.string   "actor",         default: "unknown billing actor",  null: false
    t.string   "message",       default: "appliance prolongation", null: false
    t.string   "currency",      default: "EUR",                    null: false
    t.integer  "amount_billed", default: 0,                        null: false
    t.integer  "user_id"
  end

  create_table "atmosphere_compute_site_funds", force: true do |t|
    t.integer "compute_site_id"
    t.integer "fund_id"
  end

  create_table "atmosphere_compute_sites", force: true do |t|
    t.string   "site_id",                               null: false
    t.string   "name"
    t.string   "location"
    t.string   "site_type",         default: "private"
    t.string   "technology"
    t.string   "http_proxy_url"
    t.string   "https_proxy_url"
    t.text     "config"
    t.text     "template_filters"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "wrangler_url"
    t.string   "wrangler_username"
    t.string   "wrangler_password"
    t.boolean  "active",            default: true
  end

  create_table "atmosphere_deployments", force: true do |t|
    t.integer  "virtual_machine_id"
    t.integer  "appliance_id"
    t.string   "billing_state",      default: "prepaid", null: false
    t.datetime "prepaid_until",      default: "now()",   null: false
  end

  create_table "atmosphere_dev_mode_property_sets", force: true do |t|
    t.string   "name",                              null: false
    t.text     "description"
    t.boolean  "shared",            default: false, null: false
    t.boolean  "scalable",          default: false, null: false
    t.float    "preference_cpu"
    t.integer  "preference_memory"
    t.integer  "preference_disk"
    t.integer  "appliance_id",                      null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "atmosphere_endpoints", force: true do |t|
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

  create_table "atmosphere_funds", force: true do |t|
    t.string  "name",               default: "unnamed fund", null: false
    t.integer "balance",            default: 0,              null: false
    t.string  "currency_label",     default: "EUR",          null: false
    t.integer "overdraft_limit",    default: 0,              null: false
    t.string  "termination_policy", default: "suspend",      null: false
  end

  create_table "atmosphere_http_mappings", force: true do |t|
    t.string   "application_protocol",     default: "http",    null: false
    t.string   "url",                      default: "",        null: false
    t.integer  "appliance_id"
    t.integer  "port_mapping_template_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "compute_site_id",                              null: false
    t.string   "monitoring_status",        default: "pending"
    t.string   "custom_name"
    t.string   "base_url",                                     null: false
  end

  create_table "atmosphere_os_families", force: true do |t|
    t.string "os_family_name", default: "Windows", null: false
  end

  create_table "atmosphere_port_mapping_properties", force: true do |t|
    t.string   "key",                      null: false
    t.string   "value",                    null: false
    t.integer  "port_mapping_template_id"
    t.integer  "compute_site_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "atmosphere_port_mapping_templates", force: true do |t|
    t.string   "transport_protocol",       default: "tcp",        null: false
    t.string   "application_protocol",     default: "http_https", null: false
    t.string   "service_name",                                    null: false
    t.integer  "target_port",                                     null: false
    t.integer  "appliance_type_id"
    t.integer  "dev_mode_property_set_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "atmosphere_port_mappings", force: true do |t|
    t.string   "public_ip",                null: false
    t.integer  "source_port",              null: false
    t.integer  "port_mapping_template_id", null: false
    t.integer  "virtual_machine_id",       null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "atmosphere_user_funds", force: true do |t|
    t.integer "user_id"
    t.integer "fund_id"
    t.boolean "default", default: false
  end

  create_table "atmosphere_user_keys", force: true do |t|
    t.string   "name",        null: false
    t.string   "fingerprint", null: false
    t.text     "public_key",  null: false
    t.integer  "user_id",     null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "atmosphere_user_keys", ["user_id", "name"], name: "index_atmosphere_user_keys_on_user_id_and_name", unique: true, using: :btree

  create_table "atmosphere_users", force: true do |t|
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
    t.string   "email",                  default: "", null: false
    t.string   "full_name"
    t.integer  "roles_mask"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "authentication_token"
  end

  add_index "atmosphere_users", ["authentication_token"], name: "index_atmosphere_users_on_authentication_token", unique: true, using: :btree
  add_index "atmosphere_users", ["email"], name: "index_atmosphere_users_on_email", unique: true, using: :btree
  add_index "atmosphere_users", ["login"], name: "index_atmosphere_users_on_login", unique: true, using: :btree

  create_table "atmosphere_virtual_machine_flavor_os_families", force: true do |t|
    t.integer "hourly_cost"
    t.integer "virtual_machine_flavor_id"
    t.integer "os_family_id"
  end

  create_table "atmosphere_virtual_machine_flavors", force: true do |t|
    t.string  "flavor_name",                                null: false
    t.float   "cpu"
    t.float   "memory"
    t.float   "hdd"
    t.integer "hourly_cost",                                null: false
    t.integer "compute_site_id"
    t.string  "id_at_site"
    t.string  "supported_architectures", default: "x86_64"
    t.boolean "active",                  default: true
  end

  create_table "atmosphere_virtual_machine_templates", force: true do |t|
    t.string   "id_at_site",                               null: false
    t.string   "name",                                     null: false
    t.string   "state",                                    null: false
    t.boolean  "managed_by_atmosphere", default: false,    null: false
    t.integer  "compute_site_id",                          null: false
    t.integer  "virtual_machine_id"
    t.integer  "appliance_type_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "architecture",          default: "x86_64"
    t.integer  "version"
  end

  add_index "atmosphere_virtual_machine_templates", ["compute_site_id", "id_at_site"], name: "atmo_vm_tmpls_on_cs_id_and_id_at_site_ix", unique: true, using: :btree

  create_table "atmosphere_virtual_machines", force: true do |t|
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
    t.integer  "monitoring_id"
    t.datetime "updated_at_site"
  end

  add_index "atmosphere_virtual_machines", ["compute_site_id", "id_at_site"], name: "atmo_vm_cs_id_id_at_site_ix", unique: true, using: :btree
  add_index "atmosphere_virtual_machines", ["virtual_machine_template_id"], name: "atmo_vm_vmt_ix", using: :btree

  add_foreign_key "atmosphere_appliance_configuration_instances", "atmosphere_appliance_configuration_templates", name: "ac_instances_ac_template_id_fk", column: "appliance_configuration_template_id"

  add_foreign_key "atmosphere_appliance_configuration_templates", "atmosphere_appliance_types", name: "atmo_config_templates_at_id_fk", column: "appliance_type_id"

  add_foreign_key "atmosphere_appliance_sets", "atmosphere_users", name: "atmosphere_appliance_sets_user_id_fk", column: "user_id"

  add_foreign_key "atmosphere_appliance_types", "atmosphere_users", name: "atmosphere_appliance_types_user_id_fk", column: "user_id"

  add_foreign_key "atmosphere_appliances", "atmosphere_appliance_configuration_instances", name: "atmosphere_appliances_appliance_configuration_instance_id_fk", column: "appliance_configuration_instance_id"
  add_foreign_key "atmosphere_appliances", "atmosphere_appliance_sets", name: "atmosphere_appliances_appliance_set_id_fk", column: "appliance_set_id"
  add_foreign_key "atmosphere_appliances", "atmosphere_appliance_types", name: "atmosphere_appliances_appliance_type_id_fk", column: "appliance_type_id"
  add_foreign_key "atmosphere_appliances", "atmosphere_user_keys", name: "atmosphere_appliances_user_key_id_fk", column: "user_key_id"

  add_foreign_key "atmosphere_dev_mode_property_sets", "atmosphere_appliances", name: "atmosphere_dev_mode_property_sets_appliance_id_fk", column: "appliance_id"

  add_foreign_key "atmosphere_endpoints", "atmosphere_port_mapping_templates", name: "atmosphere_endpoints_port_mapping_template_id_fk", column: "port_mapping_template_id"

  add_foreign_key "atmosphere_http_mappings", "atmosphere_appliances", name: "atmosphere_http_mappings_appliance_id_fk", column: "appliance_id"
  add_foreign_key "atmosphere_http_mappings", "atmosphere_compute_sites", name: "atmosphere_http_mappings_compute_site_id_fk", column: "compute_site_id"
  add_foreign_key "atmosphere_http_mappings", "atmosphere_port_mapping_templates", name: "atmosphere_http_mappings_port_mapping_template_id_fk", column: "port_mapping_template_id"

  add_foreign_key "atmosphere_port_mapping_properties", "atmosphere_compute_sites", name: "atmosphere_port_mapping_properties_compute_site_id_fk", column: "compute_site_id"
  add_foreign_key "atmosphere_port_mapping_properties", "atmosphere_port_mapping_templates", name: "atmosphere_port_mapping_properties_port_mapping_template_id_fk", column: "port_mapping_template_id"

  add_foreign_key "atmosphere_port_mapping_templates", "atmosphere_appliance_types", name: "atmosphere_port_mapping_templates_appliance_type_id_fk", column: "appliance_type_id"
  add_foreign_key "atmosphere_port_mapping_templates", "atmosphere_dev_mode_property_sets", name: "atmosphere_port_mapping_templates_dev_mode_property_set_id_fk", column: "dev_mode_property_set_id"

  add_foreign_key "atmosphere_port_mappings", "atmosphere_port_mapping_templates", name: "atmosphere_port_mappings_port_mapping_template_id_fk", column: "port_mapping_template_id"
  add_foreign_key "atmosphere_port_mappings", "atmosphere_virtual_machines", name: "atmosphere_port_mappings_virtual_machine_id_fk", column: "virtual_machine_id"

  add_foreign_key "atmosphere_user_keys", "atmosphere_users", name: "atmosphere_user_keys_user_id_fk", column: "user_id"

  add_foreign_key "atmosphere_virtual_machine_flavors", "atmosphere_compute_sites", name: "atmosphere_virtual_machine_flavors_compute_site_id_fk", column: "compute_site_id"

  add_foreign_key "atmosphere_virtual_machine_templates", "atmosphere_appliance_types", name: "atmosphere_virtual_machine_templates_appliance_type_id_fk", column: "appliance_type_id", dependent: :nullify
  add_foreign_key "atmosphere_virtual_machine_templates", "atmosphere_compute_sites", name: "atmo_vmt_cs_fk", column: "compute_site_id"
  add_foreign_key "atmosphere_virtual_machine_templates", "atmosphere_virtual_machines", name: "atmo_vmt_vm_fk", column: "virtual_machine_id"

  add_foreign_key "atmosphere_virtual_machines", "atmosphere_compute_sites", name: "atmo_vm_cs_fk", column: "compute_site_id"
  add_foreign_key "atmosphere_virtual_machines", "atmosphere_virtual_machine_templates", name: "atmo_vm_vmt_fk", column: "virtual_machine_template_id"

end
