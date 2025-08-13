using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Leami.Model.Entities
{
    public class Employee: User
    {
        [Required, MaxLength(100)]
        public string JobTitle { get; set; } = null!;

        [Required]
        public DateTime HireDate { get; set; }
    }
}
