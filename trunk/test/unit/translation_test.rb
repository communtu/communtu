require File.dirname(__FILE__) + '/../test_helper'

class TranslationTest < ActiveSupport::TestCase

    fixtures :translations

  def test_new_translation
    t = Translation.new_translation("Communtu")
    assert_equal t.translatable_id, 3
    assert_equal t.contents, "Communtu"
  end

  def test_duplication_translation
    t1 = Translation.new_translation("Communtu")
    t2 = Translation.new_translation("Communtu")
    assert_equal t1.translatable_id, t2.translatable_id
  end

end
