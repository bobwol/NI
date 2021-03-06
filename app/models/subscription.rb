class Subscription < ActiveRecord::Base

  belongs_to :user

  validates_presence_of :valid_from, :duration

  # PayPal encryption
  # TODO: Do we need to implement this for Purhcase/Subscriptions?
  def encrypt_for_paypal(values)
    signed = OpenSSL::PKCS7::sign(OpenSSL::X509::Certificate.new(ENV["APP_CERT_PEM"]),        OpenSSL::PKey::RSA.new(ENV["APP_KEY_PEM"], ''), values.map { |k, v| "#{k}=#{v}" }.join("\n"), [], OpenSSL::PKCS7::BINARY)
    OpenSSL::PKCS7::encrypt([OpenSSL::X509::Certificate.new(ENV["PAYPAL_CERT_PEM"])], signed.to_der, OpenSSL::Cipher::Cipher::new("DES3"),        OpenSSL::PKCS7::BINARY).to_s.gsub("\n", "")
  end

  # def recurring?
	#   return (not self.paypal_profile_id.nil?)
  # end

  def is_current?
    if is_cancelled? and was_recurring? and refunded_on.nil?
      return (expiry_date > DateTime.now)
    else
      return (expiry_date > DateTime.now and (not is_cancelled?))
    end
  end

  def expiry_date
    if was_recurring? and refunded_on.nil?
      return (valid_from + duration.months)
    else
      return (cancellation_date or (valid_from + duration.months))
    end
  end

  def expiry_date_excluding_cancelled
    return (valid_from + duration.months)
  end

  def is_recurring?
  	 return (was_recurring? and (not is_cancelled?))
  end

  def was_recurring?
  	return (not self.paypal_profile_id.blank?)
  end

  def is_cancelled?
    return ( not ( cancellation_date.nil? or cancellation_date > DateTime.now ))
  end

  # From controller

  def calculate_refund
    # TODO: Write autodebit renewal after we've implemented it.
    # FIXME: write the logic to calculate refunds properly.
    self.refund = [0,(1-(used_days/total_days))*self.price_paid].max.floor
    logger.warn "Refund of #{self.refund} cents due."
  end

  def used_days
    return [0,(DateTime.now - self.valid_from.to_datetime).to_f].max
  end

  def total_days
    return (self.expiry_date.to_datetime - self.valid_from.to_datetime).to_f
  end

  def expire_subscription
    self.calculate_refund
    self.cancellation_date = DateTime.now
  end

  def self.calculate_subscription_price(duration, options = {})
    special = options[:special] or false
    autodebit = options[:autodebit] or false
    paper = options[:paper] or false
    institution = options[:institution] or false
    if autodebit
        case duration
        when 3
            price = Settings.subscription_price * duration * 15 / 18
        when 6
            price = Settings.subscription_price * duration * 25 / 36
        when 12
            price = Settings.subscription_price * duration * 40 / 72
        end
    else
        case duration
        when 3
          price = Settings.subscription_price * duration
        when 6
          price = Settings.subscription_price * duration * 30 / 36
        when 12
          price = Settings.subscription_price * duration * 50 / 72
        end
    end
    if paper
      case duration
      when 3
        price += 1400
      when 6
        price += 3000
      when 12
        price += 6000
      end
    end
    if special
      if paper
        price -= 4400
      else
        price -= 2200
      end
    end
    if institution
      if autodebit and paper
        price += 10000
      elsif autodebit and not paper
        price += 14000
      elsif not autodebit and paper
        price += 13000
      elsif not autodebit and not paper
        price += 17000
      end
    end
    return price
  end

end
