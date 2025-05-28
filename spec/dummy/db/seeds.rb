FactoryBot.create_list(:event, 2)
FactoryBot.create_list(:user, 1)
Nexo::Engine.load_seed
