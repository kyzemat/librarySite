using Microsoft.AspNetCore.Connections;
using Microsoft.AspNetCore.Mvc;
using Npgsql;


namespace WebApplication1.Controllers
{
    public class RegistrationController : Controller
    {
        public IActionResult Index()
        {
            return View();
        }

        [HttpPost]
        public IActionResult InsertData(string username, string password, string email)
        {
            try
            {
                // Проверка на SQL-инъекцию (простая защита)
                if (IsSqlInjection(username) || IsSqlInjection(password) || IsSqlInjection(email))
                {
                    return BadRequest("Попытка SQL-инъекции обнаружена.");
                }

                // Подключение к базе данных
                using (var connection = new NpgsqlConnection("Host=localhost;Port=5432;Database=LibraryDataBase;Username=postgres;Password=a17122005"))
                {
                    connection.Open();

                    // SQL-запрос для вставки данных
                    string query = "INSERT INTO users (username, email, password, role) VALUES (@username, @email, crypt(@password, gen_salt('bf')), 'читатель')";
                    using (var command = new NpgsqlCommand(query, connection))
                    {
                        command.Parameters.AddWithValue("username", username);
                        command.Parameters.AddWithValue("email", email);
                        command.Parameters.AddWithValue("password", password);
                        command.ExecuteNonQuery();
                    }
                }

                return Ok("Данные успешно добавлены.");
            }
            catch (Exception ex)
            {
                return BadRequest($"Ошибка при вставке данных: {ex.Message}");
            }
        }


        private bool IsSqlInjection(string input)
        {
            string[] dangerousKeywords = { "DROP", "DELETE", "UPDATE", "INSERT", "SELECT", "--" };
            foreach (var keyword in dangerousKeywords)
            {
                if (input.IndexOf(keyword, StringComparison.OrdinalIgnoreCase) >= 0)
                {
                    return true;
                }
            }
            return false;
        }
    }
}
