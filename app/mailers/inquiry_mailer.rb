# app/mailers/inquiry_mailer.rb
class InquiryMailer < ApplicationMailer
  # default from: "Your App <noreply@yourapp.com>"
  default from: "Moc Productions <info@mocnguyenproductions.com>"

  def new_inquiry_email(inquiry)
    @inquiry = inquiry
    mail(
      to: "info@mocnguyenproductions.com",  # Change to your admin email
      subject: "New Inquiry: #{@inquiry.full_name} (#{@inquiry.event_type})"
    )
  end

  # CONFIRMATION TO CUSTOMER
  def thank_you(inquiry)
    @inquiry = inquiry
    mail(
      to: inquiry.email,
      subject: "Thank you for your inquiry!"
    )
  end
end
