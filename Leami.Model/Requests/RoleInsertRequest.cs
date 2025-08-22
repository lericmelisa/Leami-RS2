using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Leami.Model.Requests
{
    public class RoleInsertRequest
    {
        public string? RoleName { get; set; } = string.Empty;
        public string? Description { get; set; } = string.Empty;
    }
}
