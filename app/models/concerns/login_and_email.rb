module LoginAndEmail
  extend ActiveSupport::Concern

  module ClassMethods
    # Devise method overridden to allow sing in with email or login
    def find_for_database_authentication(warden_conditions)
      conditions = warden_conditions.dup
      if login = conditions.delete(:login)
        where(conditions).where(["lower(login) = :value OR lower(email) = :value", { value: login.downcase }]).first
      else
        where(conditions).first
      end
    end
  end
end