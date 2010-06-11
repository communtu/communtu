class AddVmRunnningToLiveCd < ActiveRecord::Migration
  def self.up
    add_column :livecds, :vm_pid, :integer
  end

  def self.down
    remove_column :livecds, :vm_running
  end
end
