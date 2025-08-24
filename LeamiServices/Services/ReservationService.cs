using Leami.Model.Requests;
using Leami.Model.Responses;
using Leami.Model.SearchObjects;
using Leami.Services.Database.Entities;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Mapster;
using MapsterMapper;
using Leami.Services.Database;
using Microsoft.EntityFrameworkCore;
using Leami.Services.IServices;


namespace Leami.Services.Services
{
    public class ReservationService : BaseCRUDService<ReservationResponse, ReservationSearchObject, Reservation, ReservationInsertRequest, ReservationUpdateRequest>, IReservationService
    {

        private readonly LeamiDbContext _context;

        public ReservationService(LeamiDbContext context, IMapper mapper) : base(context, mapper)
        {
            _context = context;
        }
        protected override IQueryable<Reservation> ApplyFilter(IQueryable<Reservation> query, ReservationSearchObject search)
        {
            query = query.Include(r => r.User);


            if (search.ReservationDate.HasValue)
            {
                query = query.Where(r => r.ReservationDate == search.ReservationDate.Value);
            }

            // Filtriraj po korisniku
            if (search.UserId.HasValue)
            {
                query = query.Where(r => r.UserId == search.UserId.Value);
            }


            if (search.IsExpired.HasValue)
            {
                var today = DateOnly.FromDateTime(DateTime.Now);
                if (search.IsExpired.Value)
                {
                    // istekle: datum manje od danas
                    query = query.Where(r => r.ReservationDate < today);
                }
                else
                {
                    // aktivne: datum >= danas
                    query = query.Where(r => r.ReservationDate >= today);
                }
            }

            return query;
        }
    }
}
