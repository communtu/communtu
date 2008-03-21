class CreateTempMetapackages < ActiveRecord::Migration
  def self.up
    create_table :temp_metapackages do |t|
      t.string :name
      t.text :description
      t.integer :distribution_id
      t.integer :user_id
      t.integer :rating
      t.integer :license_type
      t.integer :is_saved, :default => 0

      t.timestamps
    end
  end

  def self.down
    drop_table :temp_metapackages
  end
end
