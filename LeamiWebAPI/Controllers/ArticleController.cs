using Leami.Model.Entities;
using Leami.Model.Requests;
using Leami.Model.Responses;
using Leami.Model.SearchObjects;
using Leami.Services.IServices;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;

namespace LeamiWebAPI.Controllers
{
   
    public class ArticleController : BaseCRUDController<ArticleResponse, ArticleSearchObject,ArticleInsertRequest,ArticleInsertRequest>
    {
        public readonly IArticleService articleService;
        public ArticleController(IArticleService _service):base(_service)
        {  
            articleService = _service;  
        }
      
      
    }
}
