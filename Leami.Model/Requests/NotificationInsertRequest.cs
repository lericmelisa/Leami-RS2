using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Leami.Model.Requests
{
    public class NotificationInsertRequest
    {
        [Required(ErrorMessage = "UserId ne moze biti prazan.")]
        public int UserId { get; set; }
        [Required(ErrorMessage = "ReservationId ne moze biti prazan.")]
        public int ReservationId { get; set; }
        [Required(AllowEmptyStrings = false, ErrorMessage = "Message ne moze biti prazan.")]
        public string Message { get; set; } = string.Empty;
    }
}
