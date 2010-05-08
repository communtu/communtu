class Article < ActiveRecord::Base
   require "lib/utils.rb"

  def description
    translation(self.description_tid)
  end

  def url
    translation(self.url_tid)
  end
  
  def name
    translation(self.name_tid)
  end
end
