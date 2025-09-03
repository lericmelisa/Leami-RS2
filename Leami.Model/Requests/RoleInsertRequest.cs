using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Leami.Model.Requests
{
    public class RoleInsertRequest
    {
        [Required(AllowEmptyStrings = false, ErrorMessage = "Role ne moze biti prazan.")]
        [MinLength(2, ErrorMessage = "Role name ne moze biti manje od dva karaktera.")]
        [MaxLength(50, ErrorMessage = "Role name ne moze biti vise od 50 karaktera.")]
        public string RoleName { get; set; } = string.Empty;

        public string? Description { get; set; } = string.Empty;
    }
}
