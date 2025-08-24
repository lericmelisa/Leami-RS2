using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Leami.Model.Requests
{
    public class ReservationUpdateRequest
    {
      
        public DateOnly? ReservationDate { get; set; }

     
        public TimeOnly? ReservationTime { get; set; }

        [Range(1, 100, ErrorMessage = "The number of guests can be in a range from 1 to 100")]
        public int? NumberOfGuests { get; set; }


        public int? ReservationStatus { get; set; }

        public int? UserId { get; set; }

        [MaxLength(1000, ErrorMessage = "The reservation reason can't have more than 1000 characters.")]
        public string? ReservationReason { get; set; }

        [Range(0, 100, ErrorMessage = "The number of minors can be in a range from 0 to 100")]
        public int? NumberOfMinors { get; set; }

        [Phone(ErrorMessage = "The phone needs to be in a valid format")]
        public string? ContactPhone { get; set; } = null!;

        [MaxLength(1000, ErrorMessage = "Thereservation notes can't have more than 1000 characters.")]
        public string? SpeciaLRequests { get; set; } = null!;

    }
}
