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
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 2008122700000000) do

  create_table "architectures", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "articles", :force => true do |t|
    t.datetime "created_at",                   :null => false
    t.integer  "url_tid"
    t.integer  "name_tid"
    t.integer  "description_tid"
    t.string   "language_code",   :limit => 3
  end

  create_table "base_packages", :force => true do |t|
    t.string   "type"
    t.string   "name"
    t.string   "section",            :default => "unknown"
    t.text     "description"
    t.integer  "category_id"
    t.integer  "license_type"
    t.integer  "user_id"
    t.integer  "published",          :default => 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "urls"
    t.string   "fullsection"
    t.string   "icon_file"
    t.boolean  "is_program"
    t.integer  "popcon"
    t.boolean  "default_install"
    t.integer  "security_type"
    t.string   "version"
    t.string   "debianized_version"
    t.boolean  "modified",           :default => false
    t.boolean  "debianizing",        :default => false
    t.boolean  "deb_error",          :default => false
    t.integer  "ratings_count"
    t.integer  "description_tid"
    t.integer  "url_tid"
    t.integer  "name_tid"
    t.integer  "section_id"
    t.integer  "p_vote"
    t.integer  "p_old"
    t.integer  "p_recent"
    t.integer  "p_nofiles"
    t.boolean  "tested",             :default => false
    t.text     "conflict_msg"
    t.integer  "priority"
    t.boolean  "best_of",            :default => false
  end

  add_index "base_packages", ["category_id", "type"], :name => "category_id"
  add_index "base_packages", ["name"], :name => "index_base_packages_on_name"
  add_index "base_packages", ["type", "published"], :name => "type_published"
  add_index "base_packages", ["user_id", "type"], :name => "user_id"

  create_table "bdrb_job_queues", :force => true do |t|
    t.text     "args"
    t.string   "worker_name"
    t.string   "worker_method"
    t.string   "job_key"
    t.integer  "taken"
    t.integer  "finished"
    t.integer  "timeout"
    t.integer  "priority"
    t.datetime "submitted_at"
    t.datetime "started_at"
    t.datetime "finished_at"
    t.datetime "archived_at"
    t.string   "tag"
    t.string   "submitter_info"
    t.string   "runner_info"
    t.string   "worker_key"
    t.datetime "scheduled_at"
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
    t.integer  "metapackage_id"
  end

  create_table "categories", :force => true do |t|
    t.string   "name"
    t.string   "description"
    t.integer  "parent_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "link"
    t.integer  "name_tid"
    t.integer  "description_tid"
    t.integer  "link_tid"
    t.boolean  "main",            :default => false
  end

  create_table "comments", :force => true do |t|
    t.integer  "user_id"
    t.integer  "metapackage_id", :default => 0
    t.text     "comment"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "comment_tid"
  end

  add_index "comments", ["metapackage_id"], :name => "metapackage_id"

  create_table "conflicts", :force => true do |t|
    t.integer  "package_id"
    t.integer  "package2_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "debs", :force => true do |t|
    t.integer  "metapackage_id"
    t.integer  "distribution_id"
    t.integer  "derivative_id"
    t.integer  "license_type"
    t.integer  "security_type"
    t.string   "version"
    t.string   "url"
    t.boolean  "generated"
    t.boolean  "outdated"
    t.string   "errmsg"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "log"
  end

  add_index "debs", ["metapackage_id", "distribution_id", "derivative_id"], :name => "debs_index"

  create_table "dependencies", :force => true do |t|
    t.integer  "package_distr_id"
    t.integer  "base_package_id"
    t.integer  "dep_type"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "dependencies", ["package_distr_id", "base_package_id"], :name => "package_distr_id"

  create_table "derivatives", :force => true do |t|
    t.string   "name"
    t.string   "icon_file"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "sudo"
    t.string   "dialog"
  end

  create_table "distribution_derivatives", :force => true do |t|
    t.integer  "distribution_id"
    t.integer  "derivative_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "distributions", :force => true do |t|
    t.string   "name"
    t.text     "description"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "short_name"
    t.string   "url"
    t.integer  "description_tid"
    t.integer  "url_tid"
    t.boolean  "preliminary",     :default => true
    t.integer  "distribution_id"
    t.boolean  "invisible",       :default => true
  end

  create_table "folders", :force => true do |t|
    t.integer  "user_id"
    t.integer  "parent_id"
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "infos", :force => true do |t|
    t.integer  "author_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "header_tid"
    t.integer  "content_tid"
  end

  create_table "languages", :force => true do |t|
    t.string   "name"
    t.string   "country_code"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "livecd_users", :force => true do |t|
    t.integer  "livecd_id"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "locale"
  end

  create_table "livecds", :force => true do |t|
    t.string   "name"
    t.integer  "distribution_id"
    t.integer  "derivative_id"
    t.integer  "architecture_id"
    t.integer  "metapackage_id"
    t.integer  "size"
    t.string   "srcdeb"
    t.string   "installdeb"
    t.integer  "pid"
    t.boolean  "generated",                           :default => false
    t.boolean  "generating",                          :default => false
    t.boolean  "failed",                              :default => false
    t.text     "log",             :limit => 16777215
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "first_try",                           :default => true
    t.integer  "license_type"
    t.integer  "security_type"
    t.integer  "profile_version"
    t.boolean  "iso",                                 :default => false
    t.boolean  "kvm",                                 :default => false
    t.boolean  "usb",                                 :default => false
    t.integer  "vm_pid"
    t.string   "vm_hda"
    t.integer  "downloaded",                          :default => 0
    t.boolean  "published",                           :default => false
    t.text     "conflict_msg"
    t.integer  "port"
    t.string   "short_log"
  end

  create_table "message_copies", :force => true do |t|
    t.integer  "recipient_id"
    t.integer  "message_id"
    t.integer  "folder_id"
    t.boolean  "is_read",      :default => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "messages", :force => true do |t|
    t.integer  "author_id"
    t.string   "subject"
    t.text     "body"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "metacontents", :force => true do |t|
    t.integer  "metapackage_id"
    t.integer  "base_package_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "metacontents", ["metapackage_id", "base_package_id"], :name => "metacontents_1"

  create_table "metacontents_derivatives", :force => true do |t|
    t.integer  "metacontent_id"
    t.integer  "derivative_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "metacontents_derivatives", ["metacontent_id", "derivative_id"], :name => "metacontents_derivatives_1"

  create_table "metacontents_distrs", :force => true do |t|
    t.integer  "metacontent_id"
    t.integer  "distribution_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "package_distrs", :force => true do |t|
    t.integer  "package_id"
    t.integer  "distribution_id"
    t.integer  "repository_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "version"
    t.string   "filename"
    t.integer  "size"
    t.integer  "installedsize"
    t.boolean  "outdated",        :default => false
  end

  add_index "package_distrs", ["package_id"], :name => "package_id"
  add_index "package_distrs", ["repository_id"], :name => "repository_id"

  create_table "package_distrs_architectures", :force => true do |t|
    t.integer  "package_distr_id"
    t.integer  "architecture_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "outdated",         :default => false
  end

  add_index "package_distrs_architectures", ["package_distr_id", "architecture_id"], :name => "package_distr_id"

  create_table "package_tags", :force => true do |t|
    t.integer "package_id"
    t.integer "tag_id"
  end

  create_table "permissions", :force => true do |t|
    t.integer  "role_id",    :null => false
    t.integer  "user_id",    :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "rates", :force => true do |t|
    t.integer "score"
  end

  create_table "ratings", :force => true do |t|
    t.integer  "rating",                      :default => 0
    t.datetime "created_at",                                  :null => false
    t.string   "rateable_type", :limit => 15, :default => "", :null => false
    t.integer  "rateable_id",                 :default => 0,  :null => false
    t.integer  "user_id",                     :default => 0,  :null => false
    t.text     "comment"
    t.integer  "comment_tid"
    t.text     "free_text"
    t.integer  "rate_id"
    t.string   "rater_name"
  end

  add_index "ratings", ["rate_id"], :name => "index_ratings_on_rate_id"
  add_index "ratings", ["rateable_id", "rateable_type"], :name => "index_ratings_on_rateable_id_and_rateable_type"
  add_index "ratings", ["rateable_id", "rateable_type"], :name => "rateable_id"
  add_index "ratings", ["user_id"], :name => "fk_ratings_user"

  create_table "repositories", :force => true do |t|
    t.integer  "distribution_id"
    t.integer  "security_type"
    t.integer  "license_type"
    t.string   "url"
    t.string   "subtype"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "gpgkey"
    t.text     "package_file"
    t.integer  "gpgkey_tid"
    t.integer  "url_tid"
  end

  create_table "repositories_architectures", :force => true do |t|
    t.integer  "repository_id"
    t.integer  "architecture_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "repository_dependencies", :force => true do |t|
    t.integer  "repository_id"
    t.integer  "depends_on_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "roles", :force => true do |t|
    t.string   "rolename"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "sections", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "name_tid"
  end

  create_table "standard_packages", :force => true do |t|
    t.integer  "package_id"
    t.integer  "distribution_id"
    t.integer  "derivative_id"
    t.integer  "architecture_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "tags", :force => true do |t|
    t.string   "name"
    t.boolean  "is_facet"
    t.string   "status"
    t.string   "nature"
    t.text     "description"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "translations", :force => true do |t|
    t.text     "contents"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "translatable_id"
    t.string   "language_code"
  end

  add_index "translations", ["translatable_id", "language_code"], :name => "translatable_id", :unique => true

  create_table "user_packages", :force => true do |t|
    t.integer  "user_id"
    t.integer  "package_id"
    t.boolean  "is_selected"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "user_packages", ["id"], :name => "id"
  add_index "user_packages", ["user_id", "package_id", "is_selected"], :name => "user_id_package_id_selected"

  create_table "user_profiles", :force => true do |t|
    t.integer  "user_id"
    t.integer  "category_id"
    t.integer  "rating"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "userlogs", :force => true do |t|
    t.integer  "user_id"
    t.datetime "created_at",                                :null => false
    t.string   "refferer",   :limit => 240, :default => ""
  end

  add_index "userlogs", ["user_id", "created_at"], :name => "user_id_date"

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
    t.integer  "license",                                 :default => 1
    t.integer  "security",                                :default => 2
    t.integer  "distribution_id",                         :default => 2
    t.integer  "language_id",                             :default => 1
    t.integer  "first_login",                             :default => 1
    t.integer  "template_id"
    t.integer  "derivative_id"
    t.integer  "profile_version"
    t.boolean  "profile_changed",                         :default => false
    t.boolean  "anonymous",                               :default => false
    t.string   "surname",                   :limit => 30, :default => ""
    t.string   "firstname",                 :limit => 30, :default => ""
    t.integer  "architecture_id",                         :default => 1
    t.boolean  "advanced",                                :default => false
  end

  create_table "videos", :force => true do |t|
    t.integer  "base_package_id"
    t.string   "url"
    t.text     "description"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "description_tid"
    t.integer  "url_tid"
  end

end
