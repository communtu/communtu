class CreateBasePackages < ActiveRecord::Migration
  def self.up
    create_table :base_packages do |t|
      t.string  :type
      t.integer :distribution_id
      t.integer :repository_id
      t.string :name
      t.string :section, :default => "unknown"
      t.string :version
      t.text   :description
      t.integer :category_id
      t.integer :rating
      t.integer :license_type
      t.integer :distribution_id
      t.integer :user_id
      t.integer :published, :default => Metapackage.state[:pending]

      t.timestamps
    end
  end

  def self.down
    drop_table :packages
  end

