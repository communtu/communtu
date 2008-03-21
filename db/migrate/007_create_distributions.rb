class CreateDistributions < ActiveRecord::Migration
  def self.up
    create_table :distributions do |t|
      t.string :name
      t.text :description

      t.timestamps
    end
  end

  def self.down
    drop_table :distributions
  end
end
