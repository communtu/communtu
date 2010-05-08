class CreateDebs < ActiveRecord::Migration
  def self.up
    create_table :debs do |t|
      t.integer :metapackage_id
      t.integer :distribution_id
      t.integer :derivative_id
      t.integer :license_type
      t.integer :security_type
      t.string :version
      t.string :url
      t.boolean :generated
      t.boolean :outdated
      t.string :errmsg

      t.timestamps
    end
  end

  def self.down
    drop_table :debs
  end
end
