class Upload < ActiveRecord::Base
  belongs_to :account
  
  require 'ftools'
  
  # intersection of popcon (debian popularity contest) ratings to include into the whitelist
  PopconLowestRatingToInclude = 0000
  PopconHighestRatingToInclude = 150000

  def self.saveToUser(upload, account)

    # get the upload file data
    source = upload['datafile'].read
    filename = sanitize_filename(upload['datafile'].original_filename,account)
    
    # write upload to TMP-DIR
    tmp_directory = "/tmp"
    tmp_path = File.join(tmp_directory, filename)
    File.open(tmp_path, "wb") { |f| f.write(source) }
    
    # get MIME-TYPE
    mimetype = `file -ib #{tmp_path}`.gsub(/\n/,'')


    # check mime type and run if palin text
    if mimetype.include? "text/plain"

      # read the file and write the content into an array
      packages = Array.new()
      File.open(tmp_path) do |infile|
        while (line = infile.gets)
          # NOTE: "chop" is messing up the last line -> ".gsub(/\s/,'')" -> or "chomp" -> or "trim"
          packages.push(line.chomp)
        end
      end

      # get the whitelist and clear the file content
      whitelist = Whitelist.find_all_by_rating(PopconLowestRatingToInclude..PopconHighestRatingToInclude).collect(&:package)
      cleared = packages & whitelist

      # write the original file
      org_directory = "public/data/original"
      org_path = File.join(org_directory, filename)
      File.copy(tmp_path, org_path)
      
      # delete tmp file
      File.delete(tmp_path)

      # write the cleared file
      clr_directory = "public/data"
      clr_path = File.join(clr_directory, filename)
      File.open(clr_path, "wb") { |f|
        for package in cleared do
          f.write(package)
          f.write("\n")
        end
      }
      
      # write the data into the fpgrowth file
      fp_directory = "public/data/fpgrowth"
      fp_filename = "fp_source.txt"
      fp_path =  File.join(fp_directory, fp_filename)
      File.open(fp_path, "a+") { |f|
        for package in cleared do
          f.write(package)
          f.write(" ")
        end
        f.write("\n")
      }

      # write the filename into the database
      upload = Upload.create!( :account_id => account.id, :name => filename )

      # write the packages into the database
      cleared.each do |package_name|
        package = Package.find_or_create_by_name(package_name)
        account.configurations.create( :package => package, :rating => 0, :upload_id => upload[:id] )
        #account.packages << package
      end
      
      return true
      
    else
      
      # wrong mime type -> delete upload and do nothing
      File.delete(tmp_path)
      return false
      
    end

  end

  def self.sanitize_filename(file_name,account)
    # get only the filename (IE returns the whole path)
    # NOTE: File.basename doesn't work right with Windows paths on Unix
    just_filename = file_name.gsub(/^.*(\\|\/)/,'')
    # replace all not wanted characters
    just_filename = just_filename.gsub(/[^\w\.\-]/,'_')
    # add timestamp to filename
    [account.id, Time.now.to_i, just_filename].join("_")
  end

end
