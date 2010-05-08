class CreateRepositories < ActiveRecord::Migration
  def self.up
    create_table :repositories do |t|
      t.integer :distribution_id
      t.integer :security_type
      t.integer :license_type
      t.text :type
      t.string :url
      t.string :subtype

      t.timestamps
    end
  end

  def self.down
    drop_table :repositories
  end
end

