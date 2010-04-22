require 'test_helper'

class PackageTagTest < ActiveSupport::TestCase
  test "new empty package_tag" do
    package_tag = PackageTag.new()

    assert_false package_tag.save # validates presence of package_id and tag_id
  end
end
