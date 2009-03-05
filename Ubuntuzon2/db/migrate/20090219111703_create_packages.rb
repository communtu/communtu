class CreatePackages < ActiveRecord::Migration
  def self.up
    create_table :packages do |t|
      t.string :name
      t.string :description
      t.string :version
      t.integer :standard

      t.timestamps
    end
  end

  def self.down
    drop_table :packages
  end
end
