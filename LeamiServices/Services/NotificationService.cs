using Leami.Model.Requests;
using Leami.Model.Responses;
using Leami.Model.SearchObjects;
using Leami.Services.Database;
using Leami.Services.Database.Entities;
using Leami.Services.IServices;
using MapsterMapper;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Leami.Services.Services
{
    public class NotificationService:BaseCRUDService<NotificationResponse,BaseSearchObject,Notification, NotificationInsertRequest,NotificationUpdateRequest>,INotificationService
    {
        LeamiDbContext context;
        IMapper mapper;
        public NotificationService(LeamiDbContext leami,IMapper _mapper):base(leami,_mapper)
        {
            context = leami;
        }
     
    }
}
