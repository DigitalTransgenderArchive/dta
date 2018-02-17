class User < ActiveRecord::Base
  include Hydra::RoleManagement::UserRoles

  if Blacklight::Utils.needs_attr_accessible?
    attr_accessible :email, :password, :password_confirmation
  end
  # Connects this user object to Blacklights Bookmarks.
  include Blacklight::User

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  # Method added by Blacklight; Blacklight uses #to_s on your
  # user class to get a user-displayable login/identifier for
  # the account.
  def to_s
    email
  end

  def admin?
    return true
    #roles.where(name: 'admin').exists? || roles.where(name: 'superuser').exists?
  end

  def superuser?
    return false
  	#roles.where(name: 'superuser').exists?
  end

  def contributor?
    return false
    #roles.where(name: 'contributor').exists? || roles.where(name: 'admin').exists? || roles.where(name: 'superuser').exists?
  end

  def homosaurus?
    return false
    #roles.where(name: 'homosaurus').exists? || roles.where(name: 'admin').exists? || roles.where(name: 'superuser').exists?
  end

  def is_infosec?
    return self.superuser?
  end

end
