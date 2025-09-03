using MimeKit;
using MailKit.Net.Smtp;
using Microsoft.Extensions.Configuration;

public class EmailService
{
    private readonly IConfiguration _configuration;

    public EmailService(IConfiguration configuration)
    {
        _configuration = configuration;
    }

    public void SendEmail(string recipientEmail, string message)
    {
        var emailMessage = new MimeMessage();
        var smtpPort = int.Parse(_configuration["SMTP_PORT"] ?? throw new InvalidOperationException("SMTP_PORT nije definiran"));
        var smtpHost = Environment.GetEnvironmentVariable("SMTP_HOST")?? throw new InvalidOperationException("SMTP_HOST nije definiran");


        var fromEmail = _configuration["SMTP_USERNAME"] ?? throw new InvalidOperationException("SMTP_USERNAME nije definiran");

        emailMessage.From.Add(new MailboxAddress("Leami Restaurant Reservation Service", fromEmail));
        emailMessage.To.Add(new MailboxAddress("Customer", recipientEmail));
        emailMessage.Subject = "Reservation Status Notification";
        emailMessage.Body = new TextPart("plain")
        {
            Text = message
        };

        using var client = new SmtpClient();
        try
        {
            client.Connect(smtpHost, smtpPort, false);

            var smtpPass = _configuration["SMTP_PASSWORD"] ?? throw new InvalidOperationException("SMTP_PASSWORD nije definiran");
            var smtpUser = _configuration["SMTP_USERNAME"] ?? throw new InvalidOperationException("SMTP_USERNAME nije definiran");

            client.Authenticate(smtpUser, smtpPass);

            client.Send(emailMessage);
        }
        catch (Exception ex)
        {
            Console.WriteLine($"An error occurred while sending email to {recipientEmail}: {ex.Message}");
        }
        finally
        {
            client.Disconnect(true);
            client.Dispose();
        }
    }
}
