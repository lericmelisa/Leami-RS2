using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Leami.Model.SearchObjects
{
    public class ArticleSearchObject:BaseSearchObject
    {
    public string? ArticleName { get; set; }
        public string? ArticleNameGTE { get; set; }
        public string? FTSA { get; set; }


    }
}
