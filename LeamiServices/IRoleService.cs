using Leami.Model.Requests;
using Leami.Model.Responses;
using Leami.Model.SearchObjects;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Leami.Services
{
    public interface IRoleService: ICRUDService<RolesResponse, RoleSearchObject, RoleInsertRequest, RoleInsertRequest>
       
    {

    }
}
