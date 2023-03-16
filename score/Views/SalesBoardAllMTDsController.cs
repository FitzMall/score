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
        public ActionResult TeamScoreBoard(DateTime? dt = null, string Team = "", string st = "")
        {
            DateTimeFormatInfo dtfi = CultureInfo.GetCultureInfo("en-US").DateTimeFormat;
            int days = DateTime.DaysInMonth(DateTime.Now.Year, DateTime.Now.Month);
            DateTime dReportDate;
            DateTime? LastMonthdt = DateTime.Today.AddDays(-20);

            string sReportDate = dtfi.GetMonthName(DateTime.Now.Month) + " " + (DateTime.Now.Year.ToString());
            ViewBag.ReportDate = DateTime.Parse(sReportDate);
            if (dt == null)
            {
                dt = DateTime.Today;
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


            System.Collections.Generic.List<score.Models.EmployeePerformanceMTD> SBoard;
             switch (st)
            {
                case "n":
                    SBoard = MTD.Where(a => a.dept_code == Team && a.VehicleMake != "USED" && a.SalesRank_New > 0).OrderBy(a => a.SalesRank_New).ThenBy(a => a.sl_SalesAssociate1).ToList();
                    if (SBoard.Count() == 0) { 
                        MTD = context.sp_EmployeePerformanceMTD_ByDate(LastMonthdt);
                        dReportDate = (DateTime)LastMonthdt;
                        SBoard = MTD.Where(a => a.dept_code == Team && a.VehicleMake != "USED" && a.SalesRank_New > 0).OrderBy(a => a.SalesRank_New).ThenBy(a => a.sl_SalesAssociate1).ToList();
                    }
                    break;
                case "u":
                    SBoard = MTD.Where(a => a.dept_code == Team && a.VehicleMake == "USED" && a.SalesRank_Used > 0).OrderBy(a => a.SalesRank_Used).ThenBy(a => a.sl_SalesAssociate1).ToList();
                    if (SBoard.Count() == 0)
                    {
                        MTD = context.sp_EmployeePerformanceMTD_ByDate(LastMonthdt);
                        dReportDate = (DateTime)LastMonthdt;
                        SBoard = MTD.Where(a => a.dept_code == Team && a.VehicleMake == "USED" && a.SalesRank_Used > 0).OrderBy(a => a.SalesRank_Used).ThenBy(a => a.sl_SalesAssociate1).ToList();
                    }
                    break;
                default:
                    SBoard = MTD.Where(a => a.dept_code == Team).OrderBy(a => a.SalesRank).ThenBy(a => a.sl_SalesAssociate1).ToList();
                    if (SBoard.Count() == 0)
                    {
                        MTD = context.sp_EmployeePerformanceMTD_ByDate(LastMonthdt);
                        dReportDate = (DateTime)LastMonthdt;
                        SBoard = MTD.Where(a => a.dept_code == Team).OrderBy(a => a.SalesRank).ThenBy(a => a.sl_SalesAssociate1).ToList();
                    }
                    break;
            }

            DateTime ReportDate = dReportDate;
            ViewBag.MonthDisplay = ReportDate.ToString("MMMM");
            ViewBag.YrShow = ReportDate.ToString("yyyy");
            ViewBag.st = st;

            return View(SBoard);
        }

        public ActionResult BPPScoreBoard(DateTime? dt = null, string Team = "", string st = "")
        {
            DateTimeFormatInfo dtfi = CultureInfo.GetCultureInfo("en-US").DateTimeFormat;
            int days = DateTime.DaysInMonth(DateTime.Now.Year, DateTime.Now.Month);
            DateTime dReportDate;
            DateTime? LastMonthdt = DateTime.Today.AddDays(-20);

            string sReportDate = dtfi.GetMonthName(DateTime.Now.Month) + " " + (DateTime.Now.Year.ToString());
            ViewBag.ReportDate = DateTime.Parse(sReportDate);
            if (dt == null)
            {
                dt = DateTime.Today;
            }

            dReportDate = (DateTime)dt;

            sReportDate = dtfi.GetMonthName(dReportDate.Month) + " " + (dReportDate.Year.ToString());
            ViewBag.ReportDate = (dReportDate);

            //uses Stored Procedure sp_EmployeePerformanceMTD_ByDate 
            var context = new SalesCommissionEntities();
            var MTD = context.sp_EmployeePerformanceALL_ByDate(dt);

            var teamslist = context.sp_ListOfSalesTeams();
            ViewBag.TeamsList = teamslist;

            if (Team == "")
            {
                Team = "GASL03";
            }
            ViewBag.DeptCode = Team;
            Team = Team.Trim().ToUpper();

            //sp_ListOfSalesTeams_Result


            System.Collections.Generic.List<score.Models.EmployeePerformanceMTD> SBoard;
            switch (st)
            {
                case "n":
                    SBoard = MTD.Where(a => a.dept_code == Team && a.VehicleMake != "USED" && a.SalesRank_New > 0).OrderBy(a => a.SalesRank_New).ThenBy(a => a.sl_SalesAssociate1).ToList();
                    if (SBoard.Count() == 0)
                    {
                        MTD = context.sp_EmployeePerformanceMTD_ByDate(LastMonthdt);
                        dReportDate = (DateTime)LastMonthdt;
                        SBoard = MTD.Where(a => a.dept_code == Team && a.VehicleMake != "USED" && a.SalesRank_New > 0).OrderBy(a => a.SalesRank_New).ThenBy(a => a.sl_SalesAssociate1).ToList();
                    }
                    break;
                case "u":
                    SBoard = MTD.Where(a => a.dept_code == Team && a.VehicleMake == "USED" && a.SalesRank_Used > 0).OrderBy(a => a.SalesRank_Used).ThenBy(a => a.sl_SalesAssociate1).ToList();
                    if (SBoard.Count() == 0)
                    {
                        MTD = context.sp_EmployeePerformanceMTD_ByDate(LastMonthdt);
                        dReportDate = (DateTime)LastMonthdt;
                        SBoard = MTD.Where(a => a.dept_code == Team && a.VehicleMake == "USED" && a.SalesRank_Used > 0).OrderBy(a => a.SalesRank_Used).ThenBy(a => a.sl_SalesAssociate1).ToList();
                    }
                    break;
                default:
                    SBoard = MTD.Where(a => a.dept_code == Team).OrderBy(a => a.SalesRank).ThenBy(a => a.sl_SalesAssociate1).ToList();
                    if (SBoard.Count() == 0)
                    {
                        MTD = context.sp_EmployeePerformanceMTD_ByDate(LastMonthdt);
                        dReportDate = (DateTime)LastMonthdt;
                        SBoard = MTD.Where(a => a.dept_code == Team).OrderBy(a => a.SalesRank).ThenBy(a => a.sl_SalesAssociate1).ToList();
                    }
                    break;
            }

            DateTime ReportDate = dReportDate;
            ViewBag.MonthDisplay = ReportDate.ToString("MMMM");
            ViewBag.YrShow = ReportDate.ToString("yyyy");
            ViewBag.st = st;

            return View(SBoard);
        }

        public ActionResult ZurichScoreBoard(DateTime? dt = null, string Team = "", string st = "")
        {
            DateTimeFormatInfo dtfi = CultureInfo.GetCultureInfo("en-US").DateTimeFormat;
            int days = DateTime.DaysInMonth(DateTime.Now.Year, DateTime.Now.Month);
            DateTime dReportDate;
            DateTime? LastMonthdt = DateTime.Today.AddDays(-20);

            string sReportDate = dtfi.GetMonthName(DateTime.Now.Month) + " " + (DateTime.Now.Year.ToString());
            ViewBag.ReportDate = DateTime.Parse(sReportDate);
            if (dt == null)
            {
                dt = DateTime.Today;
            }

            dReportDate = (DateTime)dt;

            sReportDate = dtfi.GetMonthName(dReportDate.Month) + " " + (dReportDate.Year.ToString());
            ViewBag.ReportDate = (dReportDate);

            //uses Stored Procedure sp_EmployeePerformanceMTD_ByDate 
            var context = new SalesCommissionEntities();
            var MTD = context.sp_EmployeePerformanceALL_ByDate(dt);

            var teamslist = context.sp_ListOfSalesTeams();
            ViewBag.TeamsList = teamslist;

            if (Team == "")
            {
                Team = "GASL03";
            }
            ViewBag.DeptCode = Team;
            Team = Team.Trim().ToUpper();

            //sp_ListOfSalesTeams_Result


            System.Collections.Generic.List<score.Models.EmployeePerformanceMTD> SBoard;
            switch (st)
            {
                case "n":
                    SBoard = MTD.Where(a => a.dept_code == Team && a.VehicleMake != "USED" && a.SalesRank_New > 0).OrderBy(a => a.SalesRank_New).ThenBy(a => a.sl_SalesAssociate1).ToList();
                    if (SBoard.Count() == 0)
                    {
                        MTD = context.sp_EmployeePerformanceMTD_ByDate(LastMonthdt);
                        dReportDate = (DateTime)LastMonthdt;
                        SBoard = MTD.Where(a => a.dept_code == Team && a.VehicleMake != "USED" && a.SalesRank_New > 0).OrderBy(a => a.SalesRank_New).ThenBy(a => a.sl_SalesAssociate1).ToList();
                    }
                    break;
                case "u":
                    SBoard = MTD.Where(a => a.dept_code == Team && a.VehicleMake == "USED" && a.SalesRank_Used > 0).OrderBy(a => a.SalesRank_Used).ThenBy(a => a.sl_SalesAssociate1).ToList();
                    if (SBoard.Count() == 0)
                    {
                        MTD = context.sp_EmployeePerformanceMTD_ByDate(LastMonthdt);
                        dReportDate = (DateTime)LastMonthdt;
                        SBoard = MTD.Where(a => a.dept_code == Team && a.VehicleMake == "USED" && a.SalesRank_Used > 0).OrderBy(a => a.SalesRank_Used).ThenBy(a => a.sl_SalesAssociate1).ToList();
                    }
                    break;
                default:
                    SBoard = MTD.Where(a => a.dept_code == Team).OrderBy(a => a.SalesRank).ThenBy(a => a.sl_SalesAssociate1).ToList();
                    if (SBoard.Count() == 0)
                    {
                        MTD = context.sp_EmployeePerformanceMTD_ByDate(LastMonthdt);
                        dReportDate = (DateTime)LastMonthdt;
                        SBoard = MTD.Where(a => a.dept_code == Team).OrderBy(a => a.SalesRank).ThenBy(a => a.sl_SalesAssociate1).ToList();
                    }
                    break;
            }

            DateTime ReportDate = dReportDate;
            ViewBag.MonthDisplay = ReportDate.ToString("MMMM");
            ViewBag.YrShow = ReportDate.ToString("yyyy");
            ViewBag.st = st;

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
