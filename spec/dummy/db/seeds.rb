# ActiveRecord::FixtureSet.create_fixtures(["#{::Rails.root}/../fixtures"], ["events", "users", "nexo/clients" , "nexo/integrations" , "nexo/tokens" , "nexo/folders"])

ActiveRecord::FixtureSet.create_fixtures(["#{::Rails.root}/../fixtures"], ["events", "users"])
Nexo::Engine.load_seed
