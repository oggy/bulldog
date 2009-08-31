module TimeTravel
  def self.included(mod)
    mod.before{stop_time}
  end

  def stop_time
    Time.stubs(:now).returns(Time.now)
  end

  def warp_ahead(duration)
    new_now = Time.now + duration
    Time.stubs(:now).returns(new_now)
    new_now
  end
end
