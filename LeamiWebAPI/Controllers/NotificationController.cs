using Leami.Model.Requests;
using Leami.Model.Responses;
using Leami.Model.SearchObjects;
using Leami.Services.IServices;
using Microsoft.AspNetCore.Mvc;

namespace LeamiWebAPI.Controllers
{
    [ApiController]
    [Route("[controller]")]
    public class NotificationController:BaseCRUDController<NotificationResponse,BaseSearchObject,NotificationInsertRequest,NotificationUpdateRequest>
     {

        public readonly INotificationService notificationService;
        public NotificationController(INotificationService _service) : base(_service)
        {
            notificationService = _service;
        }   

    }
}
