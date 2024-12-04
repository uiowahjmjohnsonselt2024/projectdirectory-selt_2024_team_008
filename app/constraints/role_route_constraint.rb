class RoleRouteConstraint
  def initialize(&block)
    @block = block
  end

  def matches?(request)
    user = current_user(request)
    user.present? && @block.call(user)
  end

  private

  def current_user(request)
    User.find_by_id(request.session["warden.user.user.key"]&.dig(0, 0))
  end
end