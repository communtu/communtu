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

class LivecdsController < ApplicationController
  before_filter :login_required

  def title
    "Communtu: " + t(:livecd)
  end
  
  def destroy
    @cd = Livecd.find(params[:id])
    # detach live CD from user
    @cd.deregister(current_user)
    redirect_to :back
  end

  def show
    @cd = Livecd.find(params[:id])
  end

  def remaster
    @cd = Livecd.find(params[:id])
    if !@cd.generated
      @cd.failed = false
      @cd.generating = false
      @cd.generated = false
      @cd.log = nil
      @cd.save
      # remastering done by daemon
    end
    redirect_to :back
  end

  def force_remaster
    @cd = Livecd.find(params[:id])
    @cd.generated = false
    @cd.save
    remaster
  end
  
  def remaster_new
    @cd = Livecd.find(params[:id])
    if !@cd.generate_sources.nil?
      remaster
    end
  end

  def index
  end

  def start_vm
    @cd = Livecd.find(params[:id])
    @cd.start_vm
    redirect_to livecd_path(@cd)
  end

  def stop_vm
    @cd = Livecd.find(params[:id])
    @cd.stop_vm
    redirect_to livecd_path(@cd)
  end

  def start_vm_basis
    @cd = Livecd.find(params[:id])
    @cd.start_vm_basis
    render :action => 'show'
  end

  def download
    @cd = Livecd.find(params[:id])
    @cd.downloaded += 1
    @cd.save
    send_file @cd.iso_image, :type => "application/iso-file"
  end

end
