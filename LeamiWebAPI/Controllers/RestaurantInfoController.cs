using Leami.Model.Requests;
using Leami.Model.Responses;
using Leami.Model.SearchObjects;
using Leami.Services.IServices;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Leami.Services.Services;


namespace LeamiWebAPI.Controllers
{
    public class RestaurantInfoController : BaseCRUDController<RestaurantInfoResponse,BaseSearchObject,RestaurantInfoInsertRequest,RestaurantInfoUpdateRequest>
    {
        public readonly IRestaurantInfo restaurantInfoService;
        public RestaurantInfoController(IRestaurantInfo iservice) : base(iservice)
        {
            restaurantInfoService = iservice;
        }



    }
}
