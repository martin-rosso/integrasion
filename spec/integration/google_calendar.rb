# rubocop:disable all
require "rails_helper"

require_relative "common"

describe "Integration tests" do
  include ActiveJob::TestHelper

  around do |example|
    perform_enqueued_jobs do
      example.run
    end
  end

  before do |example|
    load File.expand_path("../../db/seeds.rb", Rails.root)
    puts "*************************************"
    puts "Running test: #{example.description}"
  end

  let!(:folder) do
    aux = Nexo::Folder.create!(
      integration: Nexo::Integration.first,
      sync_direction: :sync_bidirectional,
      external_identifier:,
      nexo_protocol: :calendar,
      name: "Nexo Integration Test",
      description: "Automatically created for testing"
    )
    DummyFolderRule.create!(folder: aux, sync_policy: :include, search_regex: ".*")
    aux
  end

  let(:external_identifier) { ENV.fetch("FOLDER_EXTERNAL_ID") }

  after do
    clear_remote_events
  end

  if ENV.fetch("CREATE_FOLDER", false)
    context "create folder" do
      let(:external_identifier) { nil }

      it "create the folder and get its external_identifier for later tests" do
        folder
        Nexo::EventReceiver.new.folder_changed(folder)
        sleep 3
        id = folder.reload.external_identifier
        puts "FOLDER_EXTERNAL_ID=#{id}"
      end
    end
  end

  it "The event with time is blocking/busy. The all-day event, non-blocking/free" do
    create_events(1, with_time: true)
    create_events(1, with_time: false)

    print_wait "The event with time is blocking/busy. The all-day event, non-blocking/free"
  end

  it "Update to event summary" do
    event = create_events(1, with_time: false, name: "To be updated").first

    print_wait "Check the calendar event is created with name: 'To be updated'"

    event.update(summary: "The name has changed!")
    Nexo::EventReceiver.new.synchronizable_updated(event)

    print_wait "Check the new name of the event"
  end

  it "Locally deleted event" do
    event = create_events(1, with_time: false, name: "To be deleted").first

    sleep 1

    event.destroy
    Nexo::EventReceiver.new.synchronizable_destroyed(event)
    element = Nexo::Element.first

    Nexo::FetchRemoteResourceJob.perform_now(element)

    expect(element.element_versions.count).to eq 2
    satisfy = element.element_versions.all? do |version|
      version.origin == "internal" && version.nev_status == "synced"
    end
    expect(satisfy).to be_truthy
  end

  pending "Update to conflicted event fails" do
    event = create_events(1, with_time: false, name: "Modify this").first

    print_wait <<~STR
      Find the google calendar event with name: 'Modify this'

      Then modify the event, by changing the date or whatever attribute of it
    STR

    event.update(summary: "The event must not be updated")

    Nexo::EventReceiver.new.synchronizable_updated(event)

    expect(event).to be_conflicted
  end

  pending "Delete to conflicted event fails" do
    event = create_events(1, with_time: false, name: "Modify this, also").first

    print_wait <<~STR
      Find the google calendar event with name: 'Modify this, also'

      Then modify the event, by changing the date or whatever attribute of it
    STR

    element = event.nexo_elements.first
    Nexo::ElementService.new(element:).flag_for_removal!(:synchronizable_destroyed)

    Nexo::EventReceiver.new.synchronizable_updated(event)

    expect(event).to be_conflicted
  end

  it "Remote update doesn't change the sequence" do
    event = create_events(1, with_time: false, name: "Change the SUMMARY of this").first

    element = event.nexo_elements.first
    rev = get_event(element)

    print_wait <<~STR
      Check the calendar event is created with name: 'Change the SUMMARY of this'

      The event has: Sequence: #{rev.sequence}. Etag: #{rev.etag}

      Now modify the event, by changing the SUMMARY
    STR

    rev2 = get_event(element)

    expect(rev.sequence).to eq rev2.sequence
    expect(rev.etag != rev2.etag).to be_truthy, "expected `etag` to have changed"
  end

  it "Remote update does change the sequence" do
    event = create_events(1, with_time: false, name: "Change the DATE of this").first

    element = event.nexo_elements.first
    rev = get_event(element)

    print_wait <<~STR
      Check the calendar event is created with name: 'Change the DATE of this'

      The event has: Sequence: #{rev.sequence}. Etag: #{rev.etag}

      Now modify the event, by changing the DATE
    STR

    rev2 = get_event(element)

    expect(rev2.sequence == rev.sequence + 1).to be_truthy, "expected sequence to be incremented by 1"

    expect(rev.etag != rev2.etag).to be_truthy, "expected `etag` to have changed"
  end

  it "if we send dont send the secuence, it gets updated by google" do
    event = create_events(1, with_time: false, name: "To be updated without sequence").first

    # print_wait "Check the calendar event is created with name: 'To be updated without sequence'"

    event.summary = "One week before"
    event.date_from = event.date_from - 1.week
    element = event.nexo_elements.first
    service = Nexo::ServiceBuilder.instance.build_protocol_service(folder)
    client = service.send(:client)
    revent = service.send(:build_event, element)

    revent.sequence = nil
    response = client.update_event(element.folder.external_identifier, element.uuid, revent)
    expect(response.sequence).to eq 1
  end

  it "if we send a fixed sequence it gets accepted, and an invalid one gets rejected" do
    event = create_events(1, with_time: false, name: "To be updated without sequence").first

    event.summary = "One week before"
    event.date_from = event.date_from - 1.week
    element = event.nexo_elements.first
    service = Nexo::ServiceBuilder.instance.build_protocol_service(folder)
    client = service.send(:client)
    revent = service.send(:build_event, element)

    revent.sequence = 9
    response = client.update_event(element.folder.external_identifier, element.uuid, revent)
    expect(response.sequence).to eq 9

    revent.sequence = 4
    begin
      client.update_event(element.folder.external_identifier, element.uuid, revent)
    rescue Google::Apis::ClientError => e
      msg = e.message
    end

    expect(msg).to match /invalid sequence value/i
  end

  it "if we send the same sequence with a date change the sequence is incremented" do
    event = create_events(1, with_time: false, name: "To be updated without sequence").first

    event.summary = "One week before"
    event.date_from = event.date_from - 1.week
    element = event.nexo_elements.first
    service = Nexo::ServiceBuilder.instance.build_protocol_service(folder)
    client = service.send(:client)
    revent = service.send(:build_event, element)

    revent.sequence = 0
    response = client.update_event(element.folder.external_identifier, element.uuid, revent)

    expect(response.sequence).to eq 1
  end

  it "Successful bidirectional sync" do
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

  pending "Conflicting bidirectional sync. Local wins" do
    event = create_events(1, with_time: false, name: "Bidirectional sync").first

    print_wait <<~STR
      Check the calendar event is created with name: 'Bidirectional sync'

      Change the date in Google Calendar
    STR

    puts "10 seconds of gracia"
    sleep 10

    event.reload
    event.summary = "New name 2"
    event.save!
    Nexo::EventReceiver.new.synchronizable_updated(event)

    expect(event).to be_conflicted
    element = event.nexo_elements.first
    expect(element.ne_status).to eq "conflicted"
    Nexo::ElementService.new(element:).resolve_conflict!

    expect(event).not_to be_conflicted
    expect(element.reload.ne_status).to eq "synced"

    expect(element.element_versions.where(origin: :external, nev_status: :ignored_in_conflict).any?).to be_truthy
  end

  pending "Conflicting bidirectional sync. Remote wins" do
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

    expect(event).to be_conflicted
    element = event.nexo_elements.first
    expect(element.ne_status).to eq "conflicted"
    Nexo::ElementService.new(element:).resolve_conflict!

    expect(event).not_to be_conflicted
    expect(element.reload.ne_status).to eq "synced"

    expect(element.element_versions.where(origin: :internal, nev_status: :ignored_in_conflict).any?).to be_truthy
  end

  it "Sync: cancelled events" do
    event = create_events(1, with_time: false, name: "To be deleted").first
    Nexo::GoogleCalendarSyncService.new(folder.integration).full_or_incremental_sync!(folder)

    sleep 1

    event.destroy
    Nexo::EventReceiver.new.synchronizable_destroyed(event)

    sleep 1

    Nexo::GoogleCalendarSyncService.new(folder.integration).full_or_incremental_sync!(folder)

    expect(Nexo::Element.count).to eq 1
    expect(Nexo::Element.first.last_remote_version.remote_status).to eq "cancelled"
    expect(Nexo::ElementVersion.count).to eq 2
  end
end
