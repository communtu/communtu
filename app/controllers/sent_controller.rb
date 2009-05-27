class SentController < ApplicationController
  def index
    @messages = current_user.sent_messages.find(:all, :limit=>10, :order => "created_at DESC")
  end

  def show
    @message = current_user.sent_messages.find(params[:id])
  end

  def new
    @message = current_user.sent_messages.build(params[:message])
    #Looks for User Id from URL and fills into inputbox
    !params[:mail_to].nil? ? @message.to = User.find(params[:mail_to]).login : nil
    session[:return_to] = request.env["HTTP_REFERER"]
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
          flash[:notice] = "Nachricht erfolgreich versendet"
          redirect_to  request.get? ? request.env["HTTP_REFERER"] : session[:return_to]
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

