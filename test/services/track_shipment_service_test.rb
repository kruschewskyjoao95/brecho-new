require "test_helper"

class TrackShipmentServiceTest < ActiveSupport::TestCase
  test "should return empty array if tracking code is blank" do
    service = TrackShipmentService.new("")
    assert_empty service.call
  end

  test "should generate simulated tracking events when order is shipped" do
    service = TrackShipmentService.new("TEST123456", "shipped")
    events = service.call

    assert_not_empty events
    assert_equal 2, events.size
    
    first_event = events.first
    assert_equal "Em Trânsito", first_event[:status]
    assert_equal "Objeto em trânsito - por favor aguarde", first_event[:description]
    assert_equal "Unidade de Tratamento - São Paulo / SP", first_event[:location]
    assert_not_nil first_event[:date]
  end

  test "should generate simulated tracking events when order is completed" do
    service = TrackShipmentService.new("TEST123456", "completed")
    events = service.call

    assert_not_empty events
    assert_equal 4, events.size
    
    latest_event = events.first
    assert_equal "Entregue", latest_event[:status]
    assert_equal "Objeto entregue ao destinatário", latest_event[:description]
    assert_equal "Rio de Janeiro / RJ", latest_event[:location]
    assert_not_nil latest_event[:date]
  end
end
