# SNS Topic for notifications
resource "aws_sns_topic" "qr_code_notification_topic" {
  name         = "QRCodeNotificationTopic"
  display_name = "QR Code Service"
}