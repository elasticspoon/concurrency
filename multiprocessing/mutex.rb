class MutexDeadlockTogether
  def initialize
    @flag = [false, false]
  end

  def synchronize
    lock
    yield
    unlock
  end

  def lock
    current_t_id = Thread.current.name.to_i
    other_t_id = 1 - current_t_id
    @flag[current_t_id] = true

    while @flag[other_t_id]
    end
  end

  def unlock
    @flag[Thread.current.name.to_i] = false
  end
end
