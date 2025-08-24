using Leami.Model.Entities;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Leami.Services.Database.Entities
{
    public class Reservation
    {
        public int ReservationId { get; set; }
        public int UserId { get; set; }    
        public User? User { get; set; }  


        public DateOnly ReservationDate { get; set; }

        public TimeOnly ReservationTime { get; set; }

        public int NumberOfGuests { get; set; }

        public int ReservationStatus { get; set; }

        public string? ReservationReason { get; set; }

        public int? NumberOfMinors { get; set; } 

        public string ContactPhone { get; set; } = null!;

        public string? SpeciaLRequests { get; set; } 

    }
}
