class SentController < ApplicationController
  def index
    @messages = current_user.sent_messages.find(:all, :limit=>10, :order => "created_at DESC")
  end

  def show
    @message = current_user.sent_messages.find(params[:id])
  end

  def new
    @message = current_user.sent_messages.build(params[:message])
  end
  
  def create
    if(!User.find_by_login(params[:message]['to']).nil?)
      @message = current_user.sent_messages.build(params[:message])
    else
      flash[:error] = "Benutzer existiert nicht"
      redirect_to new_sent_path({:message=>params[:message]})
      return
    end
    
    if @message.save
      respond_to do |format|
        format.html do 
          flash[:notice] = "Nachricht gesendet."
          redirect_to :action => "index"
        end
      end
    else
      render :action => "new"
    end
  end
  
  def update_user_exists
    render :update do |page|
      if(User.find_by_login(params[:message]['to']).nil?)
        page.replace_html :user_exists, :partial => 'user_not_exists'
      else
        page.replace_html :user_exists, :partial => 'user_exists'
      end  
    end
  end
end

