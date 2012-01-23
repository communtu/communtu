class LiveCd < ActiveRecord::Base
  def self.bestof
    LiveCd.order("downloaded DESC").limit(10)
  end
  def self.categories
    ["Grafik","Multimedia","Spiele","Kommunikation","Windows"]
  end
end
