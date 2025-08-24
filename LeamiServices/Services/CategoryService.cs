using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Leami.Model.Entities;
using Leami.Model.Requests;
using Leami.Model.Responses;
using Leami.Model.SearchObjects;
using Leami.Services.Database;
using Leami.Services.Database.Entities;
using Leami.Services.IServices;
using Mapster;
using MapsterMapper;

namespace Leami.Services.Services
{
    public class CategoryService : BaseCRUDService<CategoryResponse, CategorySearchObject, Category, CategoryInsertRequest, CategoryInsertRequest>, ICategoryService
    {
        private readonly LeamiDbContext _context;

        public CategoryService(LeamiDbContext context, IMapper mapper) : base(context, mapper)
        {
            _context = context;
        }

        protected override IQueryable<Category> ApplyFilter(IQueryable<Category> query, CategorySearchObject search)
        {


            if (!string.IsNullOrEmpty(search.FTS))
            {
                query = query.Where(pt => pt.CategoryName.Contains(search.FTS));
            }
            return query;
        }

    }
}
