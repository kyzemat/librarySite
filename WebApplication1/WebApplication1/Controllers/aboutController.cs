using Microsoft.AspNetCore.Mvc;

namespace WebApplication1.Controllers
{
    public class aboutController : Controller
    {
        public IActionResult Index()
        {
            return View();
        }
    }
}
