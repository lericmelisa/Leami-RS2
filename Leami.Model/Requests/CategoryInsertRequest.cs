using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Leami.Model.Requests
{
    public class CategoryInsertRequest
    {
        [Required(AllowEmptyStrings = false, ErrorMessage = "Category name ne moze biti prazan.")]
        [MinLength(2, ErrorMessage = "Category name can't ne moze biti manje od dva karaktera.")]
        [MaxLength(50, ErrorMessage = "ne moze biti vise od 50 karaktera.")]
        public string CategoryName { get; set; }
    }
}
