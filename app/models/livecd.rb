class Livecd < ActiveRecord::Base
  belongs_to :distribution
  belongs_to :derivative
  belongs_to :architecture
  belongs_to :user

  def fullversion
    self.derivative.name.downcase+"-"+self.distribution.name.gsub(/[a-zA-Z ]/,'')+"-desktop-"+self.architecture.name
  end

  def filename
    "#{RAILS_ROOT}/public/debs/#{self.name}-#{self.fullversion}.iso"
  end
end
