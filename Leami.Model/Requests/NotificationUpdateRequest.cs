using Leami.Model.Responses;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Leami.Model.Requests
{
    public class NotificationUpdateRequest
    {
        public int NotificationId { get; set; }
        public int? UserId { get; set; }
        public int? ReservationId { get; set; }
        public string Message { get; set; } = string.Empty;
    }
}
