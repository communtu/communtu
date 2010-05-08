class CreateTempMetacontents < ActiveRecord::Migration
  def self.up
    create_table :temp_metacontents do |t|
      t.integer :temp_metapackage_id
      t.integer :package_id

      t.timestamps
    end
  end

  def self.down
    drop_table :temp_metacontents
  end
end
