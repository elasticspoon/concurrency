# frozen_string_literal: true

queue = Queue.new

class Event
  def initialize(name, &callback)
    @name = name
    @callback = callback
  end

  def run
    puts "Calling #{@name}"
    @callback&.call
  end
end

who_there = Event.new('Who')
knock = Event.new('knock knock') do
  queue.push(who_there)
end

queue.push(knock)
queue.push(knock)

loop do
  queue.pop&.run
end
