class AddDownloadedToLivecds < ActiveRecord::Migration
  def self.up
    add_column :livecds, :downloaded, :int, :default => 0
    Dir.glob("/var/log/apache2/*-communtu.log*gz").each do |file|
      IO.popen("gunzip -c #{file}").each do |line|
        cdname = line.scan(/.*\/isos\/(.*).iso.*/).flatten[0]
        Livecd.all.select{|cd| cd.fullname == cdname}.each do |cd|
          cd.downloaded += 1
          cd.save
        end
      end
    end
  end

  def self.down
    remove_column :livecds, :downloaded
  end
end
