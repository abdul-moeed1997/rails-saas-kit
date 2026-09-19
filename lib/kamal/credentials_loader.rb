# frozen_string_literal: true

require "active_support/encrypted_configuration"
require "active_support/core_ext/hash/keys"

module Kamal
  class CredentialsLoader
    ROOT = File.expand_path("../..", __dir__)

    def self.load
      new.load
    end

    def load
      credentials.config.fetch(:kamal) do
        raise KeyError, <<~ERROR
          Missing :kamal section in config/credentials/production.yml.enc.

          Add your server IPs and deploy settings there, then retry:

            EDITOR="vim" bin/rails credentials:edit --environment production
        ERROR
      end.deep_symbolize_keys
    end

    private

      def credentials
        @credentials ||= ActiveSupport::EncryptedConfiguration.new(
          config_path: File.join(ROOT, "config/credentials/production.yml.enc"),
          key_path: File.join(ROOT, "config/credentials/production.key"),
          env_key: "RAILS_MASTER_KEY",
          raise_if_missing_key: true
        )
      end
  end
end
