# (c) 2008-2011 by Allgemeinbildung e.V., Bremen, Germany
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

class RatingController < ApplicationController
  
  def rate
    @metapackage = Metapackage.find(params[:id])
    Rating.delete_all(["rateable_type = 'Metapackage' AND rateable_id = ? AND user_id = ?", @metapackage.id, current_user.id])
    t = Translation.new
    @last_trans = Translation.find(:first, :order => "translatable_id DESC")
    @last_id = @last_trans.translatable_id
    @l = @last_id + 1
    t.contents = params[:rating][:comment]
    t.translatable_id = @l
    t.language_code = I18n.locale.to_s
    t.save                                
    @metapackage.add_rating Rating.new(:rating => params[:user_rating], :user_id => current_user.id, :comment => params[:rating][:comment], :comment_tid => @l)
    redirect_to :back
  end
  
end