class AuthError < StandardError
  def initialize(msg="Could not authenticate to pooler")
    super
  end
end
