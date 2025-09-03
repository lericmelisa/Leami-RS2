using Leami.Model.SearchObjects;
using Leami.Services.IServices;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using System.Reflection;

namespace LeamiWebAPI.Controllers
{
    public class BaseCRUDController<T, TSeacrh, TInsert, TUpdate> : BaseController<T, TSeacrh>
        where T : class
        where TSeacrh : BaseSearchObject, new()       
        where TInsert : class
        where TUpdate : class

    {
        private readonly ICRUDService<T, TSeacrh, TInsert, TUpdate> _crudService;
        public BaseCRUDController(ICRUDService<T,TSeacrh,TInsert,TUpdate> service):base(service)
        {
            _crudService = service;
        }

        [Authorize]
        [HttpPost] 
        public virtual async Task<T> Create([FromBody] TInsert request)
        {
            return await _crudService.CreateAsync(request);
        }

        [Authorize]
        [HttpPut("{id}")]
        public virtual async Task<T> Update(int id, [FromBody] TUpdate request)
        {
            return await _crudService.UpdateAsync(id, request);
        }
        [Authorize]
        [HttpDelete]
        public virtual async Task<bool> Delete(int id)
        {
            return await _crudService.DeleteAsync(id);
        }
    }
   
}
