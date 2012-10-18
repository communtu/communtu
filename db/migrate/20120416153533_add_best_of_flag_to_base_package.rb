class AddBestOfFlagToBasePackage < ActiveRecord::Migration
  def change
    add_column :base_packages, :best_of, :boolean, :default => false
  end
end
