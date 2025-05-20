module Nexo
  class ApiResponse < Struct.new(:status, :etag, :payload, :id)
  end
end
