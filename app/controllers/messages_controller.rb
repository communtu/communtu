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
