using Microsoft.Extensions.Configuration;
using MimeKit;
using MailKit.Net.Smtp;
using RabbitMQ.Client;
using RabbitMQ.Client.Events;
using System;
using System.IO;
using System.Text;
using static Org.BouncyCastle.Crypto.Engines.SM2Engine;

public class ReservationEmailConsumer
{
    private readonly IModel _channel;
    private readonly IConfiguration _configuration;
    private readonly EmailService _emailService;

    private readonly string _host = Environment.GetEnvironmentVariable("RABBITMQ_HOST") ?? "localhost";
    private readonly string _username = Environment.GetEnvironmentVariable("RABBITMQ_USERNAME") ?? "guest";
    private readonly string _password = Environment.GetEnvironmentVariable("RABBITMQ_PASSWORD") ?? "guest";
  
    public ReservationEmailConsumer(IConfiguration configuration, EmailService emailService)
    {
        _configuration = configuration;
        _emailService = emailService;
       
        var factory = new ConnectionFactory
        {
            HostName = _host,
            UserName = _username,
            Password = _password
        };
        var connection = factory.CreateConnection();
        _channel = connection.CreateModel();
    }

    public void SendEmail()
    {
        _channel.QueueDeclare(queue: Environment.GetEnvironmentVariable("RABBITMQ_QUEUE"),
                             durable: false,
                             exclusive: false,
                             autoDelete: false,
                             arguments: null);

        var consumer = new EventingBasicConsumer(_channel);
        consumer.Received += (model, ea) =>
        {
            //var body = ea.Body.ToArray();
            //var message = Encoding.UTF8.GetString(body);
            //Console.WriteLine(" [x] Received {0}", message);
            //var email = ExtractEmailFromMessage(message);


            var payload = Encoding.UTF8.GetString(ea.Body.ToArray());
            Console.WriteLine(" [x] Received {0}", payload);

            // 1) Split po char separatoru '|'
            var parts = payload.Split('|');
            if (parts.Length != 2)
            {
                Console.WriteLine("Neispravan payload format");
                return;
            }

            var email = parts[0];   // npr. "user@example.com"
            var status = parts[1];   // "Confirmed" ili "Declined"

            // 2) Sastavi poruku
            var bodyText = $"Your reservation has been {status.ToLower()}.";
            if (!string.IsNullOrEmpty(email))
            {
                Console.WriteLine(" [x] Received {0}", bodyText);
                _emailService.SendEmail(email,bodyText);
            }
        };
        _channel.BasicConsume(queue: Environment.GetEnvironmentVariable("RABBITMQ_QUEUE"),
                             autoAck: true,
                             consumer: consumer);
    }

    private string ExtractEmailFromMessage(string message)
    {
        var parts = message.Split(' ');
        return parts.Length > 3 ? parts[3] : string.Empty;
    }
}