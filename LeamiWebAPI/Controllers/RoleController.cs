using Leami.Model.Requests;
using Leami.Model.Responses;
using Leami.Model.SearchObjects;
using Leami.Services.IServices;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace LeamiWebAPI.Controllers
{
    [ApiController]
    [Route("[controller]")]
    public class RoleController : BaseCRUDController<RolesResponse, RoleSearchObject, RoleInsertRequest, RoleInsertRequest>
    {

        public readonly IRoleService roleService;
        public RoleController(IRoleService _service) : base(_service)
        {
        }
      

    }
}
