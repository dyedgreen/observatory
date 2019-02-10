require "sqlite3"


$db = SQLite3::Database.new "./data/url.db"

# Initialize database
$db.execute <<-SQL
  create table if not exists users (
    id integer primary key autoincrement,
    name varchar(64) unique not null,
    secret varchar(32) not null,
    last_login integer not null
  );
SQL
