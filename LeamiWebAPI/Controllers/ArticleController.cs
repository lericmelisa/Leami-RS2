using Leami.Model.Entities;
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
    [ApiController]
    [Route("[controller]")]
    public class ArticleController : BaseCRUDController<ArticleResponse, ArticleSearchObject,ArticleInsertRequest,ArticleInsertRequest>
    {
        public readonly IArticleService articleService;
        public ArticleController(IArticleService _service):base(_service)
        {  
            articleService = _service;  
        }


        [Authorize(Roles = "Administrator")]
        public override async Task<ArticleResponse> Create([FromBody] ArticleInsertRequest request)
        {
            return await articleService.CreateAsync(request);
        }

        [Authorize(Roles = "Administrator")]
        public override async Task<ArticleResponse> Update(int id, [FromBody] ArticleInsertRequest request)
        {
            return await articleService.UpdateAsync(id, request);
        }

        [Authorize(Roles = "Administrator")]
        public override async Task<bool> Delete(int id)
        {
            return await articleService.DeleteAsync(id);
        }

        [HttpGet("{id}/recommend")]
        public async Task<List<ArticleResponse>> Recommend(int id, [FromQuery] int take = 3)
               => await articleService.RecommendAsync(id, take);
    }





}
