using Leami.Model.SearchObjects;
using Leami.Services.Database;
using Leami.Services.IServices;
using Mapster;
using MapsterMapper;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Leami.Services.Services
{
    public abstract class BaseCRUDService<T, TSearch, TEntity, TInsert, TUpdate> :
        BaseService<T, TSearch, TEntity>,
        ICRUDService<T, TSearch, TInsert, TUpdate>
        where T : class
        where TSearch : BaseSearchObject
        where TEntity : class, new()
        where TInsert : class
        where TUpdate : class
    {
        private readonly LeamiDbContext _context;
        protected readonly IMapper _mapper;

        public BaseCRUDService(LeamiDbContext context, IMapper mapper) : base(context, mapper)
        {
            _context = context;
            _mapper = mapper;

        }

        public virtual async Task<T> CreateAsync(TInsert request)
        {
            var entity = new TEntity();
            MapToEntityInsert(entity, request);
            _context.Set<TEntity>().Add(entity);

            await BeforeInsert(entity, request);


            await _context.SaveChangesAsync();
            return MapToResponse(entity);
        }

        protected virtual async Task BeforeInsert(TEntity entity, TInsert request)
        {

        }
        protected virtual TEntity MapToEntityInsert(TEntity entity, TInsert request)
        {
            return _mapper.Map(request, entity);
        }






        public virtual async Task<T> UpdateAsync(int id, TUpdate request)
        {
            var entity = await _context.Set<TEntity>().FindAsync(id);
            if (entity == null)
                return null;


            await BeforeUpdate(entity, request);

            MapToEntityUpdate(entity, request);

            await _context.SaveChangesAsync();
            return MapToResponse(entity);
        }

        protected virtual async Task BeforeUpdate(TEntity entity, TUpdate request)
        {

        }
        protected virtual void MapToEntityUpdate(TEntity entity, TUpdate request)
        {
            _mapper.Map(request, entity);

        }



        public async Task<bool> DeleteAsync(int id)
        {
            var entity = await _context.Set<TEntity>().FindAsync(id);
            if (entity == null)
                return false;


            await BeforeDelete(entity);


            _context.Set<TEntity>().Remove(entity);
            await _context.SaveChangesAsync();
            return true;
        }

        protected virtual async Task BeforeDelete(TEntity entity)
        {

        }



















    }

}
