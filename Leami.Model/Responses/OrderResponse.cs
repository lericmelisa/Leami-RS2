using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Leami.Model.Responses
{
    public class OrderResponse
    {
        public int OrderId { get; set; }
        public int UserId { get; set; }
        public DateTime OrderDate { get; set; }
        public string Status { get; set; } = string.Empty; // Pending, Completed, Cancelled, etc.
        public decimal TotalAmount { get; set; }
        public string? PaymentMethod { get; set; }
        public string? Notes { get; set; }
        public List<OrderItemResponse> OrderItems { get; set; } = new();
    }
}
