class Sempaphore
  def initialize(spots)
    @mutex = Mutex.new
    @spots = 
  end

  def acquire(thread_id)
  end

  def release(thread_id)
  end
end

class Garage
  def initialize(spots)
    @lock = Mutex.new
    @cars = []
  end

  def park_car(car)
    @lock.synchronize do
      @cars << car
    end
  end

  def leave(car)
    @lock.synchronize do
      @cars.delete(car)
    end
  end
end

def park_cars(garage, car)
  puts "Parking #{car}"
  garage.park_car(car)
  sleep rand(1..3)
  puts "Leaving #{car}"
  grage.leave(car)
end

garage = Garage.new(4)
