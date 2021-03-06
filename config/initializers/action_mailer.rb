ActionMailer::Base.smtp_settings = {
  address: ENV['SMTP_SERVER'] || "mailcatcher",
  port: ENV['SMTP_PORT'] || 25,
  domain: ENV['SMTP_DOMAIN'],
  authentication: ENV['SMTP_AUTHENTICATION'] == 'none' ? nil : ENV['SMTP_AUTHENTICATION'] || "plain",
  enable_starttls_auto: ENV['SMTP_ENABLE_STARTTLS_AUTO'] == 'false',
  ssl: ENV['SMTP_SSL'] == 'false',
  user_name: ENV['SMTP_USER_NAME'] == '' ? nil : ENV['SMTP_USER_NAME'].presence,
  password: ENV['SMTP_USER_NAME'] == '' ? nil : ENV['SMTP_PASSWORD'].presence,
  openssl_verify_mode: ENV['SMTP_OPENSSL_VERIFY_MODE'].presence,
  ca_path: ENV['SMTP_OPENSSL_CA_PATH'].presence,
  ca_file: ENV['SMTP_OPENSSL_CA_FILE'].presence
}
