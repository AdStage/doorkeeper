require 'doorkeeper/version'
require 'doorkeeper/engine'
require 'doorkeeper/config'

require 'doorkeeper/errors'
require 'doorkeeper/server'
require 'doorkeeper/request'
require 'doorkeeper/validations'

require 'doorkeeper/oauth/authorization/code'
require 'doorkeeper/oauth/authorization/token'
require 'doorkeeper/oauth/authorization/uri_builder'
require 'doorkeeper/oauth/helpers/scope_checker'
require 'doorkeeper/oauth/helpers/uri_checker'
require 'doorkeeper/oauth/helpers/unique_token'

require 'doorkeeper/oauth/scopes'
require 'doorkeeper/oauth/error'
require 'doorkeeper/oauth/code_response'
require 'doorkeeper/oauth/token_response'
require 'doorkeeper/oauth/error_response'
require 'doorkeeper/oauth/pre_authorization'
require 'doorkeeper/oauth/request_concern'
require 'doorkeeper/oauth/authorization_code_request'
require 'doorkeeper/oauth/refresh_token_request'
require 'doorkeeper/oauth/password_access_token_request'
require 'doorkeeper/oauth/client_credentials_request'
require 'doorkeeper/oauth/code_request'
require 'doorkeeper/oauth/token_request'
require 'doorkeeper/oauth/client'
require 'doorkeeper/oauth/token'
require 'doorkeeper/oauth/invalid_token_response'
require 'doorkeeper/oauth/forbidden_token_response'

require 'doorkeeper/models/concerns/scopes'
require 'doorkeeper/models/concerns/expirable'
require 'doorkeeper/models/concerns/revocable'
require 'doorkeeper/models/concerns/accessible'

require 'doorkeeper/models/access_grant_mixin'
require 'doorkeeper/models/access_token_mixin'
require 'doorkeeper/models/application_mixin'

require 'doorkeeper/helpers/controller'

require 'doorkeeper/rails/routes'
require 'doorkeeper/rails/helpers'

require 'doorkeeper/orm/active_record'

require 'openssl'
require 'base64'
require 'jwt'

module Doorkeeper
  def self.configured?
    @config.present?
  end

  def self.database_installed?
    [AccessToken, AccessGrant, Application].all? { |model| model.table_exists? }
  end

  def self.installed?
    configured? && database_installed?
  end

  def self.authenticate(request, methods = Doorkeeper.configuration.access_token_methods)
    OAuth::Token.authenticate(request, *methods)
  end

  # TODO:
  # Where do these belong?
  def self.secure_compare(a, b)
    JWT.secure_compare(a, b)
  end
  def self.encrypt(plaintext)
    cipher = OpenSSL::Cipher::AES.new(256, :CBC)
    cipher.encrypt
    cipher.key = configured_secret
    iv = cipher.random_iv
    encrypted = cipher.update(plaintext) + cipher.final
    iv_64 = [iv].pack('m')
    encrypted_64 = [encrypted].pack('m')
    [iv_64, encrypted_64]
  end

  def self.configured_secret
    secret = Doorkeeper.configuration.encryption_secret
    if secret
      secret
    else
      @random ||= SecureRandom.hex(36)
      warn "Falling back to randomly configured secret: #{@random}"
      @random
    end
  end

  def self.decrypt(iv_64, ciphertext_64)
    iv = iv_64.unpack('m')[0]
    ciphertext = ciphertext_64.unpack('m')[0]
    cipher = OpenSSL::Cipher::AES.new(256, :CBC)
    cipher.decrypt
    cipher.key = configured_secret
    cipher.iv = iv
    cipher.update(ciphertext) + cipher.final
  end
end
