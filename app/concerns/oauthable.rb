module Oauthable
  extend ActiveSupport::Concern

  included do |base|
    @valid_oauth_providers = :all
    validate :validate_service
  end

  def oauthable?
    true
  end

  def validate_service
    if !service
      errors.add(:service, :blank)
    end
  end

  def valid_services_for(user)
    if valid_oauth_providers == :all
      user.available_services
    else
      user.available_services.where(provider: valid_oauth_providers)
    end
  end

  def valid_oauth_providers
    self.class.valid_oauth_providers
  end

  module ClassMethods
    def valid_oauth_providers(*providers)
      return @valid_oauth_providers if providers == []
      @valid_oauth_providers = providers
    end
  end
end
