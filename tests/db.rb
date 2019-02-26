require "test/unit"

require "sqlite3"
require "./classes/db"


class TestDb < Test::Unit::TestCase

  def test_exist
    assert_equal SQLite3::Database, $db.class
  end

  def test_tables
    expected = ["users", "urls", "redirects"]
    tables = $db.execute <<-SQL
      select name from sqlite_master where type = 'table' and name not like 'sqlite_%'
    SQL
    tables.each do |row|
      assert_true expected.include?(row.first)
    end
    assert_equal tables.count, expected.count
  end

end
