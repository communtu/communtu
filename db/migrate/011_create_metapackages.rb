class CreateMetapackages < ActiveRecord::Migration
  def self.up
    create_table :metapackages do |t|
      t.string :name
      t.text :description
      t.integer :category_id
      t.integer :rating
      t.integer :license_type
      t.integer :distribution_id
      t.integer :user_id
      t.integer :published, :default => Metapackage.state[:pending]

      t.timestamps
    end
  end

  def self.down
    drop_table :metapackages
  end
end
