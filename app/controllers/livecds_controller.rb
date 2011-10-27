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

class LivecdsController < ApplicationController
  before_filter :login_required, :only => [:destroy, :remaster, :force_remaster, :remaster_new]
  before_filter :check_administrator_role, :add_flash => { :notice => I18n.t(:no_admin) }, :only => [:start_vm_basis]
  before_filter :check_power_user_role, :add_flash => { :notice => I18n.t(:no_admin) }, :only => [:start_vm, :stop_vm]
  before_filter :check_livecd_enabled, :only => [:start_vm, :stop_vm, :remaster, :force_remaster, :remaster_new, :start_vm_basis]
  
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
       @cd.mark_remaster
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
    if !SETTINGS["livecd"]
      flash[:error] = t(:livecd_disabled)
      redirect_to :back
      return
    end
    @cd = Livecd.find(params[:id])
    if !session[:vm_vnc].nil?
      flash[:error] = t("vm_active_session",
             :stop => self.class.helpers.link_to(t(:vm_stop),"/livecds/#{session[:vm_cd]}/stop_vm"))
    else
      msg = @cd.start_vm(current_user)
      if msg.to_i == 0
        flash[:error] = msg
      else
        session[:vm_vnc] = msg
        session[:vm_cd] = @cd.id
        redirect_to "vnc://#{request.env['HTTP_X_FORWARDED_HOST']}:#{session[:vm_vnc]}"
        return
      end  
    end  
    redirect_to livecd_path(@cd)
  end

  def stop_vm
    @cd = Livecd.find(params[:id])
    @cd.stop_vm(current_user)
    session[:vm_vnc] = nil
    session[:vm_cd] = nil
    redirect_to livecd_path(@cd)
  end

  def start_vm_basis
    @cd = Livecd.find(params[:id])
    @cd.start_vm(current_user,true)
    @cd.vm_pid = 1
    @cd.save
    render :action => 'show'
  end

  def compute_conflicts
    @cd = Livecd.find(params[:id])
    @cd.edos_conflicts
    redirect_to :back
  end

end
