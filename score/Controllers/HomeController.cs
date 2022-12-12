using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;

namespace score.Controllers
{
    public class HomeController : Controller
    {
        public ActionResult Index()
        {

            return RedirectToAction("InventoryNotOnFitzMallReport", "InventoryNotOnFitzMall_Report");
        }
        public ActionResult JJFServer()
        {

            return Redirect("http://jjfserver/default.asp");
        }

        public ActionResult About()
        {
            ViewBag.Message = "Your application description page.";

            return View();
        }

        public ActionResult Contact()
        {
            ViewBag.Message = "Your contact page.";

            return View();
        }

        public ActionResult Inventory_Report()
        {
            ViewBag.Message = "Your contact page.";

            return View();
        }
    }
}