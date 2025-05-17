module Nexo
  class ApiResponse < Struct.new(:status, :etag, :payload)
  end
end
