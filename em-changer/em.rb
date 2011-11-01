require 'bundler/setup'
Bundler.require
require './connected_client'
require './http_server'

EM.run do
  new_client_queue = EM::Queue.new
  slide_channel = EM::Channel.new

  # Initializing slides and clients
  current_clients = []
  current_slide_number = 0

  # This is the pop callback to add new nodes to the current_clients list
  client_pop = proc do |client|
    puts "adding new client to list of current clients"
    client.channel = slide_channel
    client.subscribe!
    current_clients << client
    # On the next tick of the event loop enqueue the callback to happen on the next item to be popped
    EM.next_tick {new_client_queue.pop(&client_pop)}
  end

  # Set up the inital pop callback
  new_client_queue.pop(&client_pop)

  # Start Websockets server
  EventMachine::WebSocket.start(host: "0.0.0.0", port: 8080) do |ws|
    ws.onopen do
      # Create a new ConnectedClient when a user connects
      client = ConnectedClient.new
      client.websocket = ws
      # Queue them up to be added to the current_clients array
      new_client_queue.push(client)
      # Go ahead and send them the slide we're on
      client.wssend({slide_number: current_slide_number}.to_json)
    end

    ws.onclose do
      # Remove them from the current clients array
      d = current_clients.delete_if {|c| c.websocket == ws}
      # Unsubscribe from the channel
      d.map {|i| i.channel.unsubscribe(i.subscription) }
    end
  end

  EM.start_server '127.0.0.1', 9000, HttpServer, proc { |n|
    current_slide_number += n
    slide_channel << current_slide_number
  }
end
