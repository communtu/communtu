# This file is auto-generated from the current state of the database. Instead of editing this file, 
# please use the migrations feature of ActiveRecord to incrementally modify your database, and
# then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your database schema. If you need
# to create the application database on another system, you should be using db:schema:load, not running
# all the migrations from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 21) do

  create_table "base_packages", :force => true do |t|
    t.string   "type"
    t.integer  "distribution_id"
    t.integer  "repository_id"
    t.string   "name"
    t.string   "section",         :default => "unknown"
    t.string   "version"
    t.text     "description"
    t.integer  "category_id"
    t.integer  "rating"
    t.integer  "license_type"
    t.integer  "user_id"
    t.integer  "published",       :default => 0
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "cart_contents", :force => true do |t|
    t.integer  "cart_id"
    t.integer  "base_package_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "carts", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "categories", :force => true do |t|
    t.string   "name"
    t.string   "description"
    t.integer  "parent_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "comments", :force => true do |t|
    t.integer  "user_id"
    t.integer  "metapackage_id",      :default => 0
    t.integer  "temp_metapackage_id", :default => 0
    t.text     "comment"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "distributions", :force => true do |t|
    t.string   "name"
    t.text     "description"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "languages", :force => true do |t|
    t.string   "name"
    t.string   "country_code"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "metacontents", :force => true do |t|
    t.integer  "metapackage_id"
    t.integer  "base_package_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "permissions", :force => true do |t|
    t.integer  "role_id",    :null => false
    t.integer  "user_id",    :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "repositories", :force => true do |t|
    t.integer  "distribution_id"
    t.integer  "security_type"
    t.integer  "license_type"
    t.text     "type"
    t.string   "url"
    t.string   "subtype"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "roles", :force => true do |t|
    t.string   "rolename"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "temp_metacontents", :force => true do |t|
    t.integer  "temp_metapackage_id"
    t.integer  "package_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "temp_metapackages", :force => true do |t|
    t.string   "name"
    t.text     "description"
    t.integer  "distribution_id"
    t.integer  "user_id"
    t.integer  "rating"
    t.integer  "license_type"
    t.integer  "is_saved",        :default => 0
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "translations", :force => true do |t|
    t.integer  "language_id"
    t.string   "tag"
    t.text     "contents"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "user_profiles", :force => true do |t|
    t.integer  "user_id"
    t.integer  "category_id"
    t.integer  "rating"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "users", :force => true do |t|
    t.string   "login"
    t.string   "email"
    t.string   "crypted_password",          :limit => 40
    t.string   "salt",                      :limit => 40
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "remember_token"
    t.datetime "remember_token_expires_at"
    t.string   "activation_code",           :limit => 40
    t.datetime "activated_at"
    t.string   "password_reset_code",       :limit => 40
    t.boolean  "enabled",                                 :default => true
    t.integer  "license",                                 :default => 0
    t.integer  "security",                                :default => 0
    t.integer  "distribution_id"
    t.integer  "language_id",                             :default => 1
    t.integer  "first_login",                             :default => 1
  end

end
