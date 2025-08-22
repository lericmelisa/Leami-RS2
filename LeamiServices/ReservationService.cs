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


namespace Leami.Services
{
    public class ReservationService:BaseCRUDService<ReservationResponse,ReservationSearchObject,Reservation,ReservationInsertRequest,ReservationUpdateRequest>,IReservationService
    {

        private readonly LeamiDbContext _context;
      
        public ReservationService(LeamiDbContext context, IMapper mapper) : base(context, mapper)
        {
            _context = context;
        }
        protected override IQueryable<Reservation> ApplyFilter(IQueryable<Reservation> query, ReservationSearchObject search)
        {
            if (search.ReservationDate.HasValue)
            {
                query = query.Where(r => r.ReservationDate == search.ReservationDate.Value);
            }
            if (search.UserId.HasValue)
            {
                query = query.Where(r => r.UserId == search.UserId.Value);
            }
            return query;
        }
    }
}
