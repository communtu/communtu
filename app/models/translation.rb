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

# localisation for string that are stored in the database
# each translatable_id can have several translations (for the different language_codes)
# translatable_ids are stored in other tables
# e.g. the name of a metapackage is realised as translatable_id
# (there it is called e.g. name_tid, see table base_packages)

# database fields: 
# contents: the localised string
# language_code: two-character code for the language
# translatable_id: the id equal to e.g. name_tid

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
