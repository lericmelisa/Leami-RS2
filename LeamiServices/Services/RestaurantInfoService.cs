using Leami.Model.Requests;
using Leami.Model.Responses;
using Leami.Model.SearchObjects;    
using Leami.Services.Database;
using Leami.Services.Database.Entities;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Mapster;
using MapsterMapper;
using Leami.Services.IServices;

namespace Leami.Services.Services
{
    public class RestaurantInfoService:BaseCRUDService<RestaurantInfoResponse, BaseSearchObject,RestaurantInfo,RestaurantInfoInsertRequest,RestaurantInfoUpdateRequest>, IRestaurantInfo
    {

        private readonly LeamiDbContext _context;
        public RestaurantInfoService(LeamiDbContext context, IMapper mapper) : base(context, mapper)
        {
            _context = context;
        }
        protected override IQueryable<RestaurantInfo> ApplyFilter(IQueryable<RestaurantInfo> query, BaseSearchObject search)
        {
            if (!string.IsNullOrWhiteSpace(search.FTS))
            {
                query = query.Where(x => x.Name.Contains(search.FTS));
            }
            return query;
        }   
    }
}
