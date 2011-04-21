class ChangeHeaderAndContentToTid < ActiveRecord::Migration
  def self.up
    remove_column :infos, :header
    remove_column :infos, :content
    add_column :infos, :header_tid, :integer
    add_column :infos, :content_tid, :integer
  end

  def self.down
    remove_column :infos, :header_tid
    remove_column :infos, :content_tid
    add_column :infos, :header, :string
    add_column :infos, :content, :string
  end
end
