require 'spec_helper'

describe 'supervisor::params' do
  context "on redhat" do
    let(:facts) { {
      :osfamily => 'redhat',
    } }
    it {
      should compile
    }
  end

  context "on debian" do
    let(:facts) { {
      :osfamily => 'debian',
    } }
    it {
      should compile
    }
  end

  context "on windows" do
    let(:facts) { {
      :osfamily => 'Windows',
    } }
    it {
      expect {
        subject
      }.to raise_error(Puppet::Error, /Unsupported platform: Windows/)
    }
  end
end
