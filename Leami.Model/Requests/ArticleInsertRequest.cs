
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
       
        public string ArticleName { get; set; } = string.Empty;   
        public float ArticlePrice { get; set; }
        public string? ArticleDescription { get; set; }
        public int CategoryId { get; set; }
        public byte[] ArticleImage { get; set; }


    }
}
