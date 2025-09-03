using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Leami.Model.Responses
{
    public class NotificationResponse
    {
        public int? UserId { get; set; }
        public virtual UserResponse? User { get; set; }
        public int? ReservationId { get; set; }
        public virtual ReservationResponse? Reservation { get; set; }
        public string Message { get; set; } = string.Empty;
    }
}
