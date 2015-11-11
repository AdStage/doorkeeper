class EncryptClientSecrets < ActiveRecord::Migration
  def up
    add_column :oauth_applications, :encrypted_secret, :text

    Doorkeeper::Application.reset_column_information
    Doorkeeper::Application.find_each do |application|
      encrypted = Doorkeeper.encrypt(application[:secret])
      application.update_attribute(:encrypted_secret, encrypted)
    end
    remove_column :oauth_applications, :secret
  end

  def down
    add_column :oauth_applications, :secret, :string
    Doorkeeper::Application.reset_column_information
    Doorkeeper::Application.find_each do |application|
      plaintext = Doorkeeper.decrypt(
        application[:encrypted_secret]
      )
      application.update_attribute(:secret, plaintext)
    end
    remove_column :oauth_applications, :encrypted_secret
  end
end
