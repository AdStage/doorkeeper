require 'rails/generators/active_record'

class Doorkeeper::IntroduceJwtTokensGenerator < Rails::Generators::Base
  include Rails::Generators::Migration
  source_root File.expand_path('../templates', __FILE__)
  desc 'Copies ActiveRecord migrations to handle upgrade to jwt tokens'

  def self.next_migration_number(path)
    ActiveRecord::Generators::Base.next_migration_number(path)
  end

  def application_scopes
    if oauth_applications_exists? && !jwt_identifier_exists?
      migration_template(
        'introduce_jwt_tokens.rb',
        'db/migrate/introduce_jwt_tokens.rb'
      )
    else
      warn "Either doorkeeper generator has not run, or migration for JWT has already run"
      warn "Verify your database schema requires this migration."
    end
  end

  private

  def jwt_identifier_exists?
    ActiveRecord::Base.connection.column_exists?(
      :oauth_access_tokens,
      :jwt_identifier
    )
  end

  # Might be running this before install
  def oauth_applications_exists?
    ActiveRecord::Base.connection.table_exists? :oauth_applications
  end
end
