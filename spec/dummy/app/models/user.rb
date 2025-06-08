class User < ApplicationRecord
  def to_s
    email
  end
end
