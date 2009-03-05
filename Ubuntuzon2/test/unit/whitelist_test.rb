require 'test_helper'

class WhitelistTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  test "the truth" do
    assert true
  end
  
  test "the fixtures" do
    assert_not_nil Whitelist.find_by_id(1)
  end
end
