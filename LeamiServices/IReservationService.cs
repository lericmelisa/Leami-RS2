using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Leami.Services.Database.Entities;
using Leami.Model.Entities;
using Leami.Model.Requests;
using Leami.Model.Responses;
using Leami.Model.SearchObjects;
namespace Leami.Services
{
    public  interface IReservationService:ICRUDService<ReservationResponse, ReservationSearchObject,ReservationInsertRequest, ReservationInsertRequest>   
    {
    }
}
