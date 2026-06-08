session_domain = case Rails.env
when "development" then ".lvh.me"
when "test" then ".example.com"
else :all
end

Rails.application.config.session_store :cookie_store,
  key: "_rails_saas_kit_session_v2",
  domain: session_domain,
  same_site: :lax
