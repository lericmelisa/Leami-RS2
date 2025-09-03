using Leami.Services.Database.Entities;
using Microsoft.AspNetCore.Identity;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Leami.Services.Database.Entities
{
    public class Role : IdentityRole<int>   
    {
        public string? Description { get; set; }

    }
}
