using Leami.Model.Entities;
using Stripe.Climate;
using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Leami.Services.Database.Entities
{
  
        public class OrderItem
        {
            [Key]
            public int OrderItemId { get; set; }
            public int OrderId { get; set; }          
            public int ArticleId { get; set; }
            public int Quantity { get; set; }
            public decimal UnitPrice { get; set; }
            public decimal Total => Quantity * UnitPrice;
             public virtual Order Order { get; set; } = null!;
            public virtual Article Article { get; set; } = null!;
        }
    
}
