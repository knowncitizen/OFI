# encoding: utf-8
module Staypuft
  class Deployment::CinderService::EquallogicValidator < ActiveModel::EachValidator
    def validate_each(record, attribute, value)
      return if value.empty?

      is_valid = true
      value.each_with_index do |v, index|
        attribute_with_index = "#{attribute}[#{index}]"
        is_valid = false unless validate_san_ip record, "#{attribute_with_index}[san_ip]", v["san_ip"]
        is_valid = false unless validate_san_login record, "#{attribute_with_index}[san_login]", v["san_login"]
        is_valid = false unless validate_eqlx_pool record, "#{attribute_with_index}[pool]", v["pool"]
        is_valid = false unless validate_eqlx_group_name record, "#{attribute_with_index}[group_name]", v["group_name"]
      end
      is_valid
    end

    private

    def validate_san_ip(record, attribute, san_ip)
      ip_addr = IPAddr.new(san_ip)
      ip_range = ip_addr.to_range
      if ip_range.begin == ip_range.end
        true
      else
        record.errors.add attribute, "Specify single IP address, not range"
        false
      end
    rescue
      # not IP addr
      # validating as fqdn
      if /(?=^.{1,254}$)(^(((?!-)[a-zA-Z0-9-]{1,63}(?<!-))|((?!-)[a-zA-Z0-9-]{1,63}(?<!-)\.)+[a-zA-Z]{2,63})$)/ =~ san_ip
        true
      else
        record.errors.add attribute, "Invalid IP address or FQDN supplied"
        false
      end
    end

    # Up to 16 alphanumeric characters, including period, hyphen, and underscore.
    # First character must be a letter or number.  Last character cannot be a period.
    # ASCII, Not Unicode
    def validate_san_login(record, attribute, san_login)
      is_valid = true
      if san_login.nil? or san_login.empty?
        record.errors.add attribute, "SAN login is required"
        is_valid = false
      else
        if not /\A[a-zA-Z\d][\w\.\-]*[\w\-]\z/ =~ san_login
          record.errors.add attribute, "SAN login contains invalid characters"
          is_valid = false
        end
        if san_login.length > 16
          record.errors.add attribute, "SAN login too long"
          is_valid = false
        end
      end
      is_valid
    end

    # Password must be 3 to 16 printable ASCII characters and is case-sensitive.
    # Punctuation characters are allowed, but spaces are not.
    # Only the first 8 characters are used, the rest are ignored (without a message).
    # ASCII, Not Unicode
    def validate_san_password(record, attribute, san_password)
      is_valid = true
      if san_password.nil? or san_password.empty?
        record.errors.add attribute, "SAN password is required"
        is_valid = false
      else
        if not /\A[!-~]+\z/ =~ san_password
          record.errors.add attribute, "SAN password contains invalid characters"
          is_valid = false
        end
        if san_password.length < 3
          record.errors.add attribute, "SAN password too short"
          is_valid = false
        end
        if san_password.length > 16
          record.errors.add attribute, "SAN password too long"
          is_valid = false
        end
      end
      is_valid
    end

    # Name can be up to 63 bytes and is case insensitive.
    # You can use any printable Unicode character except for
    # ! " # $ % & ' ( ) * + , / ; < = > ?@ [ \ ] ^ _ ` { | } ~.
    # First and last characters cannot be a period, hyphen, or colon.
    # Fewer characters are accepted for this field if you enter the value as a
    # Unicode character string, which takes up a variable number of bytes,
    # depending on the specific character.
    # ASCII, Unicode
    def validate_eqlx_pool(record, attribute, eqlx_pool)
      is_valid = true
      if eqlx_pool.nil? or eqlx_pool.empty?
        record.errors.add attribute, "EqualLogic pool is required"
        is_valid = false
      else
        if not /\A[[^\p{Z}\p{C}!"\#$%&'\(\)\*\+,\/;<=>\?@\[\]\\\^\{\}|~\.\-:]][[^\p{Z}\p{C}!"\#$%&'\(\)\*\+,\/;<=>\?@\[\]\\\^\{\}|~]]+[[^\p{Z}\p{C}!"\#$%&'\(\)\*\+,\/;<=>\?@\[\]\\\^\{\}|~\.\-:]]\z/ =~ eqlx_pool
          record.errors.add attribute, "EqualLogic pool contains invalid characters"
          is_valid = false
        end
        if eqlx_pool.bytes.to_a.length > 63
          record.errors.add attribute, "Too long: max length is %{count} bytes. Using multibyte characters reduces the maximum number of characters allowed."
          is_valid = false
        end
      end
      is_valid
    end

    # Up to 54 alphanumeric characters and hyphens(dashes).
    # The first character must be a letter or a number.
    # ASCII, Not Unicode
    def validate_eqlx_group_name(record, attribute, eqlx_group_name)
      is_valid = true
      if eqlx_group_name.nil? or eqlx_group_name.empty?
        record.errors.add attribute, "EqualLogic group name is required"
        is_valid = false
      else
        if not /\A[a-zA-Z\d][a-zA-Z\d\-]*\z/ =~ eqlx_group_name
          record.errors.add attribute, "EqualLogic group name contains invalid characters"
          is_valid = false
        end
        if eqlx_group_name.length > 54
          record.errors.add attribute, "EqualLogic group name too long"
          is_valid = false
        end
      end
      is_valid
    end

  end
end
