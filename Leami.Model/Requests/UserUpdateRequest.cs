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
        public byte[]? UserImage { get; set; }
        public List<int>? RoleIds { get; set; }
        public string? PhoneNumber { get; set; }
        public string? JobTitle { get; set; } = null!;
        public DateTime? HireDate { get; set; }
        public string? Note { get; set; } = string.Empty;


    }
}
