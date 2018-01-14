require "spec_helper"
require "serverspec"

package = "strongswan"
service = "strongswan"
user    = "strongswan"
group   = "nogroup"
ports   = [500, 4500]
log_dir = "/var/log/strongswan"
config_dir = "/etc"
default_user = "root"
default_group = "root"

case os[:family]
when "freebsd"
  user = "root"
  group = "wheel"
  default_group = "wheel"
  config_dir = "/usr/local/etc"
end
config = "#{config_dir}/strongswan.conf"
conf_d = "#{config_dir}/strongswan.d"
ipsec_conf = "#{config_dir}/ipsec.conf"
ipsec_secrets = "#{conf_d}/ipsec.secrets"

describe package(package) do
  it { should be_installed }
end
describe file("#{conf_d}/empty.conf") do
  it { should exist }
  it { should be_file }
  it { should be_owned_by "daemon" }
  it { should be_grouped_into "daemon" }
  it { should be_mode 640 }
  its(:content) { should match(/^# intentinally empty$/) }
end
describe file("#{conf_d}/charon-logging.conf") do
  it { should exist }
  it { should be_file }
  it { should be_owned_by default_user }
  it { should be_grouped_into default_group }
  it { should be_mode 644 }
  its(:content) { should match(/^\s+default = 2$/) }
end

describe file(config) do
  it { should exist }
  it { should be_file }
  it { should be_owned_by default_user }
  it { should be_grouped_into default_group }
  it { should be_mode 644 }
  its(:content) { should match(%r{^\s+include #{Regexp.escape(conf_d)}/charon/\*\.conf$}) }
  its(:content) { should match(%r{^include strongswan\.d/\*\.conf$}) }
end

describe file(ipsec_conf) do
  it { should exist }
  it { should be_file }
  it { should be_owned_by default_user }
  it { should be_grouped_into default_group }
  it { should be_mode 644 }
  its(:content) { should match(/^config setup$/) }
  its(:content) { should match(/^conn %default\n\s+ikelifetime=60m$/) }
  its(:content) { should match(/^conn rw-eap\n\s+left=#{Regexp.escape("10.0.2.15")}$/) }
end

describe file(ipsec_secrets) do
  it { should exist }
  it { should be_file }
  it { should be_owned_by "daemon" }
  it { should be_grouped_into "daemon" }
  it { should be_mode 640 }
  password = "v+NkxY9LLZvwj4qCC2o/gGrWDF2d21jL"
  its(:content) { should match(/^192\.168\.0\.1 : PSK "#{Regexp.escape(password)}"$/) }
  its(:content) { should match(/^192\.168\.0\.2 : PSK "#{Regexp.escape(password)}"$/) }
end

describe file(log_dir) do
  it { should exist }
  it { should be_mode 755 }
  it { should be_owned_by user }
  it { should be_grouped_into group }
end

describe service(service) do
  it { should be_running }
  it { should be_enabled }
end

ports.each do |p|
  describe port(p) do
    it { should be_listening }
  end
end
