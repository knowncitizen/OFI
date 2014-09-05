#encoding: utf-8
module Staypuft
  class Deployment::CinderService::Equallogic
    attr_accessor :id, :san_ip, :san_login, :san_password, :pool, :group_name

    def initialize(attributes = {})
      attributes.each { |attr, value| send "#{attr}=", value } unless attributes.nil?
    end
  end
end
