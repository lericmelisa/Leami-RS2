using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Leami.Model.Requests
{
    public class UserRegistrationRequest
    {
        [Required] public string FirstName { get; set; }=string.Empty;
        [Required] public string LastName { get; set; } = string.Empty;
        [Required, EmailAddress] public string Email { get; set; } = string.Empty;
      /*  [Required, MinLength(6)]*/ public string Password { get; set; } = string.Empty;
        //public string Gender { get; set; } = string.Empty;
        //public string? Address { get; set; }
        //public string? PostalCode { get; set; }
        public byte[]? UserImage { get; set; }

        //public int CityId { get; set; }
        //public City City { get; set; } = null!;
        public List<int>? RoleIds { get; set; }

    }
}
