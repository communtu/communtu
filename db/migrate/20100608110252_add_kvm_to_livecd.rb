class AddKvmToLivecd < ActiveRecord::Migration
  def self.up
    add_column :livecds, :kvm, :boolean, :default => false
    add_column :livecds, :usb, :boolean, :default => false
  end

  def self.down
    remove_column :livecds, :kvm
    remove_column :livecds, :usb
  end
end
