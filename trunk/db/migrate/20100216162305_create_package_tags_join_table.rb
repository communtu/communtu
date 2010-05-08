class CreatePackageTagsJoinTable < ActiveRecord::Migration
  def self.up
    create_table :package_tags do |t|
      t.integer :package_id
      t.integer :tag_id
    end
  end

  def self.down
    drop_table :package_tags
  end
end
