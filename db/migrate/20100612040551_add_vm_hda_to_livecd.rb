class AddVmHdaToLivecd < ActiveRecord::Migration
  def self.up
    add_column :livecds, :vm_hda, :string
  end

  def self.down
    remove_column :livecds, :vm_hda
  end
end
