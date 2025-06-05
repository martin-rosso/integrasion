# rubocop:disable all
Nexo.logger.info("-------------------------")
Nexo.logger.info("Starting integration test. **** Implementar con: https://cucumber.io/")
Nexo.logger.info("-------------------------")

def print_wait(string)
    puts "------------------------"
    puts string
    puts "-"
    puts "Then press Enter to continue"
    gets
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

def get_folder
  integration = Nexo::Integration.first
  folder = Nexo::Folder.kept.first
  Nexo.logger.info("Folder found: #{folder}") if folder.present?

  unless folder.present?
    folder = Nexo::Folder.create!(
      integration:,
      nexo_protocol: :calendar,
      name: "Nexo Automated Test",
      description: "Automatically created calendar for Nexo Automated Test"
    )
    DummyFolderRule.create!(folder:, sync_policy: :include, search_regex: ".*")
    Nexo.logger.info("Created folder: #{folder}")
    Nexo::EventReceiver.new.folder_changed(folder)
    sleep 3
  end

  folder
end

def destroy_folder(folder)
  Nexo.logger.info("Destroying folder locally and remotelly: #{folder}")
  folder.discard!
  Nexo::EventReceiver.new.folder_discarded(folder)
end

def clear_all
  folder = get_folder
  destroy_folder(folder)
  sleep 2
  destroy_elements
  destroy_all_folders
end

def clear_remote_events
  folder = get_folder
  service = Nexo::ServiceBuilder.instance.build_protocol_service(folder)
  client = service.send(:client)
  cid = folder.external_identifier
  events = client.list_events(cid).items
  events.each do |event|
    client.delete_event(cid, event.id)
  end
end

def build_client(folder)
  service = Nexo::ServiceBuilder.instance.build_protocol_service(folder)
  service.send(:client)
end

def get_event(element)
  client = build_client(element.folder)
  client.get_event(element.folder.external_identifier, element.uuid)
end

@defined_tests = []

def xit(name)
  # skip test
end

def fit(name, &block)
  # skip test
  @defined_tests << { name:, block:, focus: true }
end

def it(name, &block)
  @defined_tests << { name:, block: }
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

def run_tests(focus: false)
  @defined_tests.each_with_index do |test, index|
    next if focus && !test[:focus]

    exec_test(test)
  end
end

# *************************************************************************
# *************************************************************************
# *************************************************************************

it "The event with time is blocking/busy. The all-day event, non-blocking/free" do
  create_events(1, with_time: true)
  create_events(1, with_time: false)

  print_wait "The event with time is blocking/busy. The all-day event, non-blocking/free"
end

it "Update to event summary" do
  folder = get_folder
  event = create_events(1, with_time: false, name: "To be updated").first

  print_wait "Check the calendar event is created with name: 'To be updated'"

  event.update(summary: "The name has changed!")
  Nexo::EventReceiver.new.synchronizable_updated(event)

  print_wait "Check the new name of the event"
end

it "Update to conflicted event fails" do
  folder = get_folder
  event = create_events(1, with_time: false, name: "To be conflicted").first

  print_wait <<~STR
    Check the calendar event is created with name: 'To be conflicted'
    Then modify the event, by changing the date or whatever attribute of it
  STR

  event.update(summary: "The event must not be updated")
  Nexo::EventReceiver.new.synchronizable_updated(event)

  print_wait "Check that the job failed with Nexo::Errors::ConflictingRemoteElementChange"
end

it "Delete to conflicted event fails" do
  folder = get_folder
  event = create_events(1, with_time: false, name: "To be conflicted").first

  print_wait <<~STR
    Check the calendar event is created with name: 'To be conflicted'
    Then modify the event, by changing the date or whatever attribute of it
  STR

  element = event.nexo_elements.first
  element.flag_for_removal!(:synchronizable_destroyed)
  Nexo::EventReceiver.new.synchronizable_updated(event)

  print_wait "Check that the job failed with Nexo::Errors::ConflictingRemoteElementChange"
end

it "Remote update doesn't change the sequence" do
  folder = get_folder
  event = create_events(1, with_time: false, name: "To be updated on Google Calendar").first

  print_wait <<~STR
    Check the calendar event is created with name: 'To be updated on Google Calendar'
  STR

  element = event.nexo_elements.first
  rev = get_event(element)

  print_wait <<~STR
    The event has: Sequence: #{rev.sequence}. Etag: #{rev.etag}

    Now modify the event, by changing the SUMMARY
  STR

  rev2 = get_event(element)

  print_wait "Now the event has: Sequence: #{rev2.sequence}. Etag: #{rev2.etag}"

  if rev.sequence != rev2.sequence
    raise "sequence should not have changed"
  end

  if rev.etag == rev2.etag
    raise "etag should have changed"
  end
end

it "Remote update does change the sequence" do
  folder = get_folder
  event = create_events(1, with_time: false, name: "To be updated on Google Calendar").first

  print_wait "Check the calendar event is created with name: 'To be updated on Google Calendar'"

  element = event.nexo_elements.first
  rev = get_event(element)

  puts "The event has: Sequence: #{rev.sequence}. Etag: #{rev.etag}"

  print_wait "Now modify the event, by changing the DATE"

  rev2 = get_event(element)

  print_wait "Now the event has: Sequence: #{rev2.sequence}. Etag: #{rev2.etag}"

  unless (rev.sequence + 1) == rev2.sequence
    raise "sequence should have changed by 1"
  end

  if rev.etag == rev2.etag
    raise "etag should have changed"
  end
end

it "if we send dont send the secuence, it gets updated by google" do
  folder = get_folder
  event = create_events(1, with_time: false, name: "To be updated without sequence").first

  print_wait "Check the calendar event is created with name: 'To be updated without sequence'"

  event.summary = "One week before"
  event.date_from = event.date_from - 1.week
  element = event.nexo_elements.first
  service = Nexo::ServiceBuilder.instance.build_protocol_service(folder)
  client = service.send(:client)
  revent = service.send(:build_event, event)


  revent.sequence = nil
  response = client.update_event(element.folder.external_identifier, element.uuid, revent)
  unless response.sequence == 1
    raise "google should have incremented the sequence"
  end
end

it "if we send a fixed sequence it gets accepted, and an invalid one gets rejected" do
  folder = get_folder
  event = create_events(1, with_time: false, name: "To be updated without sequence").first

  print_wait "Check the calendar event is created with name: 'To be updated without sequence'"

  event.summary = "One week before"
  event.date_from = event.date_from - 1.week
  element = event.nexo_elements.first
  service = Nexo::ServiceBuilder.instance.build_protocol_service(folder)
  client = service.send(:client)
  revent = service.send(:build_event, event)

  revent.sequence = 9
  response = client.update_event(element.folder.external_identifier, element.uuid, revent)
  unless response.sequence == 9
    raise "google should have accepted the fixed sequence of 9"
  end

  revent.sequence = 4
  begin
    client.update_event(element.folder.external_identifier, element.uuid, revent)
  rescue Google::Apis::ClientError => e
    msg = e.message
  end

  unless msg&.match /invalid sequence value/i
    raise "google should have errored"
  end
end

it "if we send the same sequence with a date change the sequence is incremented" do
  folder = get_folder
  event = create_events(1, with_time: false, name: "To be updated without sequence").first

  print_wait "Check the calendar event is created with name: 'To be updated without sequence'"

  event.summary = "One week before"
  event.date_from = event.date_from - 1.week
  element = event.nexo_elements.first
  service = Nexo::ServiceBuilder.instance.build_protocol_service(folder)
  client = service.send(:client)
  revent = service.send(:build_event, event)

  revent.sequence = 0
  response = client.update_event(element.folder.external_identifier, element.uuid, revent)

  unless response.sequence == 1
    raise "google should have returned a sequence of 1"
  end
end

it "Successful bidirectional sync" do
  folder = get_folder
  event = create_events(1, with_time: false, name: "Bidirectional sync").first

  print_wait <<~STR
    Check the calendar event is created with name: 'Bidirectional sync'

    Change the date in Google Calendar
  STR

  element = event.nexo_elements.first
  Nexo::FetchRemoteResourceJob.perform_now(element)

  print_wait "Fetching the change, wait until jobs finish"

  event.reload
  event.summary = "New name"
  event.save!
  Nexo::EventReceiver.new.synchronizable_updated(event)

  print_wait "Check the event should have changed the name and keeped the date change"
end

it "Conflicting bidirectional sync. Local wins" do
  folder = get_folder
  event = create_events(1, with_time: false, name: "Bidirectional sync").first

  print_wait <<~STR
    Check the calendar event is created with name: 'Bidirectional sync'

    Change the date in Google Calendar
  STR

  # element = event.nexo_elements.first
  # Nexo::FetchRemoteResourceJob.perform_now(element)

  # print_wait "Fetching the change, wait until jobs finish"

  event.reload
  event.summary = "New name 2"
  event.save!
  Nexo::EventReceiver.new.synchronizable_updated(event)

  print_wait "Check the local change is pushed to remote"
end

it "Conflicting bidirectional sync. Remote wins" do
  folder = get_folder
  event = create_events(1, with_time: false, name: "Bidirectional sync").first

  print_wait <<~STR
    Check the calendar event is created with name: 'Bidirectional sync'
  STR

  event.reload
  event.summary = "New name 2"
  event.save!

  print_wait <<~STR
    Change the date in Google Calendar
  STR
  Nexo::EventReceiver.new.synchronizable_updated(event)
  # element = event.nexo_elements.first
  # Nexo::FetchRemoteResourceJob.perform_now(element)

  # print_wait "Fetching the change, wait until jobs finish"


  print_wait "Check the local change was discarded"
end
# run_tests(focus: true)
# clear_remote_events
# destroy_elements

# folder = get_folder
# create_events(1, with_time: false)
#
#
create_other_folder

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
