using Leami.Model.Requests;
using Leami.Model.Responses;
using Leami.Model.SearchObjects;
using Leami.Services.IServices;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;

namespace LeamiWebAPI.Controllers
{
    public class CategoryController : BaseCRUDController<CategoryResponse,CategorySearchObject,CategoryInsertRequest,CategoryInsertRequest>
    {
        public readonly ICategoryService categoryService;
        public CategoryController(ICategoryService _service): base(_service)
        {
                
        }

    }
}
