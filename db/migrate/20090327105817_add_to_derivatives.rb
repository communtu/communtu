class AddToDerivatives < ActiveRecord::Migration
  def self.up
    add_column :derivatives, :sudo, :string
    add_column :derivatives, :dialog, :string
  end

  def self.down
    remove_column :derivatives, :sudo
    remove_column :derivatives, :dialog
  end
end
