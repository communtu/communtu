class Info < ActiveRecord::Base
  belongs_to :author, :class_name => 'User'

  def header
    translation(self.header_tid)
  end

  def content
    translation(self.content_tid)
  end
end
