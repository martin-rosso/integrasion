module Nexo
  ActiveRecord::FixtureSet.create_fixtures(["#{::Rails.root}/../fixtures"], ["events", "users", "nexo/clients" , "nexo/integrations" , "nexo/tokens" , "nexo/folders" , "nexo/elements" , "nexo/element_versions"])

  Nexo::Token.first.update(environment: "development")
end
