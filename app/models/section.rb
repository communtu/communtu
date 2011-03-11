# (c) 2008-2011 byllgemeinbildung e.V., Bremen, Germany
# This file is part of Communtu.

# Communtu is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# Communtu is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero Public License for more details.

# You should have received a copy of the GNU Affero Public License
# along with Communtu.  If not, see <http://www.gnu.org/licenses/>.

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
