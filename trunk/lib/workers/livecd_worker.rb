class LivecdWorker < BackgrounDRb::MetaWorker
  set_worker_name :livecd_worker
  def create(args = nil)
    # this method is called, when worker is loaded for the first time
  end
end

