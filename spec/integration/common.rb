def print_wait(string)
  puts "------------------------"
  puts string
  puts "-"
  puts "Then press Enter to continue"
  io = IO.new(IO.sysopen(`tty`.chomp("\n"), 'w+'))
  # byebug
  io.gets
end

def create_events(event_count, with_time: false, name: "Test event")
  Nexo.logger.info("Creating #{event_count} events")
  today = Time.zone.today
  event_count.times.map do |i|
    index = i

    offset = index % 5
    date = today + offset.days

    if with_time
      time_from = "16:00"
      time_to = "18:30"
      event = Event.create(date_from: date, date_to: date, time_from:, time_to:, summary: "#{name} #{index}")
    else
      event = Event.create(date_from: date, date_to: date + 1, summary: "#{name} #{index}")
    end

    Nexo.logger.info("Event created: #{event}")
    Nexo::EventReceiver.new.synchronizable_created(event)

    event
  end
end

def get_folder(external_identifier: nil)
  folder = Nexo::Folder.kept.first
  Nexo.logger.info("Folder found: #{folder}") if folder.present?

  unless folder.present?
    integration = Nexo::Integration.first
    if external_identifier.present?
      folder = Nexo::Folder.create!(
        integration:,
        sync_direction: :sync_bidirectional,
        external_identifier:,
        nexo_protocol: :calendar,
        name: "Nexo Integration Test",
        description: "Automatically created calendar for Nexo Automated Test"
      )
      Nexo.logger.info("Created folder WITH EXTERNAL ID: #{folder}")
      DummyFolderRule.create!(folder:, sync_policy: :include, search_regex: ".*")
    else
      folder = Nexo::Folder.create!(
        integration:,
        sync_direction: :sync_bidirectional,
        external_identifier:,
        nexo_protocol: :calendar,
        name: "Nexo Integration Test",
        description: "Automatically created calendar for Nexo Automated Test"
      )
      DummyFolderRule.create!(folder:, sync_policy: :include, search_regex: ".*")
      Nexo.logger.info("Created folder: #{folder}")
      Nexo::EventReceiver.new.folder_changed(folder)
      sleep 3
    end
  end

  folder
end

def build_client(folder)
  service = Nexo::ServiceBuilder.instance.build_protocol_service(folder)
  service.send(:client)
end

def get_event(element)
  client = build_client(element.folder)
  client.get_event(element.folder.external_identifier, element.uuid)
end

def exec_test(test)
  name = test[:name]
  "Starting test: #{name}".tap {  Nexo.logger.info(_1); puts _1 }
  begin
    test[:block].call
  ensure
    clear_remote_events
    puts "Events cleared"
  end
end

def destroy_elements
  Nexo.logger.info("Destroying elements and events")
  Nexo::Element.destroy_all
  Event.destroy_all
end

def destroy_all_folders
  Nexo.logger.info("Destroying folders")
  DummyFolderRule.destroy_all
  Nexo::Folder.destroy_all
end

def create_other_folder
  integration = Nexo::Integration.first
  folder = Nexo::Folder.create!(
    integration:,
    nexo_protocol: :calendar,
    name: "Nexo Alternate folder",
    description: "Automatically created calendar for Nexo Automated Test"
  )
  DummyFolderRule.create!(folder:, sync_policy: :include, search_regex: ".*")
  Nexo.logger.info("Created folder: #{folder}")
  Nexo::EventReceiver.new.folder_changed(folder)
end

def destroy_folder(folder)
  Nexo.logger.info("Destroying folder locally and remotelly: #{folder}")
  folder.discard!
  Nexo::EventReceiver.new.folder_discarded(folder)
end

def clear_all
  folder = Nexo::Folder.kept.first
  if folder.present?
    destroy_folder(folder)
  end
  sleep 2
  destroy_elements
  destroy_all_folders
end

def clear_remote_events
  Nexo.logger.info "Clearing remote events"
  folder = get_folder
  service = Nexo::ServiceBuilder.instance.build_protocol_service(folder)
  client = service.send(:client)
  cid = folder.external_identifier
  events = client.list_events(cid).items
  events.each do |event|
    client.delete_event(cid, event.id)
  end
end

=begin

# run_tests(focus: true)
run_tests(focus: false)
# clear_remote_events
# destroy_elements

# folder = get_folder
# ev = create_events(1, with_time: false)

# folder = get_folder
# Nexo::EventReceiver.new.folder_changed(folder)

#
#
# create_other_folder
# destroy_all_folders
# clear_all
# get_folder
# ev = create_events(1, with_time: false)

# destroy_elements
# destroy_all_folders

# event = Event.first
# element = event.nexo_elements.first
# folder = element.folder
# cal_id = folder.external_identifier
# service = Nexo::ServiceBuilder.instance.build_protocol_service(folder)
# client = service.send(:client)
# byebug

# event = Event.last
# event.update(summary: "asd 10")
# event.increment_sequence!

# Nexo::EventReceiver.new.synchronizable_updated(event)
# element = event.nexo_elements.first
# evd = ActiveSupport::HashWithIndifferentAccess.new(lev.payload)
# Google::Apis::CalendarV3::Event.new(**evd)
# lev.update(sequence: event.sequence)

exit

event.update(summary: "asd 10")
Nexo::EventReceiver.new.synchronizable_updated(event)
Nexo::UpdateRemoteResourceJob.perform_later(element)
Nexo::FetchRemoteResourceJob.perform_now(element)
lev.update(sequence: event.sequence)


# clear_all


Nexo.logger.info "end integration test"
exit

# folder.elements.kept.each do |el|
#   event = el.synchronizable
#   aux = event.date_from
#   event.date_from = aux - 1.week
#   event.date_to = aux - 1.week
#   event.save
#   Nexo::EventReceiver.new.synchronizable_updated(event)
# end

# sleep 2
# folder.elements.kept.each do |el|
#   event = el.synchronizable
#   event.update(summary: "Test event 2 #{rand(20..99)}")
#   Nexo::EventReceiver.new.synchronizable_updated(event)
# end




folder = element.folder
cal_id = folder.external_identifier
service = Nexo::ServiceBuilder.instance.build_protocol_service(folder)
client = service.send(:client)

event = Event.first
element = event.nexo_elements.first

evid = element.uuid
rev = client.get_event(cal_id, evid)
rev.sequence

eveu=service.send(:build_event, event)
eveu.summary = "Dummy 101"
etag = '"3497081468864670"'
options = Google::Apis::RequestOptions.new(header: { "If-Match" => etag })
res = client.update_event(folder.external_identifier, evid, eveu, options: options)
# rubocop:enable all

=end
