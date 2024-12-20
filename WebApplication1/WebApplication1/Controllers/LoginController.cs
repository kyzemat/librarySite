using BCrypt.Net;
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;
using WebApplication1.DB;

namespace WebApplication1.Controllers
{
    public class LoginController : Controller
    {
        private readonly ApplicationDbContext _context;
        public IActionResult Index()
        {
            return View();
        }
        public LoginController(ApplicationDbContext context)
        {
            _context = context;
        }

        [HttpPost]
        public async Task<IActionResult> Index(string username, string password)
        {
            // Найдите пользователя в базе данных
            var user = _context.Users.FirstOrDefault(u => u.username == username);

            if (user == null)
            {
                ModelState.AddModelError("", "Неверный логин или пароль.");
                return View();
            }

            // Сравните пароль с хэшированным паролем
            if (BCrypt.Net.BCrypt.Verify(password, user.password))
            {
                // Создаем ClaimsIdentity
                var claims = new List<Claim>
            {
                new Claim(ClaimTypes.Name, user.username),
                new Claim(ClaimTypes.Role, user.role)
            };

                var identity = new ClaimsIdentity(claims, "CookieAuth");
                var principal = new ClaimsPrincipal(identity);

                // Выполняем вход
                await HttpContext.SignInAsync("CookieAuth", principal);

                return RedirectToRoute("default", new { controller = "Home" });
            }

            ModelState.AddModelError("", "Неверный логин или пароль.");
            return View();
        }

        

    }
}
