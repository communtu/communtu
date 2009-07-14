class AddRatingCountToBasePackage < ActiveRecord::Migration
  def self.up
#    add_column :base_packages, :ratings_count, :integer
  end

  def self.down
    remove_column :base_packages, :ratings_count
  end
end
