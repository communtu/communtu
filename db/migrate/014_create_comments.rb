class CreateComments < ActiveRecord::Migration
  def self.up
    create_table :comments do |t|
      t.integer :user_id
      t.integer :metapackage_id, :default => 0
      t.integer :temp_metapackage_id, :default => 0
      t.text :comment

      t.timestamps
    end
  end

  def self.down
    drop_table :comments
  end
end
