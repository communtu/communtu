# (c) 2008-2010 by Verein Allgemeinbildung e.V., Bremen, Germany
# use, modification or distribution only with permission of the copyright holder

# videos describing packages

# database fields: 
# base_package_id
# description: deprecated
# description_tid: internationalised description (using table Translation)
# url: deprecated
# url_tid: internationalised url of the video (using table Translation)

class Video < ActiveRecord::Base
   require "lib/utils.rb"
  belongs_to :base_package

  def description
    translation(self.description_tid)
  end

  def url
    trans = translation(self.url_tid)
    if trans == "unknown"
      trans = ""
    end
    return trans
  end
end
