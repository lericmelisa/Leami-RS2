using Leami.Model.Entities;
using Newtonsoft.Json;
using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations.Schema;
using System.ComponentModel.DataAnnotations;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Leami.Services.Database.Entities
{
    public class Notification
    {
        [Key]
        public int NotificationId { get; set; }
        public int? UserId { get; set; }
        public virtual User? User { get; set; }
        public int? ReservationId { get; set; }
        public virtual Reservation? Reservation { get; set; }
        public string Message { get; set; } =string.Empty;


    }
}
