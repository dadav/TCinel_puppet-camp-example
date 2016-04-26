require 'faraday'
require 'uri'
require 'json'

module Nexus3
  class ExtDirect
    def initialize(url, headers = {})
      @url = ::URI.parse(url).to_s
      @headers = headers
      @tid = 0

      @headers[:content_type] = 'application/json'
    end

    def connection
      @connection ||= ::Faraday.new()
    end

    def remote(action, method, data)
      @tid += 1

      body = {
        'type'   => 'rpc',
        'tid'    => @tid,
        'action' => action,
        'method' => method,
        'data'   => data,
      }.to_json

      response = self.connection.post(@url, body, @headers)

      if response.nil? || response.body.nil? || response.body.empty?
        raise "Error Making Request"
      end

      return JSON.parse(response.body)
    end
  end
end
