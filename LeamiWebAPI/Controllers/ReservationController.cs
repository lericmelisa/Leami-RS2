using Leami.Model.Entities;
using Leami.Model.Requests;
using Leami.Model.Responses;
using Leami.Model.SearchObjects;
using Leami.Services.Database.Entities;
using Leami.Services.IServices;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace LeamiWebAPI.Controllers
{
     public class ReservationController:BaseCRUDController<ReservationResponse, ReservationSearchObject, ReservationInsertRequest, ReservationUpdateRequest>
    {
       public readonly IReservationService _reservationService;

        public ReservationController(IReservationService service) : base(service)
        {
            _reservationService = service;  
        }
     
    }   
 
}
