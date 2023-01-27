using System;
using System.Collections.Generic;
using System.Data;
using System.Data.Entity;
using System.Linq;
using System.Net;
using System.Web;
using System.Web.Mvc;
using score.Models;
using System.Globalization;

namespace score.Views
{
    public class SalesBoardAllMTDsController : Controller
    {
        private SalesCommissionEntities db = new SalesCommissionEntities();

        // GET: SalesBoardAllMTDs
        public ActionResult Index(string location = "")
        {
            DateTimeFormatInfo dtfi = CultureInfo.GetCultureInfo("en-US").DateTimeFormat;
            int days = DateTime.DaysInMonth(DateTime.Now.Year, DateTime.Now.Month);


            ViewBag.ReportDate = dtfi.GetMonthName(DateTime.Now.Month) + " " + (DateTime.Now.Year.ToString());
            ViewBag.DIM = days;
            location = location.ToUpper();

            if (location != "")
            {
                ViewBag.Location = location;
                return View(db.SalesBoardAllMTDs.Where(a => a.LOCATION == location).OrderByDescending(a => a.MTD).ToList());
            }
            else
            {
                ViewBag.Location = " ALL Fitzgerald";
                return View(db.SalesBoardAllMTDs.OrderByDescending(a => a.MTD).ToList());
            }
        }


        public ActionResult MultiBar(string location = "")
        {
            return View();
        }


        public ActionResult ScoreBoard(string location = "")
        {
            DateTimeFormatInfo dtfi = CultureInfo.GetCultureInfo("en-US").DateTimeFormat;
            int days = DateTime.DaysInMonth(DateTime.Now.Year, DateTime.Now.Month);


            ViewBag.ReportDate = dtfi.GetMonthName(DateTime.Now.Month) + " " + (DateTime.Now.Year.ToString());
            ViewBag.DIM = days;
            location = location.ToUpper();

            if (location == "")
            {
                location = "FTN";
            }

            if (location != "")
            {
                ViewBag.Location = location;
                return View(db.EmployeePerformanceMTDs.OrderByDescending(a => a.sl_SalesAssociate1).ToList());
            }
            else
            {
                ViewBag.Location = " ALL Fitzgerald";
                return View(db.EmployeePerformanceMTDs.OrderByDescending(a => a.sl_SalesAssociate1).ToList());
            }
        }
        public ActionResult TeamScoreBoard(DateTime? dt = null, string Team = "")
        {
            DateTimeFormatInfo dtfi = CultureInfo.GetCultureInfo("en-US").DateTimeFormat;
            int days = DateTime.DaysInMonth(DateTime.Now.Year, DateTime.Now.Month);

            ViewBag.ReportDate = dtfi.GetMonthName(DateTime.Now.Month) + " " + (DateTime.Now.Year.ToString());
            ViewBag.DIM = days;
            Team = Team.Trim().ToUpper();
            if (dt == null)
            {
                dt = DateTime.Today;
            }
            //sp_EmployeePerformanceMTD_ByDate
            var context = new SalesCommissionEntities();
            var MTD = context.sp_EmployeePerformanceMTD_ByDate(dt);

            if (Team == "")
            {
                Team = "GASL03";
            }

            DateTime ReportDate = (DateTime)dt;
            ViewBag.MonthDisplay =  ReportDate.ToString("MMMM");
            ViewBag.YrShow = ReportDate.ToString("yyyy");
            return View(MTD.Where(a => a.dept_code == Team).OrderBy(a => a.SalesID).ToList());

        }

        protected override void Dispose(bool disposing)
        {
            if (disposing)
            {
                db.Dispose();
            }
            base.Dispose(disposing);
        }
    }
}
