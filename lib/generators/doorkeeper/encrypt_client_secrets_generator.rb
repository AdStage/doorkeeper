require 'rails/generators/active_record'

class Doorkeeper::EncryptClientSecretsGenerator < Rails::Generators::Base
  include Rails::Generators::Migration
  source_root File.expand_path('../templates', __FILE__)
  desc 'Copies ActiveRecord migrations to handle upgrade to encrypted secrets'

  def self.next_migration_number(path)
    ActiveRecord::Generators::Base.next_migration_number(path)
  end

  def application_scopes
    if oauth_applications_exists? && !client_secret_encrypted?
      migration_template(
        'encrypt_client_secrets.rb',
        'db/migrate/encrypt_client_secrets.rb'
      )
      inject_into_file 'config/initializers/doorkeeper.rb', after: "Doorkeeper.configure do\n" do
        <<-RUBY
  # This string is used to encrypt client application secrets at rest
  # in the database. Changing it will invalidate all secrets in the
  # database. It is recommended you set this secret outside your source
  # repository, if possible. Here it can be set with an environment
  # variable DOORKEEPER_SECRET for Heroku-like configuration
  encryption_secret (ENV['DOORKEEPER_SECRET'] || "#{SecureRandom.hex(36)}")
        RUBY
      end
    else
      warn "Either doorkeeper generator has not run, or migration for encryption has run"
      warn "Verify your database schema requires this migration."
    end
  end

  private

  def client_secret_encrypted?
    ActiveRecord::Base.connection.column_exists?(
      :oauth_applications,
      :encrypted_secret
    )
  end

  # Might be running this before install
  def oauth_applications_exists?
    ActiveRecord::Base.connection.table_exists? :oauth_applications
  end
end
