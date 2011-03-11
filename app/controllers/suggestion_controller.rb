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

class SuggestionController < ApplicationController
  def title
    t(:view_layouts_application_21)
  end

  def install_sources
    if check_login then return end
    if current_user.selected_packages.empty? then
      flash[:error] = t(:controller_suggestion_1)
      redirect_to "/download/selection"
      return
    end
    debfile = current_user.install_sources
    if debfile.nil? then
      flash[:error] = t(:creation_error)
      redirect_to "/home"
      return
    end
    send_file debfile, :type => 'application/x-debian-package'
  end

  def install_bundle_sources
    if check_login then return end
    bundle = Metapackage.find(params[:id])
    debfile = current_user.install_bundle_sources(bundle)
    if debfile.nil? then
      flash[:error] = t(:creation_error)
      redirect_to "/home"
      return
    end
    send_file debfile, :type => 'application/x-debian-package'
  end

  def install_package_sources
    if check_login then return end
    package = Package.find(params[:id])
    debfile = current_user.install_package_sources(package)
    if debfile.nil? then
      flash[:error] = "Bei der Erstellung des Pakets ist ein Fehler aufgetreten."
      return
    end
    send_file debfile, :type => 'application/x-debian-package'
  end

  def install_bundle_as_meta
    if check_login then return end
    if current_user.selected_packages.empty? then
      flash[:error] = t(:controller_suggestion_1)
      redirect_to "/download/selection"
      return
    end
    debfile = current_user.install_bundle_as_meta
    if debfile.nil? then
      flash[:error] = t(:creation_error)
      redirect_to "/home"
      return
    end
    send_file debfile, :type => 'application/x-debian-package'
  end
  
end
