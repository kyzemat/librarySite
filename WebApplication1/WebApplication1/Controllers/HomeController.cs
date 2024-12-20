using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Diagnostics;
using WebApplication1.Models;

namespace WebApplication1.Controllers
{
    public class HomeController : Controller
    {

        [AllowAnonymous]
        public IActionResult Index()
        {

            if (User.IsInRole("читатель"))
            {
                return View("ReaderPage"); // Страница для администратора
            }
            else if (User.IsInRole("директор"))
            {
                return View("DirectorPage"); // Страница для пользователя
            }
            else if (User.IsInRole("библиотекарь"))
            {
                return View("LibrarianPage"); // Страница для пользователя
            }
            else
            {
                return View(); // Страница для неавторизованных пользователей
            }
        }


    }
}
