class AddMetapackageIdToCart < ActiveRecord::Migration
  def self.up
    add_column :carts, :metapackage_id, :integer
  end

  def self.down
    remove_column :carts, :metapackage_id
  end
end
