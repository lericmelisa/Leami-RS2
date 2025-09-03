using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Leami.Model.Responses
{
    public class UserResponse
    {
        public int Id { get; set; }
        public string FirstName { get; set; } = string.Empty;
        public string LastName { get; set; } = string.Empty;
        public string Email { get; set; } = string.Empty;
        public string Username { get; set; } = string.Empty;
        public DateTime Created { get; set; }
        public DateTime? LastLoginAt { get; set; }
        public string? PhoneNumber { get; set; }

        public RolesResponse Role { get; set; } = new();

        public string Token { get; set; } = "";
        public DateTime Expiration { get; set; }
        public byte[]? UserImage { get; set; }
        public string? JobTitle { get; set; } = null!;

       
        public DateTime? HireDate { get; set; }

        public string? Note { get; set; } = string.Empty;

    }
}
