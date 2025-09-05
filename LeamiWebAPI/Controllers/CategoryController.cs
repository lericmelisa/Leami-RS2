using Leami.Model.Requests;
using Leami.Model.Responses;
using Leami.Model.SearchObjects;
using Leami.Services.IServices;
using Leami.Services.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;

namespace LeamiWebAPI.Controllers
{
    public class CategoryController : BaseCRUDController<CategoryResponse,CategorySearchObject,CategoryInsertRequest,CategoryInsertRequest>
    {
        public readonly ICategoryService categoryService;
        public CategoryController(ICategoryService _service): base(_service)
        {
            categoryService = _service;
        }
        [Authorize(Roles = "Administrator")]
        public override async Task<CategoryResponse> Create([FromBody] CategoryInsertRequest request)
        {
            return await categoryService.CreateAsync(request);
        }

        [Authorize(Roles = "Administrator")]
        public override async Task<CategoryResponse> Update(int id, [FromBody] CategoryInsertRequest request)
        {
            return await categoryService.UpdateAsync(id, request);
        }

        [Authorize(Roles = "Administrator")]
        public override async Task<bool> Delete(int id)
        {
            return await categoryService.DeleteAsync(id);
        }
    }
}
