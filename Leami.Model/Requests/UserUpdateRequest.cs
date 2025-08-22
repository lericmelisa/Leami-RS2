using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Linq;
using System.Text;
using System.Threading.Tasks;


namespace Leami.Model.Requests
{
    public class UserUpdateRequest
    {
      public string? FirstName { get; set; } = string.Empty;
      public string? LastName { get; set; } = string.Empty;
      public string? Email { get; set; } = string.Empty;
      
      public string? Password { get; set; } = string.Empty;
        //public string Gender { get; set; } = string.Empty;
        //public string? Address { get; set; }
        //public string? PostalCode { get; set; }
        public byte[]? UserImage { get; set; }

        //public int CityId { get; set; }
        //public City City { get; set; } = null!;
        public List<int>? RoleIds { get; set; }


        //za employe
        public string? JobTitle { get; set; } = null!;

    
        public DateTime? HireDate { get; set; }

        public string? Note { get; set; } = string.Empty;


    }
}
