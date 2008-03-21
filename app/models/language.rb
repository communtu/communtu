class Language < ActiveRecord::Base
  has_many(:translations)
  def translate(tag,links=[])
    t = Translation.find(:first, :conditions => ["tag = ? AND language_id = ?", tag, self.id])
    if t.nil? then # not found? then use English as default
      l = Language.find(:first, :conditions => ["country_code = ?", "en"])
      t = Translation.find(:first, :conditions => ["tag = ? AND language_id = ?", tag, l])
      if t.nil? then
        return "unknown tag: "+tag
      end
    end
    # substitute links
    res = ""
    ind = 0
    t.contents.split("[").each do |s| 
      i = s.index(']')
      if i.nil? then
        res += s
      else
        res += '<a href="'+links[ind]+'">'+s[0,i]+'</a>'+s[i+1,s.length-(i+1)]
        ind +=1
      end
    end
    return res
  end
  
  def self.translate(tag,links=[])
    current_user.language.translate(tag,links)
  end
end
