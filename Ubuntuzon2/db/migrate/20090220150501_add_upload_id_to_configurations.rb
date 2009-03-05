class AddUploadIdToConfigurations < ActiveRecord::Migration
  def self.up
    add_column "configurations", "upload_id", :integer
  end

  def self.down
    remove_column "configurations", "upload_id"
  end
end
