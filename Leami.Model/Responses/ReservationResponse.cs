using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Leami.Model.Responses
{
    public class ReservationResponse
    {
       
        public DateOnly ReservationDate { get; set; }

    
        public TimeOnly ReservationTime { get; set; }

        public int NumberOfGuests { get; set; }


        public int? ReservationStatus { get; set; }

        public int? UserId { get; set; }

        public string? ReservationReason { get; set; }

      
        public int? NumberOfMinors { get; set; }

      
        public string ContactPhone { get; set; } = null!;

        
        public string SpeciaLRequests { get; set; } = null!;

    }
}
