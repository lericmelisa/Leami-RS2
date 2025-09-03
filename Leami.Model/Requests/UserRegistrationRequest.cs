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
        [Required(AllowEmptyStrings = false, ErrorMessage = "Username can not be empty.")]
        [MinLength(2, ErrorMessage = "Username can't be less than 2 characters.")]
        [MaxLength(50, ErrorMessage = "Username can't be more than 50 characters.")]
        public string? FirstName { get; set; } = string.Empty;


        [Required(AllowEmptyStrings = false, ErrorMessage = "Last name ne moze biti prazan.")]
        [MinLength(2, ErrorMessage = "Last name ne moze biti manje od dva karaktera.")]
        [MaxLength(50, ErrorMessage = "Last name can't be more than 50 characters.")]
        public string? LastName { get; set; } = string.Empty;


        [Required(AllowEmptyStrings = false, ErrorMessage = "Email ne moze biti prazan.")]
        [EmailAddress(ErrorMessage = "Email mora biti u validnom formatu example@smth.smth")]
        public string? Email { get; set; } = string.Empty;



        [Required(AllowEmptyStrings = false, ErrorMessage = "Password ne moze biti prazan.")]
        public string? Password { get; set; } = string.Empty;

        public byte[]? UserImage { get; set; }
        public List<int>? RoleIds { get; set; }
        public string? PhoneNumber { get; set; }

    }
}
