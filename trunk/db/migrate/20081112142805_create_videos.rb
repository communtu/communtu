class CreateVideos < ActiveRecord::Migration
  def self.up
    remove_column :base_packages, :videos
    create_table :videos do |t|
      t.integer :base_package_id
      t.string :url
      t.text :description

      t.timestamps
    end
  end

  def self.down
    drop_table :videos
  end
end
