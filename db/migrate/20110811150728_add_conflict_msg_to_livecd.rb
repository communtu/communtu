class AddConflictMsgToLivecd < ActiveRecord::Migration
  def self.up
    add_column :livecds, :conflict_msg, :text
    remove_column :base_packages, :conflict_msg
    add_column :base_packages, :conflict_msg, :text
  end

  def self.down
    remove_column :livecds, :conflict_msg
  end
end
