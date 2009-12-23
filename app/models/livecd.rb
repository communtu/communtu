class Livecd < ActiveRecord::Base
  belongs_to :distribution
  belongs_to :derivative
  belongs_to :architecture
  belongs_to :user

  def filename
    "#{RAILS_ROOT}/public/debs/#{self.name}.iso"
  end
end
