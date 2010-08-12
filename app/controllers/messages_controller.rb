# (c) 2008-2010 by Verein Allgemeinbildung e.V., Bremen, Germany
# use, modification or distribution only with permission of the copyright holder

class MessagesController < ApplicationController
  before_filter :is_anonymous
  
  def show
    @message = current_user.received_messages.find(params[:id])
    @message.is_read = true;
    @message.save
  end
  
  def reply
    session[:return_to] = '/inbox'
    
    @original = current_user.received_messages.find(params[:id])
    
    subject = @original.subject.sub(/^(Re: )?/, "Re: ")
    body = @original.body.gsub(/^/, "> ")
    @message = current_user.sent_messages.build(:to => [@original.author.login], :subject => subject, :body => body)
    render :template => "sent/new"
    
  end
  
  def forward
    session[:return_to] = '/inbox'
    
    @original = current_user.received_messages.find(params[:id])
    
    subject = @original.subject.sub(/^(Fwd: )?/, "Fwd: ")
    body = t(:controller_messages_0, {:user=>@original.author.login, :datum=>change_date_time(@original.created_at)})
    body += @original.body.gsub(/^/, "> ")
    @message = current_user.sent_messages.build(:subject => subject, :body => body)
    render :template => "sent/new"
  end
  
  def destroy
    @message = current_user.received_messages.find(params[:id])
    @message.destroy
    redirect_to inbox_path
  end

end
