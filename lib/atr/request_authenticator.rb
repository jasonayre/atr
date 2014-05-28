module Atr
  class RequestAuthenticator
    attr_accessor :request

    def initialize(request)
      @request = request
    end

    def matches?
      false
    end

    def params
      ::Hash[request.query_string.split("&").map{|seg| seg.split("=") }].with_indifferent_access
    end
  end
end