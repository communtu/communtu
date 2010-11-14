# (c) 2008-2010 by Verein Allgemeinbildung e.V., Bremen, Germany
# use, modification or distribution only with permission of the copyright holder

# localisation for string that are stored in the database
# each translatable_id can have several translations (for the different language_codes)
# translatable_ids are stored in other tables
# e.g. the name of a metapackage is realised as translatable_id
# (there it is called name_tid, see table base_packages)

# database fields: 
# contents
# language_code
# translatable_id

class Translation < ActiveRecord::Base
  belongs_to(:language)
  
  def self.new_translation(s, l = I18n.locale.to_s)
    t = Translation.find_by_contents_and_language_code(s,l)
    if !t.nil? then
      return t
    end
    last_trans = Translation.find(:first, :order => "translatable_id DESC")
    last_id = last_trans.translatable_id
    Translation.create({:translatable_id => last_id + 1,
                        :language_code => l,
                        :contents => s})
  end
end
