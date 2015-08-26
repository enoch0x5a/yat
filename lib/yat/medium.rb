require 'celluloid/current'

module YandexTranslator
  class Medium
    include Celluloid
    include Celluloid::Notifications

    # finalizer :finalize

    # def finalize
    #   p "generic dead!"
    # end

    def initialize
      subscribe(:connection_response, :stash_response)

      @responses = Array.new
      @response_num = 0
      @request_index = 0
      @request_max = YandexTranslator::configuration.maximum_requests
    end

    [:getLangs, :translate, :detect].each do |method|
      define_method(method) do |format, params|
       
        if params && params.has_key?(:text)
          @request_estimate = (
            Float(params[:text].length) / 
            YandexTranslator.configuration.chunk_size
            ).ceil

          split_input(params[:text]).each { |chunk|
            params[:text] = chunk
            request(__method__, format, params)
          }
        else
          @request_estimate = 1
          request(__method__, format, params)
        end
      end
    end

    def stash_response(topic, index, response)
      signal :continue

      @responses[index] = response
      @response_num += 1

      if @response_num == @request_estimate
        publish(:translator_ready, @responses)
        @request_index = @response_num = 0
      end
    end

  protected
    def request(function, format, params)
      raise ArgumentError, "wrong format: #{format}" unless (YandexTranslator::configuration.instance_eval("#{format}_path") rescue nil)
      raise NoApiKey, "provide api key" if (key = YandexTranslator::configuration.api_key).nil?

      params[:key] = YandexTranslator::configuration.api_key

      uri = URI(YandexTranslator::configuration.instance_eval("host + #{format}_path"))
      uri.path += "/#{function}"

      if @request_index - @response_num == @request_max
        wait :continue
      end

      Connection.new_link.async.request(uri, @request_index, params)
      @request_index += 1
    end
    
    def split_input(input)
      str = String.new
      chunks = Array.new
      chunk_size = YandexTranslator::configuration.chunk_size
      while str.length + input.length > chunk_size
        str = input.slice!(0, chunk_size)
        chunks << str.dup
        str.clear
      end
      chunks << input.dup unless input.nil?
    end
  end
end
