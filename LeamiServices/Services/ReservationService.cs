using Leami.Model.Requests;
using Leami.Model.SearchObjects;
using Leami.Services.Database;
using Leami.Services.Database.Entities;
using Leami.Services.IServices;
using Microsoft.EntityFrameworkCore;
using RabbitMQ.Client;
using System.Text;
using MapsterMapper;
using Leami.Model.Responses;
using System.Collections.Generic;
using Leami.Model.Entities;


namespace Leami.Services.Services
{
    public class ReservationService : BaseCRUDService<ReservationResponse, ReservationSearchObject, Reservation, ReservationInsertRequest, ReservationUpdateRequest>, IReservationService
    {
        private readonly LeamiDbContext _context;
        private readonly IMapper mapper;
        private readonly IRabbitMQService _rabbitMQConnectionManager;
        private readonly IModel _channel;
        private readonly string _queueName = Environment.GetEnvironmentVariable("RABBITMQ_QUEUE") ?? "confirmentque";
        public ReservationService(LeamiDbContext context, IMapper _mapper, IRabbitMQService rabbitMQConnectionManager)
            : base(context, _mapper)
        {
            mapper = _mapper;
            _context = context;
            _rabbitMQConnectionManager = rabbitMQConnectionManager;
            _channel=rabbitMQConnectionManager.GetChannel();

        }
        protected override IQueryable<Reservation> ApplyFilter(
        IQueryable<Reservation> query,
          ReservationSearchObject? search = null)
        {
            query = query.Include(r => r.User);

            if (search?.ReservationDate != null)
            {
                query = query.Where(x => x.ReservationDate == search.ReservationDate);
            }
            if (search?.IsExpired != null)
            {
                var today = DateOnly.FromDateTime(DateTime.Now);

                if (search.IsExpired == true)
                {
                    query = query.Where(x => x.ReservationDate < today);
                }
                else
                {
                    query = query.Where(x => x.ReservationDate >= today);
                }
            }

                if (search?.ReservationDate != null)
            {
                query = query.Where(x => x.ReservationDate == search.ReservationDate);
            }

            if (search?.UserId != null)
            {
                query = query.Where(x => x.UserId == search.UserId);
            }

            if (search?.ReservationStatus != null)
            {
                query = query.Where(x => x.ReservationStatus == search.ReservationStatus);
            }

            return query;
        }

      
        public override async Task<ReservationResponse> UpdateAsync(int id, ReservationUpdateRequest update)
        {
            var reservation = await _context.Reservations
            .Include(r => r.User)
            .FirstOrDefaultAsync(r => r.ReservationId == id)
            .ConfigureAwait(false);

            if (reservation == null)
                return null; 

            reservation.ReservationStatus = update.ReservationStatus;

            await _context.SaveChangesAsync();

           var user = await _context.Users.FirstOrDefaultAsync(x => x.Id == update.UserId);

         
            if (user != null && !string.IsNullOrEmpty(user.Email))
            {
                
                var userEmail = user.Email;
              
                string statusText = update.ReservationStatus switch
                {
                    0 => "Declined",
                    1 => "Confirmed",
                    _ => "Unknown"
                };

                string message = $"Reservation updated for user: {user.Email}, Status: {statusText}, Date: {reservation.ReservationDate}";

                var notificationDto = new NotificationInsertRequest
                {
                    Message = message,
                    ReservationId = id,
                    UserId = user.Id
                };

                var notificationEntity = mapper.Map<Notification>(notificationDto);

                _context.Notifications.Add(notificationEntity);
                await _context.SaveChangesAsync();

               
                var payload = $"{user.Email}|{statusText}";
                var body = Encoding.UTF8.GetBytes(payload);

               _channel.BasicPublish(exchange: "",
                                      routingKey: _queueName,
                                      basicProperties: null,
                                      body: body);
            }


          return _mapper.Map<ReservationResponse>(update);
        }
      

    }
}
