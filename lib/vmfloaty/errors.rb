class AuthError < StandardError
  def initialize(msg="Could not authenticate to pooler")
    super
  end
end

class TokenError < StandardError
  def initialize(msg="Could not do operation with token provided")
    super
  end
end

class MissingParamError < StandardError
  def initialize(msg="Argument provided to function is missing")
    super
  end
end
