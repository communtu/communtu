class Suggestion < ActiveRecord::Base


  MAX_RULES = 10000

  def self.fillDb

    #Suggestion.delete_all
    fp_directory = "public/data/fpgrowth"
    fp_filename = "fp_data_out.txt"
    fp_path =  File.join(fp_directory, fp_filename)
    rules = []
    File.open(fp_path) do |infile|
      while (line = infile.gets)
        r = line.scan(/(.+)\s\s\((.+)\)/)
        if r.is_a?(Array) && r[0].is_a?(Array)
          rules.push({ :rule => r[0][0], :rating => r[0][1] })
          #Suggestion.create :rule => r[0][0], :rating => r[0][1]
        else
          puts "totally random error: file fucked up."
          puts "Server Shutdown initialized"
        end
      end
    end
    Suggestion.create!( rules )
    return nil
  end
end
