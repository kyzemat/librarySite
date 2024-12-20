using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using WebApplication1.DB;

namespace WebApplication1.Controllers
{
    public class ReaderAcountController : Controller
    {
        private readonly ApplicationDbContext _context;

        public ReaderAcountController(ApplicationDbContext context)
        {
            _context = context;
        }

        [Authorize] // Доступ только для аутентифицированных пользователей
        public IActionResult Index()
        {
            // Получаем имя пользователя из куки
            var username = User.Identity.Name;

            // Получаем информацию о пользователе из базы данных
            var user = _context.Users.FirstOrDefault(u => u.username == username);

            if (user == null)
            {
                return NotFound("Пользователь не найден.");
            }

            // Передаем данные пользователя в представление
            return View(user);
        }
        [HttpPost]
        public async Task<IActionResult> Logout()
        {
            // Удаляем куки авторизации
            await HttpContext.SignOutAsync("CookieAuth");

            // Перенаправляем на главную страницу
            return RedirectToAction("Index", "Home");
        }
    }
}
