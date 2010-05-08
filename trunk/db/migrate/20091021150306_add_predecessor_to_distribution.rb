class AddPredecessorToDistribution < ActiveRecord::Migration
  def self.up
    add_column :distributions, :distribution_id, :integer
    add_column :distributions, :invisible, :boolean, :default => true
    Distribution.all.each do |d|
      d.invisible = false
      d.distribution_id = d.id-1
      d.save
    end
  end

  def self.down
    remove_column :distributions, :invisible
    remove_column :distributions, :distribution_id
  end
end
