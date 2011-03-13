namespace :db do
  desc 'Minimize database, for creating database db/data.yml for test purposes.'
  task :minimize  => :environment do
      puts "Shrinking database, this will take some time"
      [Article,Deb,Cart,CartContent,Comment,Folder,Info,Message,MessageCopy,Userlog].each do |c|
        puts "removing all records for #{c.to_s}"
        c.destroy_all
      end
      puts "removing most bundles"
      bundles = Metapackage.all
      bundles.remove(Metapackage.first)
      bundles.each do |b|
        b.destroy
      end      
      puts "removing most users"
      User.all.each do |u|
        if u.id >= 3 then u.destroy end
      end
      # user admin, password admin
      u = User.find(1)
      u.login = "admin"
      u.email=  "admin@example.com"
      u.crypted_password = "3ef7bb69faa7b274b65a3ad54093903ec0eaddc5"
      u.salt = "70322f50fc8713c5fa1f47da30d5714f0ead89b8"
      u.save
      u.roles = [Role.first]
      b = Metapackage.first
      b.user = u
      b.save
      # user test, password test
      u = User.find(2)
      u.login = "test"
      u.email = "test@example.com"
      u.crypted_password = "5df21cdf2f9f1da19be20a0f870ed6993309bcea"
      u.salt = "38e6a285c5997b4e61556cbf83feb20d9f15ebc8"
      u.save
      u.roles = []
  end
end
