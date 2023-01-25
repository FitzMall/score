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


            public ActionResult BarGraph(string location = "")
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
                return View(db.EmployeePerformanceMTDs.Where(a => a.LOCATION == location).OrderBy(a => a.sl_SalesAssociate1 + a.VehicleMake).ToList());
            }
            else
            {
                ViewBag.Location = " ALL Fitzgerald";
                return View(db.EmployeePerformanceMTDs.OrderBy(a => a.sl_SalesAssociate1 + a.VehicleMake).ToList());
            }
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
                return View(db.EmployeePerformanceMTDs.Where(a => a.LOCATION == location).OrderBy(a => a.SalesRank).ToList());
            }
            else
            {
                ViewBag.Location = " ALL Fitzgerald";
                return View(db.EmployeePerformanceMTDs.OrderByDescending(a => a.sl_SalesAssociate1).ToList());
            }
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
