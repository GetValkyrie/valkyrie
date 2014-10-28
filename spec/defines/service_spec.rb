require 'spec_helper'

describe 'supervisor::service' do
  let (:facts) { {
    :osfamily => 'debian',
  } }
  let(:title) { 'sometitle' }
  let(:params) { {
    :command     => 'somecommand',
  } }

  context "with debian configuration" do
    let (:pre_condition) {
      <<-PUPPET
        class { 'supervisor':
          conf_dir => '/etc/supervisor/conf.d',
          conf_ext => '.conf',
        }
      PUPPET
    }


    it "should include /etc/supervisor/conf.d/*.conf in /etc/supervisor/supervisord.conf" do
      should create_file('/etc/supervisor/supervisord.conf') \
          .with_content(Regexp.new Regexp.escape 'files = /etc/supervisor/conf.d/*.conf')
    end

    it "should create /etc/supervisor/conf.d/sometitle.conf" do
      should create_file('/etc/supervisor/conf.d/sometitle.conf') \
          .with_content(Regexp.new Regexp.escape 'command=somecommand')
    end
  end

  context "with default configuration" do

    it "should include /etc/supervisor/*.ini in /etc/supervisor/supervisord.conf" do
      should contain_file('/etc/supervisor/supervisord.conf') \
          .with_content(Regexp.new Regexp.escape 'files = /etc/supervisor/*.ini')
    end

    it "should create /etc/supervisor/sometitle.ini" do
      should create_file('/etc/supervisor/sometitle.ini') \
          .with_content(Regexp.new Regexp.escape 'command=somecommand')
    end

    context "with ensure => absent" do
      let (:params) { {
        :command => 'somecommand',
        :ensure => 'absent',
      } }

      it "should delete config and log dir" do
        should contain_file('/etc/supervisor/sometitle.ini').with_ensure('absent')
        should contain_file('/var/log/supervisor/sometitle').with_ensure('absent')
      end
    end
  end

  context "with ensure => stopped" do
    let (:params) { {
      :command => 'somecommand',
      :ensure => 'stopped',
    } }

    it "should create /etc/supervisor/sometitle.ini" do
      should create_file('/etc/supervisor/sometitle.ini') \
          .with_content(Regexp.new Regexp.escape 'command=somecommand')
    end

    it "should ensure that the service is stopped" do
      should contain_service('supervisor::sometitle').with_ensure('stopped')
    end
  end

end
