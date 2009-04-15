class Distribution < ActiveRecord::Base
  has_many :packages, :dependent => :destroy
  has_many :repositories, :dependent => :destroy
  has_many :metapackages, :dependent => :destroy
  has_many :metacontents_distrs

  # return the distribution info from the browser info string
  def self.browser_info(s)
    index = s.index("Ubuntu")
    if index.nil? then
      s = nil
    else
      s = s[index+7,s.length]
      index = s.index(")")
      if !index.nil? then
        s = s[0,index+1]
      end  
    end  
    return s
  end
end
