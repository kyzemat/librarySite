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

            if (User.IsInRole("��������"))
            {
                return View("ReaderPage"); // �������� ��� ��������������
            }
            else if (User.IsInRole("��������"))
            {
                return View("DirectorPage"); // �������� ��� ������������
            }
            else if (User.IsInRole("������������"))
            {
                return View("LibrarianPage"); // �������� ��� ������������
            }
            else
            {
                return View(); // �������� ��� ���������������� �������������
            }
        }


    }
}
