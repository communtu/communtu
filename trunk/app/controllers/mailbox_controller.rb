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
