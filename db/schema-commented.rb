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

ActiveRecord::Schema.define(:version => 2008122700000000) do

#################### packages and bundles ############################

# Ubuntu packages and Communtu bundles (the latter are called "metapackages", this should be changed to "bundles")
# A special feature of base_packages is that they are distribution independent,
# and therefore more general as Ubuntu/Debian (meta)packages
  create_table "base_packages", :force => true do |t|
    # Ubuntu package or Communtu bundle?
    t.string   "type"
    t.string   "name"
    # abbreviated debian section of the package (empty for bundles)
    # the abbreviation makes section names more user-friendly
    t.string   "section",                          :default => "unknown"
    # description inherited from Ubuntu
    t.text     "description"
    # category of the bundle
    t.integer  "category_id",        :limit => 11
    # only for bundles. 0 = free, 1 = free and non-free
    t.integer  "license_type",       :limit => 11
    # maintainer of the bundle
    t.integer  "user_id",            :limit => 11
    # is the bundle published?
    t.integer  "published",          :limit => 11, :default => 0
    t.datetime "created_at"
    t.datetime "updated_at"
    # Useful links for the packages (not used for bundles)
    t.text     "urls"
    # debian section of the package (empty for bundles)
    t.string   "fullsection"
    # filename (relativ to public/images/apps) of icon for package
    # (bundles get a fixed icon)
    t.string   "icon_file"
    # is the package a program, or just a library?
    t.boolean  "is_program"
    # popularity from popcon.ubuntu.com
    t.integer  "popcon",             :limit => 11
    # should the bundle be installed by default, if the user selects the category?
    t.boolean  "default_install"
    # 0 = main/restricted, 1 = also universe/multiverse
    t.integer  "security_type",      :limit => 11
    # version of the bundle
    t.string   "version"
    # last version of the bundle that has been turned into a debian metapackage
    t.string   "debianized_version"
  end

# categories, for structuring the realm of bundles
  create_table "categories", :force => true do |t|
    t.string   "name"
    # description is not really used yet!
    t.string   "description"
    # categories form a hierarchy (tree)
    t.integer  "parent_id",   :limit => 11
    t.datetime "created_at"
    t.datetime "updated_at"
  end

# comments for bundles, also used for packages
# just a first hack though
  create_table "comments", :force => true do |t|
    t.integer  "user_id",        :limit => 11
    t.integer  "metapackage_id", :limit => 11, :default => 0
    t.text     "comment"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

# videos illustrating Ubuntu packages (in the future perhaps also bundles?)
  create_table "videos", :force => true do |t|
    t.integer  "base_package_id", :limit => 11
    # location of the video
    t.string   "url"
    t.text     "description"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

################ Structuring packages in repositories, derivatives, distributions #########################

# derivatives, like Ubuntu, Kubuntu, Xubuntu
# in the future, also Debian could be addded
  create_table "derivatives", :force => true do |t|
    t.string   "name"
    # filename of icon, currently not used
    t.string   "icon_file"
    t.datetime "created_at"
    t.datetime "updated_at"
    # graphical sudo command, like gksudo or kdesudo
    t.string   "sudo"
    # graphical dialog command, like zenity of kdialog
    t.string   "dialog"
  end

# distributions, like Hardy, Intreprid, Jaunty, Karmic
  create_table "distributions", :force => true do |t|
    # full name, e.g. "Hardy Heron 8.10"
    t.string   "name"
    # more detailed description (currently not really used)
    t.text     "description"
    t.datetime "created_at"
    t.datetime "updated_at"
    # short name, e.g. "Hardy"
    t.string   "short_name"
    # link to Ubuntu wiki page
    t.string   "url"
  end

# Ubuntu (and third party) repositories providing software packages
  create_table "repositories", :force => true do |t|
    # each repository belongs to a specific distribution
    t.integer  "distribution_id", :limit => 11
    # see under base_packages
    t.integer  "security_type",   :limit => 11
    # see under base_packages
    t.integer  "license_type",    :limit => 11
    # location of the repository
    # this is also used to download infos contained in tables package_distrs and dependencies
    t.string   "url"
    # subtype, e.g. main, universe, multiverse
    t.string   "subtype"
    t.datetime "created_at"
    t.datetime "updated_at"
    # url for download of gpg key, shall be replaced with id of gpg key
    t.string   "gpgkey"
  end

######## relations between bundles, packages, repositories, derivatives, and distributions ###########

# contents of bundles
# each bundle is linked to the packages and bundles it contains
  create_table "metacontents", :force => true do |t|
    # bundle
    t.integer  "metapackage_id",  :limit => 11
    # contained package or bundle
    t.integer  "base_package_id", :limit => 11
    t.datetime "created_at"
    t.datetime "updated_at"
  end

# membership of packages in bundles can be active or inactive for different derivatives
  create_table "metacontents_derivatives", :force => true do |t|
    t.integer  "metacontent_id", :limit => 11
    t.integer  "derivative_id",  :limit => 11
    t.datetime "created_at"
    t.datetime "updated_at"
  end

# membership of packages in bundles can be active or inactive for different distributions
  create_table "metacontents_distrs", :force => true do |t|
    t.integer  "metacontent_id",  :limit => 11
    t.integer  "distribution_id", :limit => 11
    t.datetime "created_at"
    t.datetime "updated_at"
  end

# info about membership of a package in a specific distribution
  create_table "package_distrs", :force => true do |t|
    t.integer  "package_id",      :limit => 11
    t.integer  "distribution_id", :limit => 11
    # repository witnessing membership of package in distribution
    # this often is not unique, i.e. one and the same package
    # may belong to one distribution via different repositories
    t.integer  "repository_id",   :limit => 11
    t.datetime "created_at"
    t.datetime "updated_at"
    # version of the package
    t.string   "version"
    # file name within the Ubuntu repository
    t.string   "filename"
    # download size in bytes
    # due to compression, this is usually smaller than the installed size
    t.integer  "size",            :limit => 11
    # installed size in kilobytes
    t.integer  "installedsize",   :limit => 11
  end

# temporary lists of packages for editing the package list of a bundle
  create_table "carts", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

# list elements for carts
  create_table "cart_contents", :force => true do |t|
    t.integer  "cart_id",         :limit => 11
    t.integer  "base_package_id", :limit => 11
    t.datetime "created_at"
    t.datetime "updated_at"
  end

########################### users ###################################

# list of packages that a user has selected for installation
# this may complement and override the selection from user_profiles
  create_table "user_packages", :force => true do |t|
    t.integer  "user_id",     :limit => 11
    t.integer  "package_id",  :limit => 11
    t.boolean  "is_selected"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

# list of categories that a user has selected
  create_table "user_profiles", :force => true do |t|
    t.integer  "user_id",     :limit => 11
    t.integer  "category_id", :limit => 11
    # 0 = not selected
    # should be replaced by boolean
    t.integer  "rating",      :limit => 11
    t.datetime "created_at"
    t.datetime "updated_at"
  end

# users and temporary users for anonymous logins
  create_table "users", :force => true do |t|
    # login names, anonymous users have generated names a000 etc.
    t.string   "login"
    # the following ata are from the authenticated_system plugin
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
    # see base_packages
    t.integer  "license",                   :limit => 11, :default => 1
    # see base_packages
    t.integer  "security",                  :limit => 11, :default => 2
    # distribution selected by the user
    t.integer  "distribution_id",           :limit => 11, :default => 2
    # language selected by the user. Currently not used
    # Not sure whether this will be useful at all, because different localisations will be different rails instances
    t.integer  "language_id",               :limit => 11, :default => 1
    # 1 = this is the user's first login
    # should be replaced by boolean
    t.integer  "first_login",               :limit => 11, :default => 1
    # not needed, can be removed
    t.integer  "template_id",               :limit => 11
    # derivative selected by the user
    t.integer  "derivative_id",             :limit => 11
    # version of the user_profiles data
    t.integer  "profile_version",           :limit => 11
    # has the profile changed since the last generation of a metapackage for the user?
    t.boolean  "profile_changed",                         :default => false
    # is the user a temporary anonymous user?
    t.boolean  "anonymous",                               :default => false
  end

# user roles. Currently, only the admin role is used
  create_table "roles", :force => true do |t|
    t.string   "rolename"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

# which user has which roles?
  create_table "permissions", :force => true do |t|
    t.integer  "role_id",    :limit => 11, :null => false
    t.integer  "user_id",    :limit => 11, :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

################ debian packages ###############################

# debian metapackages that are generated for the bundles
# each bundle leads to a number of metapackages:
# for each distribution, derivative, license_type and security_type
# this table is needed to record whether the generation has been
# successful or whether it needs to be repeated at a later stage
  create_table "debs", :force => true do |t|
    t.integer  "metapackage_id",  :limit => 11
    t.integer  "distribution_id", :limit => 11
    t.integer  "derivative_id",   :limit => 11
    t.integer  "license_type",    :limit => 11
    t.integer  "security_type",   :limit => 11
    t.string   "version"
    # url of the debian package
    t.string   "url"
    # was the metapackage generated successfully?
    t.boolean  "generated"
    # is the metapackage superseeded by another one?
    t.boolean  "outdated"
    # ruby error message that occured during metapackage generation
    t.string   "errmsg"
    t.datetime "created_at"
    t.datetime "updated_at"
    # log of the metapackage generation
    t.text     "log"
  end

# dependencies between Ubuntu packages
# this information is read in from the Ubuntu repositories
  create_table "dependencies", :force => true do |t|
    # package in a specific distribution
    t.integer  "package_distr_id", :limit => 11
    # package it refers to
    t.integer  "base_package_id",  :limit => 11
    # 0 = depends, 1 = recommends, 2 = conflicts, 3 = suggests
    t.integer  "dep_type",         :limit => 11
    t.datetime "created_at"
    t.datetime "updated_at"
  end

########################### unused ################################

# needed for localisation, currently not used
  create_table "languages", :force => true do |t|
    t.string   "name"
    t.string   "country_code"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

# needed for localisation, currently not used
  create_table "translations", :force => true do |t|
    t.integer  "language_id", :limit => 11
    t.string   "tag"
    t.text     "contents"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

# experimental poll about lists of installed packages
  create_table "umfrage_packages", :force => true do |t|
    t.integer  "umfrage_id", :limit => 11
    t.string   "package"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

# experimental poll about lists of installed packages
  create_table "umfrage_sources", :force => true do |t|
    t.integer  "umfrage_id", :limit => 11
    t.string   "source"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

# experimental poll about lists of installed packages
  create_table "umfrages", :force => true do |t|
    t.boolean  "einsteiger"
    t.boolean  "freak"
    t.boolean  "sammler"
    t.boolean  "musik"
    t.boolean  "video"
    t.boolean  "netz"
    t.boolean  "grafik"
    t.boolean  "spiele"
    t.string   "email"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end
