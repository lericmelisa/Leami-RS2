using Leami.Model.Responses;
using Leami.Model.SearchObjects;
using Leami.Services.IServices;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;

namespace LeamiWebAPI.Controllers
{
    [ApiController]
    [Route("[controller]")] 
    public class BaseController<T,TSearch> : ControllerBase
                where T : class
                where TSearch : BaseSearchObject,new()
    {
        protected readonly IService<T, TSearch> _service;
        public BaseController(IService<T,TSearch> service)
        {
            _service = service;
        }
        [HttpGet("")]
        public async Task<List<T>> GetAsync([FromQuery] TSearch? searchTerm=null)
        {
            return await _service.GetAsync(searchTerm?? new TSearch());
        }
        [HttpGet("{id}")]
        public async Task<T?> GetByIdAsync(int id)
        {
            return await _service.GetByIdAsync(id);
        }


    }
   
}
