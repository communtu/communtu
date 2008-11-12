class CreateDerivatives < ActiveRecord::Migration
  def self.up
    create_table :derivatives do |t|
      t.string :name
      t.string :icon_file

      t.timestamps
    end
  end

  def self.down
    drop_table :derivatives
  end
end
