class CreateDoorkeeperTables < ActiveRecord::Migration
  def change
    create_table :oauth_applications do |t|
      t.string  :name,             null: false
      t.string  :uid,              null: false
      t.text    :encrypted_secret, null: false
      t.text    :redirect_uri,     null: false
      t.string  :scopes,           null: false, default: ''
      t.timestamps
    end
    add_index :oauth_applications, :uid, unique: true

    create_table :oauth_access_tokens do |t|
      t.integer  :resource_owner_id
      t.integer  :application_id

      t.string   :jwt_identifier,             null: false
      t.string   :jwt_refresh_identifier

      t.integer  :expires_in
      t.datetime :revoked_at
      t.datetime :created_at,        null: false
      t.string   :scopes
    end
    add_index :oauth_access_tokens, :resource_owner_id
    add_index :oauth_access_tokens, :jwt_identifier, unique: true
    add_index :oauth_access_tokens, :jwt_refresh_identifier, unique: true

  end
end
