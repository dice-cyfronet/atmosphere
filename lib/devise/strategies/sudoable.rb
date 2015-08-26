module Devise
  module Strategies
    module Sudoable
      private

      def sudo_as
        params[:sudo] || request.headers['HTTP-SUDO']
      end

      def sudo!(user, sudo_as)
        sudo_fail!(403, 'Must be admin to use sudo') unless user.admin?
        user = Atmosphere::User.find_by(login: sudo_as)
        sudo_fail!(404, "No user login for: #{sudo_as}") unless user

        user
      end

      def sudo_fail!(status, msg)
        body = { error: msg }
        headers = { 'Content-Type' => 'application/json; charset=utf-8' }

        custom! [status, headers, [body.to_json]]
        throw :warden
      end
    end
  end
end
