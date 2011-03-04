# (c) 2008-2010 by Verein Allgemeinbildung e.V., Bremen, Germany
# use, modification or distribution only with permission of the copyright holder

module DownloadHelper
  
    def check_bundles root
      root.default_bundles.map do |b|
         "$('post_#{b.id}').checked=$('categories_#{root.id.to_s}').checked"
      end.join("; ")
    end

  
    def paths(p)
      case p
        when "install" 
        then [{:name => I18n.t(:download_area), :action => "start"},
              {:name => I18n.t(:model_user_profile_tabz_1), :action => "selection"},
              {:name => I18n.t(:model_user_profile_tabz_4), :action => "settings"},
              {:name => I18n.t(:add_sources), :action => "prepare_install_sources"},
              {:name => I18n.t(:controller_suggestion_15), :action => "installation"}]
        when "cd" 
        then [{:name => I18n.t(:download_area), :action => "start"},
              {:name => I18n.t(:model_user_profile_tabz_1), :action => "selection"},
              {:name => I18n.t(:model_user_profile_tabz_4), :action => "settings"},
              {:name => I18n.t(:create_livecd), :action => "livecd"},
              {:name => I18n.t(:wait_for_email), :action => "cd_email"},
              {:name => I18n.t(:cd_ready), :action => "current_cd"}]
        when "bundle_cd"
        then [{:name => I18n.t(:model_user_meta_tabz_3), :action => "/metapackages"},
              {:name => I18n.t(:model_user_profile_tabz_4), :action => "/download/settings"},
              {:name => I18n.t(:bundle_to_livecd1), :action => "/download/bundle_to_livecd"},
              {:name => I18n.t(:wait_for_email), :action => "/download/create_livecd_from_bundle"},
              {:name => I18n.t(:cd_ready), :action => "/download/current_cd"}]
        when "mybundle_cd"
        then [{:name => I18n.t(:model_user_meta_tabz_0), :action => "/metapackages/index_mine"},
              {:name => I18n.t(:model_user_profile_tabz_4), :action => "/download/settings"},
              {:name => I18n.t(:bundle_to_livecd1), :action => "/download/bundle_to_livecd"},
              {:name => I18n.t(:wait_for_email), :action => "/download/create_livecd_from_bundle"},
              {:name => I18n.t(:cd_ready), :action => "/download/current_cd"}]
        when "usb"
        then [{:name => I18n.t(:download_area), :action => "start"},
              {:name => I18n.t(:model_user_profile_tabz_1), :action => "selection"},
              {:name => I18n.t(:model_user_profile_tabz_4), :action => "settings"},
              {:name => I18n.t(:create_iso), :action => "livecd"},
              {:name => I18n.t(:wait_for_email), :action => "cd_email"},
              {:name => I18n.t(:iso_ready), :action => "current_cd"}
             # {:name => "USB-Stick erstellen", :action => "usb"}
             ]
        else nil
      end  
  end           
  

end
