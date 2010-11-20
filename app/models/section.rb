# (c) 2008-2010 by Verein Allgemeinbildung e.V., Bremen, Germany
# use, modification or distribution only with permission of the copyright holder

# debian sections, a classification of packages
# shall be replaced by debtags

# database fields: 
# name: deprecated
# name_tid: internationalised name, using table Translation

class Section < ActiveRecord::Base
  validates_uniqueness_of  :name_tid

   # this does not work - why?
  has_many :translations, :foreign_key => :translatable_id, :primary_key => :name_tid

  def self.find_or_create_section_by_name_and_language(name, lang = "en")
    s = Section.find(:first,
         :conditions=>["translations.contents = ? and translations.language_code = ?",
                        name,lang],
#         :include => :translations)  # this does not work - why?
         :joins => "LEFT JOIN translations ON sections.name_tid = translations.translatable_id")
    if s.nil? then
      t = Translation.new_translation(name,lang)
      s = Section.create(:name_tid => t.translatable_id)
    end
    return s
  end
end
