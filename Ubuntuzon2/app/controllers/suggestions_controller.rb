class SuggestionsController < ApplicationController

  def show
    unless logged_in?
      redirect_to '/login'
    end

    @account = @current_account
    getSuggestion
  end

  def getSuggestion
    # TODO: Implement a more sophisticated suggestion algorithm

    @suggested_packages = []
    @fp_measure = []

    last_uploads = Upload.find :all, :limit => "0,1", :select => 'id', :order => 'id DESC', :conditions => { :account_id => @account }
    currentPackages = Package.find :all, :joins => :configurations, :select => 'packages.name', :conditions => [ "configurations.upload_id = ? AND configurations.account_id = ?", last_uploads[0], @account ]

    rules = Suggestion.all
    results = []
    rules.each_index do |i|
      rArr = rules[i].rule.split(/\s/)
      mapped =  rArr - currentPackages.map(&:name)
      if mapped.length == 1
        duplicated = false
        results.each do |r|
          if r[:name] == mapped[0]
            duplicated = true
          end
        end
        unless duplicated
          results.push({ :name => mapped[0], :rating => rules[i].rating })
        end
      end
    end
    results.sort! { |a,b| b[:rating] <=> a[:rating] }
    results.each do |r|
      if (r = Package.find_by_name(r[:name])) != nil
        @suggested_packages.push(r)
        @fp_measure.push(r[:rating])
      end
    end

    @userrated_packages = Package.all
    @userrated_packages.sort! { |a,b| b.rating <=> a.rating }
    @userrated_packages = @userrated_packages[0..10]
  end

end
