# Manage services using Supervisor.  Start/stop uses /sbin/service and enable/disable uses chkconfig

Puppet::Type.type(:service).provide :supervisor, :parent => :base do

  desc "Supervisor: A daemontools-like service monitor written in python"

  commands :supervisorctl => "/usr/bin/supervisorctl"

  def name_without_prefix
    @resource[:name].gsub(/^supervisor::/, '')
  end

  def group_or_process_name
    name_without_prefix
  end

  def supervisorctl_arg
    name_without_prefix + ':*'
  end

  def status
    begin
      output = supervisorctl(:status)
    rescue Puppet::ExecutionFailure
      return :stopped
    end

    filtered_output = output.lines.grep /#{self.group_or_process_name}[ :]/
    if filtered_output.empty?
      return :stopped
    end

    status_is_starting = filtered_output.grep(/STARTING/)
    unless status_is_starting.empty?
      Puppet.warning "Could not reliably determine status: #{self.group_or_process_name} is still starting"
    end

    status_not_running = filtered_output.reject {|item| item =~ /RUNNING|STARTING/}
    if status_not_running.empty?
      return :running
    end

    :stopped
  end

  def restart
    output = supervisorctl(:restart, self.supervisorctl_arg)

    if output.include? 'ERROR (no such process)' or output.include? 'ERROR (abnormal termination)'
      raise Puppet::Error, "Could not restart #{self.group_or_process_name}: #{output}"
    end
  end

  def start
    output = supervisorctl(:start, self.supervisorctl_arg)

    if output.include? 'ERROR (no such process)' or output.include? 'ERROR (abnormal termination)'
      raise Puppet::Error, "Could not start #{self.group_or_process_name}: #{output}"
    end

    filtered_output = output.lines.reject {|item| item.include? "ERROR (already started)"}

    status_not_started = filtered_output.reject {|item| item =~ /started$/}
    unless status_not_started.empty?
      raise Puppet::Error, "Could not start #{self.group_or_process_name}: #{output}"
    end
  end

  def stop
    output = supervisorctl(:stop, self.supervisorctl_arg)

    if output.include? 'ERROR (no such process)'
      raise Puppet::Error, "Could not stop #{self.group_or_process_name}: #{output}"
    end

    if output =~ /^error/
      raise Puppet::Error, "Could not stop #{self.group_or_process_name}: #{output}"
    end
  end

end
