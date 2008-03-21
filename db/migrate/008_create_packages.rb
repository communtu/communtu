class CreatePackages < ActiveRecord::Migration
  def self.up
    create_table :packages do |t|
      t.integer :distribution_id
      t.integer :repository_id
      t.string :name
      t.string :section, :default => "unknown"
      t.string :version
      t.text   :description

      t.timestamps
    end
  end

  def self.down
    drop_table :packages
  end
end
