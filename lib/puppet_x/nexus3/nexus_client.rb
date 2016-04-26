require 'faraday'
require 'uri'
require 'base64'

require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'puppet_x', 'nexus3', 'extdirect.rb'))

module Nexus3
  class NexusClient
    def initialize(base_url, admin_user, admin_password)
      @base_url = ::URI.parse(base_url).to_s
      @admin_user = admin_user
      @admin_password = admin_password
    end

    def session
      @session ||= begin
        conn = Faraday.new(:url => "#{@base_url}") do |faraday|
          faraday.request  :url_encoded
          faraday.adapter  Faraday.default_adapter
        end

        response = conn.post '/service/rapture/session', {
          :username => Base64.urlsafe_encode64(@admin_user),
          :password => Base64.urlsafe_encode64(@admin_password),
          :rememberMe => 'on',
        }

        raise "Unable to Authenticate" unless /NXSESSIONID/ =~ response.headers['set-cookie']

        /NXSESSIONID=([^;]+);/.match(response.headers['set-cookie'])[1]
      end
    end

    def extdirect_client
      @extdirect_client ||= Nexus3::ExtDirect.new(
        "#{@base_url}/service/extdirect",
        {:cookie => "NXSESSIONID=#{self.session}"},
      )
    end
  end
end
