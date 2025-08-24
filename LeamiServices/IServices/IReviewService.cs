using Leami.Model.Responses;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Leami.Model.Requests;
using Leami.Model.SearchObjects;
using Leami.Services.Database.Entities;

namespace Leami.Services.IServices
{
    public interface IReviewService : ICRUDService<ReviewResponse, ReviewSearchObject, ReviewInsertRequest, ReviewUpdateRequest>
    {
    }
}
