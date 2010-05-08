require 'test_helper'


class PackageTest < ActiveSupport::TestCase
  # this really is a Rails function, if save doesn't work it's not our fault..
  # package cannot be empty
  test "new empty package" do
    package = Package.new()

    assert !package.save # validates presence of name
  end

  # this really is a rails function, if save doesn't work it's not our fault..
  # inserted package equals found one
  test "new package" do
    package = Package.new(:name => "thisone")
    package.save

    db_package = Package.find_by_name("thisone")

    assert_equal package, db_package
  end

  test "duplicate package" do
    assert !Package.create(:name => "thisone")
  end

  # this really is a rails function, if create doesn't work it's beyond our responsibilities
  # after insertion, there is one more package in the db
  test "package count" do
    i = Package.count
    i += 1

    package = Package.create( { :name => "does not matter" } )
    
    assert_equal Package.count, i
  end

  
end
