class CreateWhitelists < ActiveRecord::Migration
  def self.up
    create_table :whitelists do |t|
      t.string :package
      t.integer :standard
      t.integer :rating

      t.timestamps
    end
  end

  def self.down
    drop_table :whitelists
  end
end
