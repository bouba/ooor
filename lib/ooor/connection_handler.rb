require 'ooor/connection'

module Ooor
  class ConnectionHandler
    def connection_spec(config)
      config.slice(:url, :user_id, :password, :database, :scope_prefix)
    end

    # meant to be overriden for Omniauth, Devise...
    def user_connection(email=nil)
      retrieve_connection(Ooor.default_config)
    end

    def retrieve_connection(config) #TODO cheap impl of connection pool
      config[:user_id] ||= config.delete(:ooor_user_id)
      config[:username] ||= config.delete(:ooor_username)
      config[:password] ||= config.delete(:ooor_password)
      config[:database] ||= config.delete(:ooor_database)
      connections.each do |c| #TODO limit pool size, create a queue etc...
        if connection_spec(c.config) == connection_spec(config)
          c.config.merge(config)
          return c
        end
      end #TODO may be use something like ActiveRecord::Base.connection_id ||= Thread.current.object_id
      config = Ooor.default_config.merge(config) if Ooor.default_config.is_a? Hash
      Connection.new(config).tap do |c|
        if config[:database] && config[:username] && !config[:user_id]
          c.config[:user_id] = Ooor.cache.fetch("login-id-#{config[:username]}") do
            c.common.login(config[:database], config[:username], config[:password])
          end
        end
        @connections << c
      end
    end

    def connections; @connections ||= []; end
  end
end
