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
using Mapster;
using MapsterMapper;

namespace Leami.Services
{
    public class CategoryService:BaseCRUDService<CategoryResponse, CategorySearchObject, Category, CategoryInsertRequest, CategoryInsertRequest>, ICategoryService
    {
        private readonly LeamiDbContext _context;

        public CategoryService(LeamiDbContext context, IMapper mapper) : base(context, mapper)
        {
            _context = context;
        }

    }
}
