class LiveCd < ActiveRecord::Base
  def self.bestof
    LiveCd.order("downloaded DESC").limit(10)
  end
  def self.categories
    ["Grafik","Multimedia","Spiele","Kommunikation","Windows"]
  end
end
class Array
  def our_sort_by(params)
   desc = case params[:order] 
           when "asc" then 1
           when "desc" then -1
           else 1
          end
    case params[:by]
        when "name" then method = lambda {|x| x.name.downcase}
        when "size" then method = lambda &:size
        else method = lambda &:downloaded
    end  
    sort{|x,y|(method.call(x)<=>method.call(y))*desc}
  end  
end
