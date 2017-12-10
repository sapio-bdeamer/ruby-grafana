
module Grafana

  # http://docs.grafana.org/http_api/datasource/
  #
  module Datasource

    # Get all datasources
    #
    # @example
    #    datasources
    #
    # @return [Hash]
    #
    def datasources

      endpoint = '/api/datasources'

      @logger.debug("Attempting to get all existing data sources (GET #{endpoint})") if @debug

      datasources = get( endpoint )

      if  datasources.nil? || datasources.dig('status').to_i != 200
        return {
          'status' => 404,
          'message' => 'No Datasources found'
        }
      end

      datasources = datasources.dig('message')

      datasource_map = {}
      datasources.each do |ds|
        datasource_map[ds['id']] = ds
      end

      datasource_map
    end

    # Get a single datasources by Id or Name
    #
    # @example
    #    datasource( 1 )
    #    datasource( 'foo' )
    #
    # @return [Hash]
    #
    def datasource( datasource_id )

      raise ArgumentError.new(format('wrong type. user \'datasource_id\' must be an String (for an Datasource name) or an Integer (for an Datasource Id), given \'%s\'', datasource_id.class.to_s)) if( datasource_id.is_a?(String) && datasource_id.is_a?(Integer) )
      raise ArgumentError.new('missing \'datasource_id\'') if( datasource_id.size.zero? )

      if(datasource_id.is_a?(String))
        data = datasources.select { |_k,v| v['name'] == datasource_id }
        datasource_id = data.keys.first if( data )
      end

      if( datasource_id.nil? )
        return {
          'status' => 404,
          'message' => format( 'No Datasource \'%s\' found', datasource_id)
        }
      end

      raise format('DataSource Id can not be 0') if( datasource_id.zero? )

      endpoint = format('/api/datasources/%d', datasource_id )

      @logger.debug("Attempting to get existing data source Id #{datasource_id} (GET #{endpoint})") if  @debug

      get(endpoint)
    end

    # Get a single data source by Name
    # GET /api/datasources/name/:name

    # Get data source Id by Name
    # GET /api/datasources/id/:name

    # Update an existing data source
    #
    # merge an current existing datasource configuration with the new values
    #
    # @param [Hash] params
    # @option params [Hash] data
    # @option params [Mixed] datasource Datasource Name (String) or Datasource Id (Integer)
    #
    # @example
    #    update_datasource(
    #      datasource: 'graphite',
    #      data: { url: 'http://localhost:2003' }
    #    )
    #
    # @return [Hash]
    #
    def update_datasource( params )

      raise ArgumentError.new(format('wrong type. \'params\' must be an Hash, given \'%s\'', params.class.to_s)) unless( params.is_a?(Hash) )
      raise ArgumentError.new('missing \'params\'') if( params.size.zero? )

      data       = validate( params, required: true, var: 'data', type: Hash )
      datasource = validate( params, required: true, var: 'datasource' )

      raise ArgumentError.new(format('wrong type. user \'datasource\' must be an String (for an Datasource name) or an Integer (for an Datasource Id), given \'%s\'', datasource.class.to_s)) if( datasource.is_a?(String) && datasource.is_a?(Integer) )

      existing_ds = datasource(datasource)

      existing_ds.reject! { |x| x == 'status' }
      existing_ds = existing_ds.deep_string_keys

      datasource_id = existing_ds.dig('id')

      payload = data.deep_string_keys
      payload = existing_ds.merge(payload).deep_symbolize_keys

      endpoint = format('/api/datasources/%d', datasource_id )
      @logger.debug("Updating data source Id #{datasource_id} (GET #{endpoint})") if  @debug
      logger.debug(payload.to_json) if(@debug)

      put( endpoint, payload.to_json )
    end

    # Create data source
    #
    # @param [Hash] params
    # @option params [String] type Datasource Type - (required) (grafana graphite cloudwatch elasticsearch prometheus influxdb mysql opentsdb postgres)
    # @option params [String] name  Datasource Name - (required)
    # @option params [String] database  Datasource Database - (required)
    # @option params [String] access (proxy) Acess Type - (required) (proxy or direct)
    # @option params [Boolean] default (false)
    # @option params [String] user
    # @option params [String] password
    # @option params [String] url Datasource URL - (required)
    # @option params [Hash] json_data
    # @option params [Hash] json_secure
    # @option params [String] basic_user
    # @option params [String] basic_password
    #
    # @example
    #    params = {
    #      name: 'graphite',
    #      type: 'graphite',
    #      database: 'graphite',
    #      url: 'http://localhost:8080'
    #    }
    #    create_datasource(params)
    #
    #    params = {
    #      name: 'graphite',
    #      type: 'graphite',
    #      database: 'graphite',
    #      default: true,
    #      url: 'http://localhost:8080',
    #      json_data: { graphiteVersion: '1.1' }
    #    }
    #    create_datasource(params)
    #
    #    params = {
    #      name: 'test_datasource',
    #      type: 'cloudwatch',
    #      url: 'http://monitoring.us-west-1.amazonaws.com',
    #      json_data: {
    #        authType: 'keys',
    #        defaultRegion: 'us-west-1'
    #      },
    #      json_secure: {
    #        accessKey: 'Ol4pIDpeKSA6XikgOl4p',
    #        secretKey: 'dGVzdCBrZXkgYmxlYXNlIGRvbid0IHN0ZWFs'
    #      }
    #    }
    #    create_datasource(params)
    #
    # @return [Hash]
    #
    def create_datasource( params )

      raise ArgumentError.new(format('wrong type. \'params\' must be an Hash, given \'%s\'', params.class.to_s)) unless( params.is_a?(Hash) )
      raise ArgumentError.new('missing \'params\'') if( params.size.zero? )

      type        = validate( params, required: true, var: 'type', type: String )
      name        = validate( params, required: true, var: 'name', type: String )
      database    = validate( params, required: true, var: 'database', type: String )
      access      = validate( params, required: false, var: 'access', type: String ) || 'proxy'
      default     = validate( params, required: false, var: 'default', type: Boolean ) || false
      user        = validate( params, required: false, var: 'user', type: String )
      password    = validate( params, required: false, var: 'password', type: String )
      url         = validate( params, required: true, var: 'url', type: String )
      json_data   = validate( params, required: false, var: 'json_data', type: Hash )
      json_secure = validate( params, required: false, var: 'json_secure', type: Hash )
      ba_user     = validate( params, required: false, var: 'basic_user', type: String )
      ba_password = validate( params, required: false, var: 'basic_password', type: String )

      basic_auth  = false
      basic_auth  = true unless( ba_user.nil? && ba_password.nil? )

      valid_types = %w[grafana graphite cloudwatch elasticsearch prometheus influxdb mysql opentsdb postgres]

      raise ArgumentError.new(format('wrong datasource type. only %s allowed, given \%s\'', valid_types.join(', '), type)) if( valid_types.include?(type.downcase) == false )

      payload = {
        isDefault: default,
        basicAuth: basic_auth,
        basicAuthUser: ba_user,
        basicAuthPassword: ba_password,
        name: name,
        type: type,
        url: url,
        access: access,
        jsonData: json_data,
        secureJsonData: json_secure
      }

      payload.reject!{ |_k, v| v.nil? }

      if( @debug )
        logger.debug("Creating data source: #{name} (database: #{database})")
        logger.debug( payload.to_json )
      end

      endpoint = '/api/datasources'
      post(endpoint, payload.to_json)
    end

    # Delete an existing data source by id
    #
    # @param [Mixed] datasource_id Datasource Name (String) or Datasource Id (Integer) for delete Datasource
    #
    # @example
    #    delete_datasource( 1 )
    #    delete_datasource( 'foo' )
    #
    # @return [Hash]
    #
    def delete_datasource( datasource_id )

      raise ArgumentError.new(format('wrong type. user \'datasource_id\' must be an String (for an Datasource name) or an Integer (for an Datasource Id), given \'%s\'', datasource_id.class.to_s)) if( datasource_id.is_a?(String) && datasource_id.is_a?(Integer) )
      raise ArgumentError.new('missing \'datasource_id\'') if( datasource_id.size.zero? )

      if(datasource_id.is_a?(String))
        data = datasources.select { |_k,v| v['name'] == datasource_id }
        datasource_id = data.keys.first if( data )
      end

      if( datasource_id.nil? )
        return {
          'status' => 404,
          'message' => format( 'No Datasource \'%s\' found', datasource_id)
        }
      end

      raise format('Data Source Id can not be 0') if( datasource_id.zero? )

      endpoint = format('/api/datasources/%d', datasource_id)
      logger.debug("Deleting data source Id #{datasource_id} (DELETE #{endpoint})") if @debug

      delete(endpoint)
    end


    # Delete an existing data source by name
    # DELETE /api/datasources/name/:datasourceName

    # Data source proxy calls
    # GET /api/datasources/proxy/:datasourceId/*



  end

end

