class ProtectedTag::CreateAccessLevel < ActiveRecord::Base
  include ProtectedTagAccess

  def self.human_access_levels
    {
      Gitlab::Access::MASTER => "Masters",
      Gitlab::Access::DEVELOPER => "Developers + Masters",
      Gitlab::Access::NO_ACCESS => "No one"
    }.with_indifferent_access
  end

  def check_access(user)
    return false if access_level == Gitlab::Access::NO_ACCESS

    super
  end
end
