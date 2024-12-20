using Microsoft.AspNetCore.Mvc;

namespace WebApplication1.Controllers
{
    public class BookController : Controller
    {
        public IActionResult Index()
        {
            return View();
        }
    }
}
