require 'net/http'

module YandexTranslator

  class GenericTranslator
    attr_reader :response

    def initialize
      @response = nil
    end

private
    def method_missing(api_function, *args)
      @response = make_request(api_function, *args)

      if @response.code == '404'
        raise YandexTranslator::ApiFunctionNotSupported, "#{api_function}"
      else
        GenericTranslator.send(:define_method, api_function) do |*args|
           make_request(__method__, *args)
        end
      end
      @response
    end

protected
    def make_request(function, format, params = nil)
      raise ArgumentError, "wrong format: #{format}" if YandexTranslator::configuration.instance_eval("#{format}_path").nil?

      raise NoApiKey, "provide api key" if (key = YandexTranslator::configuration.api_key).nil?
      
      params[:key] = key 

      uri = URI(YandexTranslator::configuration.instance_eval("#{format}_path"))
      uri.path += "/#{function}"
      
      Net::HTTP.start(uri.host, uri.port,
        :use_ssl => uri.scheme == 'https') do |https|
        request = Net::HTTP::Post.new(uri)
        @response = https.request(request, URI.encode_www_form(params))
      end
    end

    def error_check(return_code)
      unless return_code.nil? || return_code == 200
        raise YandexTranslator::ReturnCodeException, case return_code.to_i
          when 401
            "401: wrong api key"
          when 402
            "402: api key blocked"
          when 403
            "403: daily request limit exceeded"
          when 404
            "404: daily text volume limit exceeded"
          when 413
            "413: text size too big"
          when 422
            "422: unable to translate"
          when 501
            "501: translation direction is not supported"
        end
      end
    end
  end #  class GenericTranslator
end
