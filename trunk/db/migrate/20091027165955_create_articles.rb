class CreateArticles < ActiveRecord::Migration
  def self.up
    create_table :articles, :force => true do |t|
    t.column :created_at, :datetime, :null => false
    t.column :url_tid, :integer
    t.column :name_tid, :integer
    t.column :description_tid, :integer
    t.column :language_code, :string, :limit => 3
    end
  end

  def self.down
    drop_table :artciles
  end
end
