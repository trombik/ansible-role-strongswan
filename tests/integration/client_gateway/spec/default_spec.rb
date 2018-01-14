require "spec_helper"

class ServiceNotReady < StandardError
end

sleep 10 if ENV["JENKINS_HOME"]

clients = [:client1]
# clients = [:client1, :client2]
context "after provisioning finished" do
  clients.each do |client|
    describe server(client) do
      it "should be able to ping server" do
        result = current_server.ssh_exec("ping -c 1 #{server(:server1).server.address} && echo OK")
        expect(result).to match(/OK/)
      end
    end
  end

  describe server(:server1) do
    clients.each do |client|
      it "should be able to ping #{client}" do
        result = current_server.ssh_exec("ping -c 1 #{server(client).server.address} && echo OK")
        expect(result).to match(/OK/)
      end
    end
  end

  clients.each do |client|
    describe server(client) do
      it "establishes IPSec tunnel" do
        # ensure the tunnel is not created
        current_server.ssh_exec("sudo ipsec down vpn")
        r = current_server.ssh_exec("sudo ipsec up vpn")
        expect(r).to match(/^connection 'vpn' established successfully$/)
      end

      it "has a correct route to internal network" do
        r = current_server.ssh_exec("sudo route -n get 172.16.0.200")
        # when tunnel was not created, interface would be em0
        expect(r).to match(/^\s*interface: tun0$/)
      end
    end
  end
end

context "when tunnel has been established" do
  clients.each do |client|
    before(:all) do
      server(client).server.ssh_exec("sudo ipsec down vpn")
      server(client).server.ssh_exec("sudo ipsec up vpn")
    end

    after(:all) do
      server(client).server.ssh_exec("sudo ipsec down vpn")
    end

    client_subnet = %r{172\.16\.0\.11\d\/32}
    internel_subnet = %r{0\.0\.0\.0\/0}

    describe server(:client1) do
      it "has an SA" do
        r = current_server.ssh_exec("sudo ipsec status")
        expect(r).to match(/Security Associations \(1 up/)
        expect(r).to match(/vpn\[\d+\]: ESTABLISHED/)
        # 172.16.0.110/32 === 172.16.0.0/24
        expect(r).to match(/vpn\{\d+\}:\s+#{client_subnet} === #{internel_subnet}/)
      end
    end

    describe server(:server1) do
      it "has an SA" do
        r = current_server.ssh_exec("sudo ipsec status")
        expect(r).to match(/Security Associations \(1 up/)
        expect(r).to match(/vpn\[\d+\]: ESTABLISHED/)
        expect(r).to match(/vpn\{\d+\}:\s+#{internel_subnet} === #{client_subnet}/)
      end
    end

    describe server(client) do
      it "has default route to WAN via IPSec tunnel" do
        r = current_server.ssh_exec("route -n get www.example.org")
        expect(r).to match(/^\s*interface: tun0$/)
      end

      it "gets HTTP resource from external host" do
        # ICMP is preferred, but virtualbox does not NAT ICMP, use HTTP instead
        r = current_server.ssh_exec("curl -sI http://www.example.org/")
        expect(r).to match(%r{^HTTP/1\.1 200 OK})
      end
    end
  end
end
