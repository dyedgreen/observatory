require "sqlite3"


$db = SQLite3::Database.new "./data/database.db"

# Initialize database

$db.execute <<-SQL
  PRAGMA foreign_keys = ON;
SQL

$db.execute <<-SQL
  create table if not exists users (
    id integer primary key autoincrement,
    name varchar(64) unique not null,
    secret varchar(32) not null,
    last_login integer not null
  );
SQL

$db.execute <<-SQL
  create table if not exists urls (
    id integer primary key autoincrement,
    public_id varchar(8) unique not null,
    target text not null,
    created integer not null
  );
SQL

$db.execute <<-SQL
  create table if not exists redirects (
    id integer primary key autoincrement,
    resource integer not null,
    created integer not null,
    ref text,
    user_agent text,
    foreign key (resource) references urls(id)
  );
SQL

$db.execute <<-SQL
  create table if not exists site_whitelist (
    id integer primary key autoincrement,
    host text unique not null,
    consent_token varchar(16) unique not null
  );
SQL

$db.execute <<-SQL
  create table if not exists visits (
    id integer primary key autoincrement,
    resource integer not null,
    created integer not null,
    ref text,
    foreign key (resource) references site_whitelist(id)
  );
SQL

$db.execute <<-SQL
  create table if not exists pages (
    id integer primary key autoincrement,
    site integer not null,
    path text unique not null,
    foreign key (site) references site_whitelist(id)
  );
SQL

$db.execute <<-SQL
  create table if not exists page_views (
    id integer primary key autoincrement,
    page integer not null,
    day integer not null,
    count integer not null,
    foreign key (page) references pages(id)
  );
SQL
