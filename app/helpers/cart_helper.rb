module CartHelper
  def packages_not_found err
    t(:controller_cart_2, :message => err, :endOfSentence => link_to("/home/new_repository",t(:controller_cart_3)))
  end
end
