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
            DateTime dReportDate;

            string sReportDate = dtfi.GetMonthName(DateTime.Now.Month) + " " + (DateTime.Now.Year.ToString());
            ViewBag.ReportDate = DateTime.Parse(sReportDate);
            if (dt == null)
            {
                dt = DateTime.Today.AddDays(-1);
            }

            dReportDate = (DateTime)dt;
            
            sReportDate = dtfi.GetMonthName(dReportDate.Month) + " " + (dReportDate.Year.ToString());
            ViewBag.ReportDate = (dReportDate);

            //uses Stored Procedure sp_EmployeePerformanceMTD_ByDate 
            var context = new SalesCommissionEntities();
            var MTD = context.sp_EmployeePerformanceMTD_ByDate(dt);
            var teamslist = context.sp_ListOfSalesTeams();
            ViewBag.TeamsList = teamslist;

            if (Team == "")
            {
                Team = "GASL03";
            }
            ViewBag.DeptCode = Team;
            Team = Team.Trim().ToUpper();

            //sp_ListOfSalesTeams_Result

            DateTime ReportDate = dReportDate;
            ViewBag.MonthDisplay = ReportDate.ToString("MMMM");
            ViewBag.YrShow = ReportDate.ToString("yyyy");
            var SBoard = MTD.Where(a => a.dept_code == Team).OrderBy(a => a.SalesRank).ThenBy(a => a.sl_SalesAssociate1).ToList();

            //            return View(MTD.Where(a => a.dept_code == Team).OrderBy(a => a.SalesID).ToList());
            return View(SBoard);
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
