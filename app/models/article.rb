# (c) 2008-2010 by Verein Allgemeinbildung e.V., Bremen, Germany
# use, modification or distribution only with permission of the copyright holder

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
