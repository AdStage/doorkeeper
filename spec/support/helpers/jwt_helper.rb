RSpec::Matchers.define :be_a_valid_jwt do |expected|
  match do |actual|
    begin
      Doorkeeper.read_claims(actual)
      true
    rescue
      false
    end
  end
end

module JWTHelper
  def jwt_access_grant_should_have_scopes(*args)
    grant = extract_url_access_grant
    expect(Doorkeeper::OAuth::Scopes.from_string(grant['scopes'])).to eq(
      Doorkeeper::OAuth::Scopes.from_array(args)
    )
  end

  def jwt_access_grant_should_exist_for(client, resource_owner)
    grant = extract_url_access_grant
    expect(grant['aud']).to eq(client.id)
    grant['sub'] == resource_owner.id
  end

  def jwt_grant_exists(options)
    aud = options.delete(:application).try(:id)
    options.merge(aud: aud)
    @authorization = Doorkeeper.build_claims(options)
  end

  def jwt_access_grant_should_not_exist
    expect { extract_url_access_grant }.to raise_error
  end

  def extract_url_access_grant
    grant = current_params['code'] || current_uri.path.split('/').last
    Doorkeeper.read_claims(grant)
  end
end

RSpec.configuration.send :include, JWTHelper
