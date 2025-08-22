using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Leami.Model.Responses
{
    public class RolesResponse
    {
        public int Roleid { get; set; }
        public string? RoleName { get; set; } = string.Empty;
        public string? Description { get; set; } = string.Empty; 
    }
}
