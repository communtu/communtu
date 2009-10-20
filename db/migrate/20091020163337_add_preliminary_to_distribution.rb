class AddPreliminaryToDistribution < ActiveRecord::Migration
  def self.up
    add_column :distributions, :preliminary, :boolean, :default => true
    add_column :users, :advanced, :boolean, :default => false
    Distribution.all.each do |d|
      d.preliminary = false
      d.save
    end
  end

  def self.down
    remove_column :distributions, :preliminary
    remove_column :users, :advanced
  end
end
