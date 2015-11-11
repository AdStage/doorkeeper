class EncryptClientSecrets < ActiveRecord::Migration
  def up
    add_column :oauth_applications, :encrypted_secret, :text
    add_column :oauth_applications, :encrypted_secret_iv, :text

    Doorkeeper::Application.reset_column_information
    Doorkeeper::Application.find_each do |application|
      iv, encrypted = Doorkeeper.encrypt(application[:secret])
      application.update_attribute(:encrypted_secret, encrypted)
      application.update_attribute(:encrypted_secret_iv, iv)
    end
    remove_column :oauth_applications, :secret
  end

  def down
    add_column :oauth_applications, :secret, :string
    Doorkeeper::Application.reset_column_information
    Doorkeeper::Application.find_each do |application|
      plaintext = Doorkeeper.decrypt(
        application[:encrypted_secret_iv],
        application[:encrypted_secret]
      )
      application.update_attribute(:secret, plaintext)
    end
    remove_column :oauth_applications, :encrypted_secret
    remove_column :oauth_applications, :encrypted_secret_iv
  end
end
