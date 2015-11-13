class IntroduceJwtTokens < ActiveRecord::Migration
  def up
    add_column :oauth_access_tokens, :jwt_identifier, :string
    add_column :oauth_access_tokens, :jwt_refresh_identifier, :string
    Doorkeeper::AccessToken.reset_column_information
    Doorkeeper::AccessToken.find_each do |token|
      token.update_attribute(:jwt_identifier, token.id.to_s)
      token.update_attribute(:jwt_refresh_identifier, token.id.to_s)
    end
    add_index :oauth_access_tokens, :jwt_identifier, unique: true
    add_index :oauth_access_tokens, :jwt_refresh_identifier, unique: true

    add_column :oauth_access_grants, :jwt_identifier, :string
    Doorkeeper::AccessGrant.reset_column_information
    Doorkeeper::AccessGrant.find_each do |token|
      token.update_attribute(:jwt_identifier, token.id.to_s)
    end
    add_index :oauth_access_grants, :jwt_identifier, unique: true
  end

  def down
    remove_column :oauth_access_tokens, :jwt_identifier
    remove_column :oauth_access_tokens, :jwt_refresh_identifier
    remove_column :oauth_access_grants, :jwt_identifier
  end
end
