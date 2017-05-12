module RepositoryOwner
  class Github < Base
    def avatar_url(size = 60)
      "https://avatars.githubusercontent.com/u/#{owner.uuid}?size=#{size}"
    end

    def repository_url
      "https://github.com/#{owner.login}"
    end

    def self.fetch_user(id_or_login)
      api_client.user(id_or_login)
    rescue *RepositoryHost::Github::IGNORABLE_EXCEPTIONS
      nil
    end

    def self.api_client(token = nil)
      AuthToken.fallback_client(token)
    end

    def self.create_org(org_hash)
      org_hash = org_hash.to_hash.with_indifferent_access
      org = nil
      org_by_id = RepositoryOrganisation.host('GitHub').find_by_uuid(org_hash[:id])
      org_by_login = RepositoryOrganisation.host('GitHub').where("lower(login) = ?", org_hash[:login].try(:downcase)).first
      if org_by_id # its fine
        if org_by_id.login.try(:downcase) == org_hash[:login].downcase && org_by_id.user_type == org_hash[:type]
          org = org_by_id
        else
          if org_by_login && !org_by_login.download_org_from_host
            org_by_login.destroy
          end
          org_by_id.login = org_hash[:login]
          org_by_id.user_type = org_hash[:type]
          org_by_id.save!
          org = org_by_id
        end
      elsif org_by_login # conflict
        if org_by_login.download_org_from_host_by_login
          org = org_by_login if org_by_login.uuid == org_hash[:id]
        end
        org_by_login.destroy if org.nil?
      end
      if org.nil?
        org = RepositoryOrganisation.create!(uuid: org_hash[:id], login: org_hash[:login], user_type: org_hash[:type], host_type: 'GitHub')
      end
      org.update(org_hash.slice(:name, :company, :blog, :location, :email, :bio))
      org
    end

    def self.create_user(user_hash)
      user_hash = user_hash.to_hash.with_indifferent_access
      user = nil
      user_by_id = RepositoryUser.host('GitHub').find_by_uuid(user_hash[:id])
      user_by_login = RepositoryUser.host('GitHub').where("lower(login) = ?", user_hash[:login].try(:downcase)).first
      if user_by_id # its fine
        if user_by_id.login.try(:downcase) == user_hash[:login].downcase && user_by_id.user_type == user_hash[:type]
          user = user_by_id
        else
          if user_by_login && !user_by_login.download_user_from_host
            user_by_login.destroy
          end
          user_by_id.login = user_hash[:login]
          user_by_id.user_type = user_hash[:type]
          user_by_id.save!
          user = user_by_id
        end
      elsif user_by_login # conflict
        if user_by_login.download_user_from_host_by_login
          user = user_by_login if user_by_login.uuid == user_hash[:id]
        end
        user_by_login.destroy if user.nil?
      end
      if user.nil?
        user = RepositoryUser.create!(uuid: user_hash[:id], login: user_hash[:login], user_type: user_hash[:type], host_type: 'GitHub')
      end
      user.update(user_hash.slice(:name, :company, :blog, :location, :email, :bio))
      user
    end
  end
end
