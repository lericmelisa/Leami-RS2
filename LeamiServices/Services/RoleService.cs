using Leami.Model.Entities;
using Leami.Model.Requests;
using Leami.Model.Responses;
using Leami.Model.SearchObjects;
using Leami.Services.Database;
using Leami.Services.IServices;
using Mapster;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Leami.Services.Services
{
    public class RoleService :
        BaseCRUDService<RolesResponse, RoleSearchObject, Role, RoleInsertRequest, RoleInsertRequest>, IRoleService
    {
        private readonly LeamiDbContext _context;

        public RoleService(LeamiDbContext context, IMapper mapper) : base(context, mapper)
        {
            _context = context;
        }

        protected override IQueryable<Role> ApplyFilter(IQueryable<Role> query, RoleSearchObject search)
        {
            if (!string.IsNullOrWhiteSpace(search.FTS))
            {
                query = query.Where(x => x.Name.Contains(search.FTS));
            }

            return query;
        }

        public override async Task<List<RolesResponse>> GetAsync(RoleSearchObject search)
        {
            var roles = await _context.Roles.ToListAsync();
            return roles.Select(r => new RolesResponse
            {
                Roleid = r.Id,
                RoleName = r.Name ?? string.Empty,
                Description = r.Description
            }).ToList();
        }


    }

}
