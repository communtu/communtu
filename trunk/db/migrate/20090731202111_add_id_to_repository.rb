class AddIdToRepository < ActiveRecord::Migration
  def self.up
    add_column :repositories, :gpgkey_tid, :integer
    add_column :repositories, :url_tid, :integer
  end

  def self.down
    remove_column :repositories, :gpgkey_tid
    remove_column :repositories, :url_tid
  end
end
