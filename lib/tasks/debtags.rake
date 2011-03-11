# (c) 2008-2011 by Allgemeinbildung e.V., Bremen, Germany
# This file is part of Communtu.

 # Communtu is free software: you can redistribute it and/or modify
 # it under the terms of the GNU Affero Public License as published by
 # the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

 # Communtu is distributed in the hope that it will be useful,
 # but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero Public License for more details.

# You should have received a copy of the GNU Affero Public License
# along with Communtu.  If not, see <http://www.gnu.org/licenses/>.

namespace :debtags do
   desc "read in debtags from http://debtags.alioth.debian.org/tags/tags-current.gz"
   task :read_tags => :environment do
        read_tagscurrent
   end
   desc "read in popcon data from http://popcon.ubuntu.com/all-popcon-results.txt.gz"
   task :read_popcon => :environment do
        add_popcon
   end
   desc "read in debtags vocabulary from http://debtags.alioth.debian.org/tags/vocabulary.gz"
   task :read_vocabulary => :environment do
        add_tag_extensions
   end
end  

  private
  def read_tagscurrent
    system "cd /tmp; wget http://debtags.alioth.debian.org/tags/tags-current.gz"
    system "gunzip /tmp/tags-current.gz"
    file = "/tmp/tags-current"
    puts "read tagscurrent from " + file
    # we don't want the database to be written again..
    # OPTIMIZE: hash the source file, save the hash and compare it with the new file so we can tell if we have to update the db
    #puts "To prevent you from destroying your database, please comment out exit in " + __FILE__ + ":" + (__LINE__+1).to_s
    #exit

    i = 0
    open(file).each do |l|
      i += 1

      matches = /^([a-zA-Z\.0-9\-\+_]+):?(.*)/.match(l.chomp) #we don't need lstrip because the regex only matches on lines starting with characters

      if (package = Package.create(:name => matches[1])).id != nil
        package_id = package.id
      else
        package_id = Package.find_by_name(matches[1]).id
      end

      # 2nd regexp match
      matches[2].chomp.split(", ").each do |t|
        tag_name = t.chomp.strip
        puts tag_name
        if (tag = Tag.create(:name => tag_name)).id != nil
          tag_id = tag.id
        else
          tag_id = Tag.find_by_name(tag_name).id
        end

        # do we get any empty ids? then something went horribly wrong.
        if(tag_id == nil || package_id == nil)
          puts "failed at tag_id " + tag_id.to_s + ", package_id " + package_id.to_s
          exit
        end

        package_tag = PackageTag.create( { :package_id => package_id, :tag_id => tag_id } )
      end
    end
    puts i.to_s + " lines processed."
  end

  private
  def add_popcon
    system "cd /tmp; wget http://popcon.ubuntu.com/all-popcon-results.txt.gz"
    system "gunzip /tmp/all-popcon-results.txt.gz"
    file = "/tmp/all-popcon-results.txt"
    puts "add popcon data from " + file
    # we don't want the database to be written again..
    # OPTIMIZE: hash the source file, save the hash and compare it with the new file so we can tell if we have to update the db
    #puts "To prevent you from destroying your database, please comment out exit in " + __FILE__ + ":" + (__LINE__+1).to_s
    #exit

    packages_db = Package.find(:all)
    packages = []
    packages_db.each do |pkg|
      packages << pkg[:name].downcase
    end

    i = 0
    open(file).each do |l|
      i += 1
      #                 first,            second,           third,      fourth,     fifth       sixth match
      matches = /^([a-zA-Z]+):[ ]*([a-zA-Z\.0-9\-\+_]+)[ ]*([0-9]+)[ ]*([0-9]+)[ ]*([0-9]+)[ ]*([0-9]+)$/.match(l.chomp)
      if matches
        if matches[1].casecmp("package")
          if packages.include?(matches[2].downcase)
            if (matches[3].to_i) && (matches[4].to_i) && (matches[5].to_i) && (matches[6].to_i)
                pkg = Package.find_by_name(matches[2])
                Package.update( pkg,
                  :p_vote    => matches[3],
                  :p_old     => matches[4],
                  :p_recent  => matches[5],
                  :p_nofiles => matches[6]
                )
                unless pkg.save
                  puts "FATAL: save to database not successful on line " + i.to_s + ":"
                  puts l.to_s
                  exit
                end
            else
              puts "FATAL: the popcon results file does not provide four integers on line " + i.to_s + ":"
              puts l.to_s
              exit
            end
          end
        end
      else
        puts "WARNING: the popcon results file does not match the regex on line " + i.to_s + ":"
        puts l.to_s
      end
    end
    puts i.to_s + " lines processed."
  end

  # OPTIMIZE Known bugs:
  # There is an "Implies:" field.
  # There exist tags that have no facet.
  # There are tags that are equal to facets.
  # The Tag model currently defines :name as unique and if we change this, it
  # might break everything.
  private
  def add_tag_extensions
    system "cd /tmp; wget http://debtags.alioth.debian.org/tags/vocabulary.gz"
    system "gunzip /tmp/vocabulary.gz"
    file = "/tmp/vocabulary"
    puts "read tag extensions from " + file
    # we don't want the database to be written again..
    # OPTIMIZE: hash the source file, save the hash and compare it with the new file so we can tell if we have to update the db
    #puts "To prevent you from destroying your database, please comment out exit in " + __FILE__ + ":" + (__LINE__+1).to_s
    #exit


    tags_db = Tag.find(:all)
    tags = {}
    tags_db.each do |t|
      tags.merge!({ t[:name] => t[:id] })
    end

    tag_ext = {
      :name => "",
      :is_facet => false,
      :status => "",
      :nature => "",
      :description => ""
    }

    i = 0
    newline_count = 0
    open(file).each do |l|
      i += 1

      # #1: Facet|Tag|Status|Nature|Description|' '
      # #2: facet|tag|status|nature|description title|description -value
      #                #1       #2
      matches = /^(|[a-zA-Z]+): (.*)|^( )(.*)/.match(l.chomp)

      # == Behaviour
      # In case a line starts with "Facet", "Tag", "Status" or "Nature", we save
      # it to the corresponding field.
      #
      # Once we encounter a "Description" line, we have two cases:
      # a) we're currently in a Facet (and no Tag-Line was found before the
      # Description line) so the current description is a facet's description.
      # Facets have to be entered as new Tags with isFacet set.
      # b) we're currently in a Tag (that is we have Facet set but we also
      # encountered a Tag-Line just before the Description line) so we
      # (hopefully) don't have to create the tag, we just have to look it up and
      # add the description to it.
      # Since Descriptions have multiple lines, the current line might start
      # with a blank. In this case, matches[1] and [2] will be nil, therefore we
      # have to check for this special case.
      #
      # When we encounter matches = nil, it means we found an empty line. If we
      # found an empty line for the first time, we'll save the previously
      # extracted data and reset the variable. If it's the second or
      # onehundretandeleveneths time, we'll just wait until newlines stop and
      # text reappears.
      # There are some lines that just contain one space and then break. We'll
      # catch them as empty lines as well.
      #
      if !matches || (!matches[1] && matches[3] == " " && !matches[4]) # we're in an empty line
        newline_count += 1
        if tag_ext[:is_facet]
          Tag.create(tag_ext)
        else
          # find id by name in tags-Array, then use this to update corresponding tag in DB
          unless newline_count > 1
            begin
              tag = Tag.update(tags[tag_ext[:name]], tag_ext)
            rescue ActiveRecord::RecordNotFound # Tag actually doesn't exist yet so we create it
              tag = Tag.create(tag_ext)
            end
            unless tag.save
              puts "FATAL: couldn't save tag to DB on line " + i.to_s
              exit
            end
          end
        end
        tag_ext = {
          :name => "",
          :is_facet => false, # restore to default
          :status => tag_ext[:status], # keep status
          :nature => tag_ext[:nature], # keep nature
          :description => ""
        }
      elsif matches[3] == " " # so we're in a continued description line
          tag_ext[:description] += '\n' + matches[4].strip
      else # or we're in one of the regular lines
        newline_count = 0
        case matches[1]
        when "Facet"
          tag_ext[:is_facet] = true
          tag_ext[:name] = matches[2].strip
        when "Tag"
          tag_ext[:name] = matches[2].strip
        when "Status"
          tag_ext[:status] = matches[2].strip
        when "Nature"
          tag_ext[:nature] = matches[2].strip
        when "Description"
          tag_ext[:description] = matches[2].strip
        end
      end
    end
    puts i.to_s + " lines processed."
  end


