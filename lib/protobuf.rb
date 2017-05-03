require 'logger'
require 'socket'
require 'pp'
require 'stringio'

require 'active_support/core_ext/object/blank'
require 'active_support/core_ext/object/try'
require 'active_support/inflector'
require 'active_support/json'
require 'active_support/notifications'

# All top-level run time code requires, ordered by necessity
require 'protobuf/wire_type'

require 'protobuf/varint_pure'
require 'protobuf/varint'

require 'protobuf/exceptions'
require 'protobuf/deprecation'
require 'protobuf/logging'

require 'protobuf/encoder'
require 'protobuf/decoder'

require 'protobuf/optionable'
require 'protobuf/field'
require 'protobuf/enum'
require 'protobuf/message'
require 'protobuf/descriptors'

module Protobuf

  class << self
    # Client Host
    #
    # Default: `hostname` of the system
    #
    # The name or address of the host to use during client RPC calls.
    attr_writer :client_host

    # Server Host
    #
    # Default: first ipv4 address of the system
    #
    # The name or address of the host to use during client RPC calls.
    attr_writer :server_host
  end

  def self.client_host
    @client_host ||= Socket.gethostname
  end

  def self.connector_type_class
    @connector_type_class ||= ::Protobuf::Rpc::Connectors::Socket
  end

  def self.connector_type_class=(type_class)
    @connector_type_class = type_class
  end

  # GC Pause during server requests
  #
  # Default: false
  #
  # Boolean value to tell the server to disable
  # the Garbage Collector when handling an rpc request.
  # Once the request is completed, the GC is enabled again.
  # This optomization provides a huge boost in speed to rpc requests.
  def self.gc_pause_server_request?
    return @gc_pause_server_request unless @gc_pause_server_request.nil?
    self.gc_pause_server_request = false
  end

  def self.gc_pause_server_request=(value)
    @gc_pause_server_request = !!value
  end

  # Permit unknown field on Message initialization
  #
  # Default: true
  #
  # Simple boolean to define whether we want to permit unknown fields
  # on Message intialization; otherwise a ::Protobuf::FieldNotDefinedError is thrown.
  def self.ignore_unknown_fields?
    !defined?(@ignore_unknown_fields) || @ignore_unknown_fields
  end

  def self.ignore_unknown_fields=(value)
    @ignore_unknown_fields = !!value
  end

  def self.server_host
    @server_host ||= Socket.gethostname
  end
end

unless ENV.key?('PB_NO_NETWORKING')
  require 'protobuf/rpc/client'
  require 'protobuf/rpc/service'

  env_connector_type = ENV.fetch('PB_CLIENT_TYPE') do
    :socket
  end

  symbolized_connector_type = env_connector_type.to_s.downcase.strip.to_sym
  if [:zmq, :socket].include?(symbolized_connector_type)
    require "protobuf/#{symbolized_connector_type}"
  else
    require "#{env_connector_type}" # rubocop:disable Style/UnneededInterpolation
    classified = env_connector_type.classify
    ::Protobuf.connector_type_class = classified.constantize
  end
end
