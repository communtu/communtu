class CreateArchitectures < ActiveRecord::Migration
  def self.up
    create_table :architectures do |t|
      t.string :name

      t.timestamps
    end

    Architecture.create(:name => "i386")
    Architecture.create(:name => "amd64")
  end

  def self.down
    drop_table :architectures
  end
end
