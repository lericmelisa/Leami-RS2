
using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Leami.Model.Requests
{
    public class ArticleInsertRequest
    {
        [Required]
        [MaxLength(100)]
        public string ArticleName { get; set; } = string.Empty;

        [MaxLength(500)]
        public string ArticleCode { get; set; } = string.Empty;
    }
}
