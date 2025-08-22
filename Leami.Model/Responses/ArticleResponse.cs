using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Leami.Model.Responses
{
    public class ArticleResponse
    {
        public int ArticleId { get; set; }
        public string ArticleName { get; set; } = string.Empty;
        public string ArticleDescription { get; set; } = string.Empty;
        public float ArticlePrice { get; set; }
        public byte[]? ArticleImage { get; set; }
        public int? CategoryId { get; set; }
    

    }
}
