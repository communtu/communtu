class CreateLivecds < ActiveRecord::Migration
  def self.up
    create_table :livecds do |t|
      t.string :name
      t.integer :distribution_id
      t.integer :derivative_id
      t.integer :architecture_id
      t.integer :user_id
      t.integer :metapackage_id
      t.integer :size
      t.boolean :generated, :default => false

      t.timestamps
    end
  end

  def self.down
    drop_table :livecds
  end
end
