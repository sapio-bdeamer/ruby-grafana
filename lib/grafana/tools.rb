
module Grafana

  module Tools

    def slug( text )

      raise ArgumentError.new(format('wrong type. \'text\' must be an String, given \'%s\'', text.class.to_s)) unless( text.is_a?(String) )

      begin
      if( text =~ /\s/ && text =~ /-/ )
#        if( text =~ /-/ )
          text = text.gsub( /\s+/, '' )
        else
          text = text.gsub( /\s+/, '-' )
#        end
      end

      rescue => e
        puts e
      end

      text.downcase
    end


    def regenerate_template_ids( params )

      raise ArgumentError.new(format('wrong type. \'params\' must be an Hash, given \'%s\'', params.class.to_s)) unless( params.is_a?(Hash) )
      raise ArgumentError.new('missing \'params\'') if( params.size.zero? )

      rows = params.dig('dashboard','rows')
      # name   = validate( params, required: true, var: 'name', type: String )

      unless( rows.nil? )

        # counter = 1
        id_counter = 10
        rows.each_with_index do |r, _counter|
          panel = r.dig('panels')
          next if( panel.nil? )
          panel.each do |p|
            p['id']   = id_counter
            id_counter = id_counter +=1 # id_counter+1 # id_counter +=1 ??
          end
        end
      end

      JSON.generate( params )
    end


    def valid_json?( json )
      begin
        JSON.parse( json )
        return true
      rescue JSON::ParserError => e
        @logger.error("json parse error: #{e}") if @debug
        return false
      end
    end

  end

end
