# Provides a Concern for any Model class, entities of which should NEVER be destroyed.
# In model class use it with
#   include Nondeletable
# somewhere inside the model class definition. This guards against "destroy", probably
# not effective against "delete".

module Nondeletable
  extend ActiveSupport::Concern

  included do
    before_destroy :prevent_destroy
  end

  private

  def prevent_destroy
    logger.error "PREVENTING DESTROY of #{self.class.name}!!!"
    errors.add :base, "Entities of #{self.class.name} cannot be destroyed!"
    false
  end

end
