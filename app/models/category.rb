class Category < ActiveRecord::Base
  require "lib/utils.rb"
  acts_as_tree :order => "name"
  has_many :metapackages
  belongs_to :category, :foreign_key => 'parent_id'

  def name
    translation(self.name_tid)
  end

  def description
    translation(self.description_tid)
  end

  def link
    trans = translation(self.link_tid)
    if trans == "unknown"
      trans = ""
    end
    return trans
  end

  def parent_name
    if category.nil? then "" else category.name end
  end
  
  def self.draw_tree
    f=File.open("categories.dot","w")
    f.puts "digraph G {"
    Category.find(1).draw_tree_aux(f)
    f.puts "}"
    f.close
  end
  
  def draw_tree_aux(f)
    f.puts '"'+self.name+'";'
    self.children.each do |child|
      f.puts '"'+self.name+'" -> "'+child.name+'";'
      child.draw_tree_aux(f)
    end
  end
end
