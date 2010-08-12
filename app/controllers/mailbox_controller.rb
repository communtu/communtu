# (c) 2008-2010 by Verein Allgemeinbildung e.V., Bremen, Germany
# use, modification or distribution only with permission of the copyright holder

class MailboxController < ApplicationController
  before_filter :is_anonymous
  
  def index
    @folder = current_user.inbox
    show
    render :action => "show"
  end

  def show
    @folder ||= current_user.folders.find_by_user_id(current_user)
    @messages = @folder.messages.find(:all, :limit=>10, :order => "message_id DESC")
  end
end
