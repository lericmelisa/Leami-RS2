using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Leami.Model.Responses
{
    public class RestaurantInfoResponse
    {
        public int RestaurantId { get; set; } = 1;
        public string Name { get; set; } = string.Empty;
        public string? Description { get; set; }
        public string? Address { get; set; }
        public string? Phone { get; set; }
        public byte[]? RestaurantImage { get; set; }
        public TimeSpan OpeningTime { get; set; }
        public TimeSpan ClosingTime { get; set; }
    }
}
