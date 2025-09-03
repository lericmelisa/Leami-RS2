using RabbitMQ.Client;
using Leami.Services.IServices; 

namespace Leami.Services.Services
{
    public class RabbitMQConnectionManager : IRabbitMQService,IDisposable
    {
        private readonly ConnectionFactory _factory;
        private IConnection? _connection;
        private bool _disposed = false;
        private readonly IModel channel;

        public RabbitMQConnectionManager()
        {
            var host = Environment.GetEnvironmentVariable("RABBITMQ_HOST") ?? "localhost";
            var username = Environment.GetEnvironmentVariable("RABBITMQ_USERNAME") ?? "guest";
            var password = Environment.GetEnvironmentVariable("RABBITMQ_PASSWORD") ?? "guest";
            var port = int.TryParse(Environment.GetEnvironmentVariable("RABBITMQ_PORT"), out var p) ? p : 5672;

            _factory = new ConnectionFactory()
            {
                HostName = host,
                UserName = username,
                Password = password,
                Port = port,
            };

            _connection = _factory.CreateConnection();
            channel = _connection.CreateModel();
            var queueName = Environment.GetEnvironmentVariable("RABBITMQ_QUEUE") ?? "confirmentque";
            
            channel.QueueDeclare(
                queue: queueName,
                durable: false,
                exclusive: false,
                autoDelete: false,
                arguments: null);
        }
        public IModel GetChannel() => channel;


        public void Dispose()
        {
            if (_disposed)
                return;

            _connection?.Dispose();
            _disposed = true;
        }
    }
}
