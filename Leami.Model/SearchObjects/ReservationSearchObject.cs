using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Leami.Model.SearchObjects
{
    public class ReservationSearchObject : BaseSearchObject
    {
        public DateOnly? ReservationDate { get; set; }
        public int? UserId { get; set;}
        public bool? IsExpired { get; set; }
    }
}
