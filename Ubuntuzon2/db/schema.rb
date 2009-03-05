# This file is auto-generated from the current state of the database. Instead of editing this file, 
# please use the migrations feature of Active Record to incrementally modify your database, and
# then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your database schema. If you need
# to create the application database on another system, you should be using db:schema:load, not running
# all the migrations from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20090224162458) do

  create_table "accounts", :force => true do |t|
    t.string   "login"
    t.string   "email"
    t.string   "crypted_password",          :limit => 40
    t.string   "salt",                      :limit => 40
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "remember_token"
    t.datetime "remember_token_expires_at"
    t.string   "firstname"
    t.string   "lastname"
    t.integer  "gender",                    :limit => 11
    t.integer  "newsletter",                :limit => 11
  end

  create_table "comments", :force => true do |t|
    t.integer  "package_id", :limit => 11
    t.text     "body"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "account_id", :limit => 11
  end

  create_table "config_changes", :force => true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "configurations", :force => true do |t|
    t.integer  "account_id", :limit => 11
    t.integer  "package_id", :limit => 11
    t.float    "rating"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "upload_id",  :limit => 11
  end

  create_table "packages", :force => true do |t|
    t.string   "name"
    t.string   "description"
    t.string   "version"
    t.integer  "standard",    :limit => 11
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "ratings", :force => true do |t|
    t.integer  "rating",        :limit => 11, :default => 0
    t.datetime "created_at",                                  :null => false
    t.string   "rateable_type", :limit => 15, :default => "", :null => false
    t.integer  "rateable_id",   :limit => 11, :default => 0,  :null => false
    t.integer  "user_id",       :limit => 11, :default => 0,  :null => false
  end

  add_index "ratings", ["user_id"], :name => "fk_ratings_user"

  create_table "uploads", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "account_id", :limit => 11
  end

  create_table "whitelists", :force => true do |t|
    t.string   "package"
    t.integer  "standard",   :limit => 11
    t.integer  "rating",     :limit => 11
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end
