class CreateUmfragePackages < ActiveRecord::Migration
  def self.up
    create_table :umfrage_packages do |t|
      t.integer :umfrage_id
      t.string :package

      t.timestamps
    end
  end

  def self.down
    drop_table :umfrage_packages
  end
end
