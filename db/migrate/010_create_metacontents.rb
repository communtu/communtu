class CreateMetacontents < ActiveRecord::Migration
  def self.up
    create_table :metacontents do |t|
      t.integer :metapackage_id
      t.integer :package_id
      t.boolean :is_meta

      t.timestamps
    end
  end

  def self.down
    drop_table :metacontents
  end
end
