using Leami.Model.SearchObjects;
using Leami.Services;
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
   
        [HttpPost] 
        public async Task<T> Create([FromBody] TInsert request)
        {
            return await _crudService.CreateAsync(request);
        }

        [HttpPut("{id}")]
        public async Task<T> Update(int id, [FromBody] TUpdate request)
        {
            return await _crudService.UpdateAsync(id, request);
        }
        [HttpDelete]
        public async Task<bool> Delete(int id)
        {
            return await _crudService.DeleteAsync(id);
        }
    }
   
}
