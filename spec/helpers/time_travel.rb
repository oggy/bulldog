module TimeTravel
  def self.included(mod)
    mod.before{stop_time}
  end

  def stop_time
    warp_to Time.now
  end

  def warp_to(time)
    time = Time.parse(time) if time.is_a?(String)
    Time.stubs(:now).returns(time)
  end

  def warp_ahead(duration)
    new_now = Time.now + duration
    Time.stubs(:now).returns(new_now)
    new_now
  end
end
