class AddLocaleToLivecdUser < ActiveRecord::Migration
  def self.up
    add_column :livecd_users, :locale, :string
  end

  def self.down
    remove_column :livecd_users, :locale
  end
end
