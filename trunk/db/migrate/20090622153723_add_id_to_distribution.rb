class AddIdToDistribution < ActiveRecord::Migration
  def self.up
    add_column :distributions, :description_tid, :integer
    add_column :distributions, :url_tid, :integer
  end

  def self.down
    remove_column :distributions, :description_tid
    remove_column :distributions, :url_tid
  end
end
