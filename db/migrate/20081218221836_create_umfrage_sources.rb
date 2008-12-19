class CreateUmfrageSources < ActiveRecord::Migration
  def self.up
    create_table :umfrage_sources do |t|
      t.integer :umfrage_id
      t.string :source

      t.timestamps
    end
  end

  def self.down
    drop_table :umfrage_sources
  end
end
