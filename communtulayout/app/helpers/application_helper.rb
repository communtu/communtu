module ApplicationHelper
  def navi_link(text,img)
    "<div class='button'>#{image_tag(img)} <span class='navi_text'>#{text}</span></div>"
  end
end
