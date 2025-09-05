using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Leami.Model.Responses
{
    public class OrderItemResponse
    {
        public int OrderItemId { get; set; }
        public int ArticleId { get; set; }
        public int Quantity { get; set; }
        public decimal UnitPrice { get; set; }
        public decimal Total { get; set; }
        public ArticleResponse? Article {get;set;}
        public ArticleResponse? ArticleName { get; set; }

    }
}
