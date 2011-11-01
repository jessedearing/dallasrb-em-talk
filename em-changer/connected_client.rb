class ConnectedClient
  attr_accessor :websocket, :subscription, :channel

  def wssend(message)
    websocket.send(message)
  end

  def subscribe!
    self.channel.subscribe do |m|
      wssend({slide_number: m}.to_json)
    end
  end
end
