require 'spec_helper'
require 'puppetlabs_spec_helper/puppetlabs_spec/puppet_internals'

lib_path = File.expand_path(File.join(__FILE__, '..', '..', 'lib'))
Puppet[:libdir] = lib_path

provider = Puppet::Type.type(:service).provider(:supervisor)

describe provider do

  let (:subject) {
    resource = Puppet::Type.type(:service).hash2resource({:name => 'supervisor::some-program'})
    provider.new(resource)
  }

  context "with no processes configured" do

    describe "status" do
      it "should return stopped if status produces no output" do
        subject.expects(:supervisorctl).with(:status).returns('')
        subject.status.should == :stopped
      end
    end
  end

  context "with process group" do

    describe "status" do
      it "should return running if the processes are running" do
        subject.expects(:supervisorctl).with(:status).returns(<<-EOF)
some-program:some-program_9000 RUNNING
some-program:some-program_9001 RUNNING
        EOF
        subject.status.should == :running
      end

      it "should return running if some processes are starting" do
        subject.expects(:supervisorctl).with(:status).returns(<<-EOF)
some-program:some-program_9000 STARTING
some-program:some-program_9001 RUNNING
        EOF
        subject.status.should == :running
      end

      it "should return stopped if the processes are stopped" do
        subject.expects(:supervisorctl).with(:status).returns(<<-EOF)
some-program:some-program_9000 STOPPED
some-program:some-program_9001 STOPPED
        EOF
        subject.status.should == :stopped
      end

      it "should return stopped if some processes are stopped and some are running" do
        subject.expects(:supervisorctl).with(:status).returns(<<-EOF)
some-program:some-program_9000 STOPPED
some-program:some-program_9001 RUNNING
some-program:some-program_9002 STOPPED
        EOF
        subject.status.should == :stopped
      end

      # This one is suspicious: should we really be that optimistic
      # and hope that STARTING will be RUNNING soon?
      # We could try sleeping $startsecs after restart. After that the state is deterministic.
      # For now we just issue a warning.
      it "should return running if the processes are starting" do
        subject.expects(:supervisorctl).with(:status).returns(<<-EOF)
some-program:some-program_9000 STARTING
some-program:some-program_9001 STARTING
        EOF
        subject.status.should == :running
      end

      it "should return stopped if the processes are not found" do
        subject.expects(:supervisorctl).with(:status).returns(<<-EOF)
some-other-program:some-other-program_9000 RUNNING
some-other-program:some-other-program_9001 RUNNING
        EOF
        subject.status.should == :stopped
      end

      it "should return stopped if some processes are fatal" do
        subject.expects(:supervisorctl).with(:status).returns(<<-EOF)
some-program:some-program_9000 FATAL
some-program:some-program_9001 RUNNING
        EOF
        subject.status.should == :stopped
      end

    end

    describe "start" do
      it "should succeed if all processes are already started (no output from supervisorctl)" do
        subject.expects(:supervisorctl).with(:start, 'some-program:*').returns('')
        subject.start
      end

      it "should succeed if all processes are started" do
        subject.expects(:supervisorctl).with(:start, 'some-program:*').returns(<<-EOF)
some-program_9000: started
some-program_9001: started
        EOF
        subject.start
      end

      it "should fail if not all processes could be started" do
        subject.expects(:supervisorctl).with(:start, 'some-program:*').returns(<<-EOF)
some-program_9000: started
some-program_9001: ERROR (abnormal termination)
        EOF
        expect {
          subject.start
        }.to raise_error(Puppet::Error, /Could not start some-program/)
      end

      it "should fail if output is unexpected" do
        subject.expects(:supervisorctl).with(:start, 'some-program:*').returns(<<-EOF)
and what do you think about king prawn?
        EOF
        expect {
          subject.start
        }.to raise_error(Puppet::Error, /Could not start some-program/)
      end
    end

    describe "stop" do

      it "should stop the process if it is running" do
        subject.expects(:supervisorctl).with(:stop, 'some-program:*').returns(<<-EOF)
some-program_9000: stopped
some-program_9001: stopped
        EOF
        subject.stop
      end

      it "should succeed if process already stopped" do
        subject.expects(:supervisorctl).with(:stop, 'some-program:*').returns(<<-EOF)
some-program_9000: stopped
some-program_9001: ERROR (not running)
        EOF
        subject.stop
      end

      it "should fail if the process name is not found" do
        subject.expects(:supervisorctl).with(:stop, 'some-program:*').returns(<<-EOF)
error: <class 'xmlrpclib.Fault'>, <Fault 10: 'BAD_NAME: some-other-program'>: file: /usr/lib/python2.6/xmlrpclib.py
        EOF
        expect {
          subject.stop
        }.to raise_error(Puppet::Error, /Could not stop some-program/)
      end

      it "should succeed even if it wasn't running (race condition?)" do
        subject.expects(:supervisorctl).with(:stop, 'some-program:*').returns(<<-EOF)
FAILED: attempted to kill some-program_9014 with sig SIGTERM but it wasn't running
FAILED: attempted to kill some-program_9013 with sig SIGTERM but it wasn't running
some-program_9018: stopped
some-program_9019: stopped
        EOF
        subject.stop
      end
    end

    describe "restart" do
      it "should succeed if all processes are started and stopped" do
        subject.expects(:supervisorctl).with(:restart, 'some-program:*').returns(<<-EOF)
some-program_9000: stopped
some-program_9001: stopped
some-program_9000: started
some-program_9001: started
        EOF
        subject.restart
      end


      it "should succeed if some processes are not running" do
        subject.expects(:supervisorctl).with(:restart, 'some-program:*').returns(<<-EOF)
some-program_9000: stopped
some-program_9000: started
some-program_9001: started
some-program_9002: started
        EOF
        subject.restart
      end

      it "should fail if not all processes are started and stopped" do
        subject.expects(:supervisorctl).with(:restart, 'some-program:*').returns(<<-EOF)
some-program_9000: stopped
some-program_9001: stopped
some-program_9001: started
some-program_9000: ERROR (abnormal termination)
        EOF
        expect {
          subject.restart
        }.to raise_error(Puppet::Error, /Could not restart some-program/)
      end
    end

  end

  context "with a single process" do

    describe "group_or_process_name" do
      it "should return some-programm" do
        subject.group_or_process_name.should == 'some-program'
      end
    end

    describe "status" do
      it "should return running if the process is running" do
        subject.expects(:supervisorctl).with(:status).returns('some-program RUNNING')
        subject.status.should == :running
      end

      it "should return stopped if the process is stopped" do
        subject.expects(:supervisorctl).with(:status).returns('some-program STOPPED')
        subject.status.should == :stopped
      end

      # This one is suspicious: should we really be that optimistic
      # and hope that STARTING will be RUNNING soon?
      # We could try sleeping $startsecs after restart. After that the state is deterministic.
      # For now we just issue a warning.
      it "should return running if the process is starting" do
        subject.expects(:supervisorctl).with(:status).returns('some-program STARTING')
        subject.status.should == :running
      end

      it "should return stopped if the process is not found" do
        subject.expects(:supervisorctl).with(:status).returns('some-other-program RUNNING')
        subject.status.should == :stopped
      end

      it "should return stopped if the process is fatal" do
        subject.expects(:supervisorctl).with(:status).returns('some-program FATAL')
        subject.status.should == :stopped
      end
    end

    describe "start" do

      it "should start the process if it is stopped" do
        subject.expects(:supervisorctl).with(:start, 'some-program:*').returns('some-program: started')
        subject.start
      end

      it "should succeed if process already started" do
        subject.expects(:supervisorctl).with(:start, 'some-program:*').returns('some-program: ERROR (already started)')
        subject.start
      end

      it "should fail if process is not found" do
        subject.expects(:supervisorctl).with(:start, 'some-program:*').returns('some-program: ERROR (no such process)')
        expect {
          subject.start
        }.to raise_error(Puppet::Error, /Could not start some-program/)
      end

      it "should fail if process could not be started" do
        subject.expects(:supervisorctl).with(:start, 'some-program:*').returns('some-program: ERROR (abnormal termination)')
        expect {
          subject.start
        }.to raise_error(Puppet::Error, /Could not start some-program/)
      end
    end

    describe "stop" do

      it "should stop the process if it is running" do
        subject.expects(:supervisorctl).with(:stop, 'some-program:*').returns('some-program: stopped')
        subject.stop
      end

      it "should succeed if process already stopped" do
        subject.expects(:supervisorctl).with(:stop, 'some-program:*').returns('some-program: ERROR (not running)')
        subject.stop
      end

      it "should fail if the process name is not found" do
        subject.expects(:supervisorctl).with(:stop, 'some-program:*').returns('some-program: ERROR (no such process)')
        expect {
          subject.stop
        }.to raise_error(Puppet::Error, /Could not stop some-program/)
      end
    end

    describe "restart" do

      it "should succeed if the process is stopped" do
        subject.expects(:supervisorctl).with(:restart, 'some-program:*').returns(<<-EOF)
some-program: ERROR (not running)
some-program: started
        EOF
        subject.restart
      end

      it "should succeed if the process is running" do
        subject.expects(:supervisorctl).with(:restart, 'some-program:*').returns(<<-EOF)
some-program: stopped
some-program: started
        EOF
        subject.restart
      end

      it "should fail if the process could not be started" do

        subject.expects(:supervisorctl).with(:restart, 'some-program:*').returns(<<-EOF)
some-program: stopped
some-program: ERROR (abnormal termination)
        EOF
        expect {
          subject.restart
        }.to raise_error(Puppet::Error, /Could not restart some-program/)
      end

    end
  end
end
