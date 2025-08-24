using Leami.Model.Responses;
using Leami.Model.SearchObjects;
using Leami.Services.Database;
using Leami.Services.IServices;
using Mapster;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Conventions;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Leami.Services.Services
{
    public class BaseService<T, TSearch, TEntity> : IService<T, TSearch>
        where T : class
        where TSearch : BaseSearchObject
        where TEntity : class
    {
        private readonly LeamiDbContext _context;
        private readonly IMapper _mapper;
        public BaseService(LeamiDbContext context, IMapper mapper)
        {
            _context = context;
            _mapper = mapper;

        }

        public virtual async Task<List<T>> GetAsync(TSearch search)
        {
            var query = _context.Set<TEntity>().AsQueryable();
            query = ApplyFilter(query, search);


            var list = await query.ToListAsync();

            return list.Select(MapToResponse).ToList();


        }

        protected virtual IQueryable<TEntity> ApplyFilter(IQueryable<TEntity> query, TSearch search)
        {
            // This method should be overridden in derived classes to apply specific filters based on the search object.
            return query;
        }
        public virtual async Task<T?> GetByIdAsync(int id)
        {
            var entity = await _context.Set<TEntity>().FindAsync(id);
            if (entity == null)
            {
                return null;
            }
            return MapToResponse(entity);
        }

        protected virtual T MapToResponse(TEntity entity)
        {
            return _mapper.Map<T>(entity);


        }


    }
}
