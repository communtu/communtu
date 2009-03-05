class CreateConfigChanges < ActiveRecord::Migration
  def self.up
    create_table :config_changes do |t|

      t.timestamps
    end
  end

  def self.down
    drop_table :config_changes
  end
end
