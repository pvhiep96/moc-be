class Inquiry < ApplicationRecord
  validates :full_name, :email, :message, presence: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }

  after_create :send_notification_email
  after_create_commit :send_thank_you_email

  private

  def send_notification_email
    InquiryMailer.new_inquiry_email(self).deliver_now
  end

  def send_thank_you_email
    InquiryMailer.thank_you(self).deliver_now
  end
end

# == Schema Information
#
# Table name: inquiries
#
#  id             :bigint           not null, primary key
#  full_name      :string
#  email          :string
#  location       :string
#  event_type     :string
#  role           :string
#  event_date     :date
#  event_location :string
#  budget         :string
#  instagram      :string
#  source         :string
#  message        :text
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#
