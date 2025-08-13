using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Data;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

using Microsoft.AspNetCore.Identity;    

namespace Leami.Model.Entities
{
    public class User : IdentityUser<int>
    {
        [MaxLength(50)] public string FirstName { get; set; } = string.Empty;
        [MaxLength(50)] public string LastName { get; set; } = string.Empty;
        public DateTime? Created { get; set; } = DateTime.UtcNow;
        public string? Gender { get; set; } = string.Empty;
        public string? Address { get; set; }
        public string? PostalCode { get; set; }
        public byte[]? Image { get; set; }

        public int? CityId { get; set; }
        public City? City { get; set; } = null!;
        public DateTime? LastLoginAt { get; set; }
    }
}
