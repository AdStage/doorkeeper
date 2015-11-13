module Doorkeeper
  module AccessGrantMixin
    extend ActiveSupport::Concern

    include OAuth::Helpers
    include Models::Expirable
    include Models::Revocable
    include Models::Accessible
    include Models::Scopes
    include ActiveModel::MassAssignmentSecurity if defined?(::ProtectedAttributes)

    included do
      belongs_to :application, class_name: 'Doorkeeper::Application', inverse_of: :access_grants

      if respond_to?(:attr_accessible)
        attr_accessible :resource_owner_id, :application_id, :expires_in, :redirect_uri, :scopes
      end

      validates :resource_owner_id, :application_id, :jwt_identifier, :expires_in, :redirect_uri, presence: true
      validates :jwt_identifier, uniqueness: true

      before_validation :generate_jti, on: :create
    end

    def token
      Doorkeeper.build_claims(
        aud: application_id,
        sub: resource_owner_id,
        jti: jwt_identifier,
        exp: created_at.to_i + expires_in,
        scopes: scopes,
        redirect_uri: redirect_uri
      )
    end

    module ClassMethods
      def by_token(token)
        claims = Doorkeeper.read_claims(token)
        # Force exact match with the claims to prevent/detect tampering
        where(
          jwt_identifier: claims['jti'],
          application_id: claims['aud'],
          resource_owner_id: claims['sub'],
          scopes: claims['scopes'],
          redirect_uri: claims['redirect_uri']
        ).limit(1).to_a.first
      rescue JWT::DecodeError
        nil
      end
    end

    private

    def generate_jti
      jti = UniqueToken.generate_jti
      while duplicate = self.class.find_by_jwt_identifier(jti)
        jti = UniqueToken.generate_jti
      end
      self[:token] = self.jwt_identifier = jti
    end
  end
end
