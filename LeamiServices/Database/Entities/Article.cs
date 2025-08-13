using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Leami.Model.Entities
{
    public class Article
    {
        public int ArticleId { get; set; }
        public string ArticleName { get; set; } = string.Empty;
        public string ArticleCode { get; set; } = string.Empty;
    }
}
