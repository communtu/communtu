class SearchesController < ApplicationController
  layout 'application'

  PACKAGES_MAXNUM = 25 # TODO set this as some kind of config constant
  QUERY_MINLENGTH = 3 # TODO set this as some kind of config constant

  $query    = ""
  $tags     = []
  $packages = []


  

  def index
    met_requirements = false

    # get query and precision from params or else from cookie
    if (query = params[:query])
      precision = "full" unless (precision = params[:precision])
      met_requirements = true
    end
    
    if met_requirements
      session[:query] = query
      $query = query
      session[:precision] = precision


      @result = live_search(query, precision)

      respond_to do |wants|
        wants.html  { render :partial => "result" }
        wants.js    { #render :partial => "result",
          render :update do |page|
            page.replace_html("result", :partial => "result")
            # flash "precision" checkbox if less than 30 results unless already selected
            if @result[:packages_num] < 30 && precision != "substrings"
              page.visual_effect(:highlight, "precs", :startcolor => '#ffff99', :endcolor => '#ffffff', :duration => 0.5)
            end
          end
        }
      end

    end
  end



  private

  
  def live_search(query, precision = false)

    result = {
      :start_rendering  => false,
      :query            => "",
      :precision        => "",
      :matched          => nil,
      :tags             => nil,
      :missed           => nil,
      :packages         => nil,
      :packages_num     => 0
    }

    if query.length >= QUERY_MINLENGTH
      if (tag_search_result = tag_search(query, precision))
        result[:query]     = query
        result[:precision] = precision
        result[:matched]   = tag_search_result[:matched]
        result[:tags]      = tag_search_result[:tags]
        result[:missed]    = tag_search_result[:missed]

        if ($packages = packages_only(packages_by_tags(tag_search_result[:tags])))
          $packages = packages_sort($packages, "popularity", "descending")

          result[:packages_num] = $packages.count
          result[:start_rendering] = (result[:packages_num] > 0)

          # OPTIMIZE: Because of the way we get packages by tags from the
          # database and then throw away duplicates, the number of packages
          # returned by packages_by_tags is somewhat non-deterministic.
          # Creating an offset an limit thus isn't a trivial task.
          offset = 0                # OPTIMIZE user defined value
          limit  = PACKAGES_MAXNUM  # OPTIMIZE user defined value

          #result[:packages] = $packages[offset..limit]
          result[:packages] = $packages # ah, what the heck, just show them all
        end

      end
    end

    return result
  end

  def packages_sort(packages, by = "popularity", order = "descending")
    case by
    when "popularity"
      case order
      when "ascending"
        # sort by popularity .............  not nil
        packages = packages.sort_by { |p| (p[:p_old]) ? p[:p_old] : 0 }
      when "descending" # default: descending
        # sort by popularity .............  not nil ................... (descending)
        packages = packages.sort_by { |p| (p[:p_old]) ? p[:p_old] : 0 }.reverse
      else
        nil #idunno
      end
    else
      nil #idunno
    end
  end

  # return uniq'ed and flattened packages[] from a { :tag, :packages } hash
  def packages_only(packages_by_tags)
    if packages_by_tags
      packages_by_tags.collect! { |pt| pt[:packages] }
      return packages_by_tags.flatten.uniq
    end
  end

  # search packages for given tags
  def packages_by_tags(tags, offset = 0, limit = PACKAGES_MAXNUM)
    packages_by_tags = [{
        :tag      => nil,
        :packages => []
    }]

    tags.each do |t|
      # PackageTag
      package_ids = PackageTag.find(:all, {
          :select => :package_id,
          :conditions => { :tag_id => t[:id] }
      })

      package_ids.collect! { |pt| pt[:package_id] }
      package_ids = package_ids.uniq

      # Package
      packages = Package.find(:all, {
          #:order      => "`p_old` DESC",
          :offset     => offset,
          :limit      => limit,
          :select     => "#{:id}, #{:name}, #{:p_old}", # so we'll be able to order by p_old later; TODO: popularity = p_inst = p_vote + p_old
          #:conditions => "#{:id} = #{package_ids.join(" AND #{:id} = ")}",
          :conditions => { :id => package_ids }
      })

      if packages
        packages_by_tags << {
          :tag      => t,
          :packages => packages
        }
      end
    end

    #remove prototype
    packages_by_tags.shift

    return packages_by_tags
  end

  # TODO search tag descriptions
#  def tag_description_search(tags)
#    nil
#  end

  # == Parameters
  #   request: Search request (query)
  #   precision: "full" (default), "substrings"
  def tag_search(request, precision = "full")
    retval = {
      :matched  => [],
      :tags     => [],
      :missed   => []
    }

    # optimization: initialize once
    unless $tags.count > 0
      $tags = Tag.find(:all, {
          :select     => "#{:id}, #{:name}",
          :conditions => { :is_facet => false }, # we don't want to match with facets here
      }) # get all tags from database - we can afford this because they aren't so many and doing string comparisons is much cheaper this way
      $tags = strip_from_tags(/.*todo|.*not-yet-tagged.*|.*not-applicable.*|.*invalid-tag.*/i, $tags)
    end

    # we don't understand these anyways
    stop_words = ["with", "for", "that", "and", "can", "use", "using", "but"]

    request = prepare_request(request)
    request = tokenize(request)
    request = request.uniq
    request = request - stop_words # throw away stop words

    i = 0
    request.each do |r|
      found_one = 0 # span foreach'es
      # full string match
      $tags.each do |tag|
        (tokenize_tag(tag[:name]) - stop_words).each do |t|
          # matching tag in array, so it's also in the DB => put tag into :tags
          case precision
          when "substrings" # match substrings
            if t.include? r
              found_one = 2
            end
          else # default: match full strings
            if t.casecmp(r) == 0
              found_one = 2
            end
          end
        end

        if found_one == 2
          retval[:tags] << tag
          found_one = 1
        end
      end

      # fuzzy matching
      if found_one == 1
        retval[:matched] << r
        found_one = 0
      else
        # no match: put r into :missed
        retval[:missed] << r
      end
    end

    retval[:tags] = retval[:tags].uniq # OPTIMIZE: this is bullocks. first we read them all, then we throw them away again. but can we change this?

    return retval
  end

  def tokenize_tag(tag)
    tag = tag.split(/:+/)
    tag.collect! { |t| tokenize(t) }
    tag = tag.flatten.uniq.compact

    # for now, we want to throw away facets. So if we got a tag that contains no
    # ':'s (i.e. "office"), we end up with a single-element array. that's fine.
    if tag.length == 1
      return Array.[](tag[0])
    else
      tag.shift # remove the first element (facet)
      return tag
    end
  end

  # tokenize: scan for words (\w+) in the input string, returns all elements
  # longer than 3 chars in an array
  def tokenize(string)
    return (string.scan(/[0-9a-zA-Z]+\+*/).map { |t| ((s = t.downcase.singularize).length >= 3) ? s : nil }).compact
  end

  def prepare_request(string)
    return string.mgsub([ # strip: remove leading/trailing whitespace
      [/[,?!]/, ''],      # strip ',?!' chars
      [/[-_]/, ' '],      # substitute '-_' by spaces
    ]).strip.chomp        # remove all kinds of line breaks
  end

# From: O'Reilly's Ruby Cookbook, First Edition, pp. 32f
#  class String
  String.class_eval do
    def mgsub(key_value_pairs=[].freeze)
      regexp_fragments = key_value_pairs.collect { |k,v| k }
      gsub(Regexp.union(*regexp_fragments)) do |match|
        key_value_pairs.detect{ |k,v| k =~ match }[1]
      end
    end
  end

  def strip_from_tags(pattern, tags)
    ret_tags = []

    tags.each do |tag|
      unless tag[:name].index(pattern)
        ret_tags << tag
      end
    end

    return ret_tags
  end
end
