<cfparam name="isPcesRequest" type="boolean" default=false />
<cfparam name="pcesFormVal"   type="string"  default="0" />
<cfparam name="pcesText"      type="string"  default="" />
<cfparam name="pcesDbFlag"    type="string"  default="" />
<cfparam name="futurePrompt"  type="boolean" default="0">

<cfif isdefined("cftrk")><CF_Tracker PID=1></cfif>

<cfif (isDefined("form.isPces") && form.isPces eq 1) || (isDefined("url.isPces") && url.isPces eq 1)>
    <cfset isPcesRequest = true />
    <cfset pcesText      = "PCES " />
    <cfset pcesDbFlag    = "and b_pce_ind = 1" />
    <cfset pcesFormVal   = "1" />    
</cfif>

<cfscript>
    arrColor = arrayNew(1);
    strColor = structNew();
    strColor.color = 'FF6666';
    strColor.limit = .75;
    arrColor[1] = strColor;
    strColor = structNew();
    strColor.color = 'FFFF66';
    strColor.limit = .85;
    arrColor[2] = strColor;
    strColor = structNew();
    strColor.color = '66FF66';
    strColor.limit = .95;
    arrColor[3] = strColor;
    strColor = structNew();
    strColor.color = '6666FF';
    strColor.limit = 1;
    arrColor[4] = strColor;
    arrLen = arrayLen(arrColor);
    dailyOppColor = 'ccccff';
</cfscript>
<cfif isdefined("helpPrompt")><cfset client.pivotHelpPrompt=#helpPrompt#></cfif>

<cfif ListContains(CGI.HTTP_REFERER,"avar_pivot.cfm") NEQ 0>
    <cfif beg_period GT end_period OR end_period EQ 0>
        <cfquery name="bcalendar" datasource="#application.dsn#">
            SELECT CONVERT(char(12), cal_date_beg_wk, 110) bdate FROM master_calendar with (nolock) WHERE RIGHT(cal_fy_long,2)=LEFT('#beg_period#',2) AND RIGHT(cal_display_fywk,2)=RIGHT('#beg_period#',2) AND cal_del_days<>0
        </cfquery>
        <cfquery name="ecalendar" datasource="#application.dsn#">
            SELECT CONVERT(char(12), cal_date_end_wk, 110) edate FROM master_calendar with (nolock) WHERE RIGHT(cal_fy_long,2)=LEFT('#end_period#',2) AND RIGHT(cal_display_fywk,2)=RIGHT('#end_period#',2) AND cal_del_days<>0
        </cfquery>
        <cfoutput>
            <cfset ubdate="#bcalendar.bdate#">
            <cfset uedate="#ecalendar.edate#">
        </cfoutput>
        <cfoutput><cflocation url="avar_pivot.cfm?msg=INVALID DATE RANGE!! FROM: #ubdate# TO: #uedate#" addtoken="No"></cfoutput>
    </cfif>

        <cfquery name="getAdhocDate" datasource="#application.dsn#">
            SELECT DISTINCT cal_fy_long,cal_fy_wk
            FROM master_calendar  with (nolock)
            WHERE cal_date_beg_wk BETWEEN
                (SELECT TOP 1 cal_date_beg_wk cal_date_beg_wk FROM master_calendar with (nolock) WHERE RIGHT(cal_fy_long,2)=LEFT('#beg_period#',2) AND RIGHT(cal_display_fywk,2)=RIGHT('#beg_period#',2) AND cal_del_days<>0 ORDER BY cal_date_beg_wk ASC)
                AND
                (SELECT TOP 1 cal_date_end_wk cal_date_end_wk FROM master_calendar with (nolock) WHERE RIGHT(cal_fy_long,2)=LEFT('#end_period#',2) AND RIGHT(cal_display_fywk,2)=RIGHT('#end_period#',2) AND cal_del_days<>0 ORDER BY cal_date_end_wk DESC)
            AND cal_del_days<>0
            ORDER BY cal_fy_long,cal_fy_wk
        </cfquery>
        <cfquery name="getBegPeriod" datasource="#application.dsn#">
            SELECT TOP 1 cal_date_beg_wk wk_beg_dte FROM master_calendar WHERE RIGHT(cal_fy_long,2)=LEFT('#beg_period#',2) AND RIGHT(cal_display_fywk,2)=RIGHT('#beg_period#',2) AND cal_del_days<>0 ORDER BY cal_date_beg_wk ASC
        </cfquery>
        <cfquery name="getEndPeriod" datasource="#application.dsn#">
            SELECT TOP 1 cal_date_end_wk wk_end_dte FROM master_calendar WHERE RIGHT(cal_fy_long,2)=LEFT('#end_period#',2) AND RIGHT(cal_display_fywk,2)=RIGHT('#end_period#',2) AND cal_del_days<>0 ORDER BY cal_date_end_wk DESC
        </cfquery>
        <cfoutput>
            <cfset client.avar_wk_beg_dte="#getBegPeriod.wk_beg_dte#">
            <cfset client.avar_wk_end_dte="#getEndPeriod.wk_end_dte#">
        </cfoutput>
        <cfset client.avar_oppWeeks="">
        <cfset client.lstWeeks = ''>
        <cfoutput query="getAdhocDate">
            <!--- change fy logic --->
            <cfif cal_fy_wk GT curWeekAvailable>
                <cfset adhoc="#sply_cal_fy_long##cal_fy_wk#">
                <cfset adhoc1="#evaluate((sply_cal_fy_long*100)+cal_fy_wk)#">
            <cfelse>
                <cfset adhoc="#cal_fy_long##cal_fy_wk#">
                <cfset adhoc1="#evaluate((cal_fy_long*100)+cal_fy_wk)#">
            </cfif>
            <cfset client.avar_oppWeeks=#listappend(client.avar_oppWeeks,adhoc,",")#>
            <cfset client.lstWeeks=#listappend(client.lstWeeks,adhoc1,",")#>
        </cfoutput>

        <cfquery name="getAdhocDays" datasource="#application.dsn#">
            select sum(cal_del_days) AdHocdelDays
            from  master_calendar with (nolock)
            where CAST(cal_fy_long AS CHAR(4))+CAST(cal_fy_wk as VARCHAR(2)) in (#client.avar_oppWeeks#)
        </cfquery>
        <cfoutput><cfset client.avar_adHocDelDays=#getAdhocDays.AdHocdelDays#></cfoutput>
    </cfif>
    <cfoutput>
        <!--- count number of weeks in getdate.pic_wks string by counting commas and adding 1 --->
        <cfparam name="nbr_wks" default="0" type="numeric">
        <CF_WAD_Count substring="," string="#client.avar_oppWeeks#">
        <cfset avar_nbr_wks=#cnt#+1>
    </cfoutput>
    <!--- <cfif right(END_PERIOD,2) GT curWeekAvailable>
        <cfset futurePrompt=1><cfoutput> ---futurePrompt: #futurePrompt# #client.avar_oppWeeks# deldays: #client.avar_adHocDelDays# client.avar_oppWeeks: #client.avar_oppWeeks#</cfoutput> ---<br>
    </cfif> --->

<!DOCTYPE html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
<meta name="title" content="USPS - Variance Programs" />
<meta name="author" content="Field Operations Support" />
<meta http-equiv="Cache-Control" content="no-cache" />
<meta http-equiv="Cache-Control" content="no-store" />
<meta http-equiv="Pragma" content="no-cache" />
<meta name="expires" content="tue, 01 Jan 1980" />
<cfoutput>
<title>#pcesText#City Delivery Pivot Opportunity Model</title>
</cfoutput>
    <script src="/scripts/tablesort.js" type="text/javascript"></script>
    <link rel=stylesheet type="text/css" href="/css/avar_tablesort_v2.css">
    <style type="text/css">
        body {
            border-collapse: collapse;
        }

        .alink:link {color: #FFFFFF}
        .alink:visited {color: #FFFFFF}
        .alink:hover {color: #FFFFFF}
        .alink:active {color: #FFFFFF}

    </style>
    <style type="text/css">

        #dhtmltooltip{
        position: absolute;
        width: 150px;
        border: 2px solid black;
        padding: 2px;
        background-color: lightyellow;
        visibility: hidden;
        z-index: 100;
        /*Remove below line to remove shadow. Below line should always appear last within this CSS*/
        filter: progid:DXImageTransform.Microsoft.Shadow(color=gray,direction=135);
        }

    </style>
</head>

<body>
    <div id="dhtmltooltip"></div>

    <script type="text/javascript">

        /***********************************************
        * Cool DHTML tooltip script- � Dynamic Drive DHTML code library (www.dynamicdrive.com)
        * This notice MUST stay intact for legal use
        * Visit Dynamic Drive at http://www.dynamicdrive.com/ for full source code
        ***********************************************/

        var offsetxpoint=-60 //Customize x offset of tooltip
        var offsetypoint=20 //Customize y offset of tooltip
        var ie=document.all
        var ns6=document.getElementById && !document.all
        var enabletip=false
        if (ie||ns6)
        var tipobj=document.all? document.all["dhtmltooltip"] : document.getElementById? document.getElementById("dhtmltooltip") : ""

        function ietruebody(){
        return (document.compatMode && document.compatMode!="BackCompat")? document.documentElement : document.body
        }

        function ddrivetip(thetext, thecolor, thewidth){
        if (ns6||ie){
        if (typeof thewidth!="undefined") tipobj.style.width=thewidth+"px"
        if (typeof thecolor!="undefined" && thecolor!="") tipobj.style.backgroundColor=thecolor
        tipobj.innerHTML=thetext
        enabletip=true
        return false
        }
        }

        function positiontip(e){
        if (enabletip){
        var curX=(ns6)?e.pageX : event.clientX+ietruebody().scrollLeft;
        var curY=(ns6)?e.pageY : event.clientY+ietruebody().scrollTop;
        //Find out how close the mouse is to the corner of the window
        var rightedge=ie&&!window.opera? ietruebody().clientWidth-event.clientX-offsetxpoint : window.innerWidth-e.clientX-offsetxpoint-20
        var bottomedge=ie&&!window.opera? ietruebody().clientHeight-event.clientY-offsetypoint : window.innerHeight-e.clientY-offsetypoint-20

        var leftedge=(offsetxpoint<0)? offsetxpoint*(-1) : -1000

        //if the horizontal distance isn't enough to accomodate the width of the context menu
        if (rightedge<tipobj.offsetWidth)
        //move the horizontal position of the menu to the left by it's width
        tipobj.style.left=ie? ietruebody().scrollLeft+event.clientX-tipobj.offsetWidth+"px" : window.pageXOffset+e.clientX-tipobj.offsetWidth+"px"
        else if (curX<leftedge)
        tipobj.style.left="5px"
        else
        //position the horizontal position of the menu where the mouse is positioned
        tipobj.style.left=curX+offsetxpoint+"px"

        //same concept with the vertical position
        if (bottomedge<tipobj.offsetHeight)
        tipobj.style.top=ie? ietruebody().scrollTop+event.clientY-tipobj.offsetHeight-offsetypoint+"px" : window.pageYOffset+e.clientY-tipobj.offsetHeight-offsetypoint+"px"
        else
        tipobj.style.top=curY+offsetypoint+"px"
        tipobj.style.visibility="visible"
        }
        }

        function hideddrivetip(){
        if (ns6||ie){
        enabletip=false
        tipobj.style.visibility="hidden"
        tipobj.style.left="-1000px"
        tipobj.style.backgroundColor=''
        tipobj.style.width=''
        }
        }

        document.onmousemove=positiontip

    </script>


<cfparam name="viewLevel" type="string" default="N">

<cfif viewLevel EQ "N">
    <!--- far from optimal, but keeps all code in 1 file to maintain --->
    <cfif isPcesRequest>
    	<cfquery name="getOpp" datasource="#application.dsn#">
            Select 
               b_area
              ,rtrim(ltrim(b_area_name)) b_area_name
              ,#client.avar_adHocDelDays# calc_del_days
              ,(SUM(vw_car_rte_nbr)/#avar_nbr_wks#) b_car_rte_nbr
              ,((sum(ern_rt_equiv_workload)/#client.avar_adHocDelDays#)/8)*prod_fters_fact ern_rt_equiv_workload
              ,(((CAST(SUM(act_rt_equiv_workload) AS DECIMAL(18,2)) /#client.avar_adHocDelDays#)/8)*prod_fters_fact) act_rt_equiv_workload
              ,(SUM(vw_car_rte_nbr)/#avar_nbr_wks#) - (((sum(rt_pivot_dly_opp)/#client.avar_adHocDelDays#)/8)*prod_fters_fact) rt_pivot_dly_opp
              ,(SUM(vw_car_rte_nbr)/#avar_nbr_wks#) - (((sum(rt_pivot_perf_dly_act) /#client.avar_adHocDelDays#)/8)*prod_fters_fact) rt_pivot_perf_dly_act
            from var_cluster_summary_pces,pcdv_delpvar.dbo.avar_cdv_prod,lead_nbr_rts_vw with (nolock)
            where b_area=vw_area and period in (#client.lstWeeks#)
            and b_lead_fin_nbr=vw_lead_fin_nbr
            and left(b_area, 1) = '4'
            group by b_area,b_area_name,prod_fters_fact
        </cfquery>    
    <cfelse>
        <cfquery name="getOpp" datasource="#application.dsn#">
            select 
                 b_area
                ,rtrim(ltrim(b_area_name)) b_area_name
                ,#client.avar_adHocDelDays# calc_del_days,vw_car_rte_nbr b_car_rte_nbr
                ,((sum(ern_rt_equiv_workload)/#client.avar_adHocDelDays#)/8)*prod_fters_fact ern_rt_equiv_workload
                ,(((CAST(SUM(act_rt_equiv_workload) AS DECIMAL(18,2)) /#client.avar_adHocDelDays#)/8)*prod_fters_fact) act_rt_equiv_workload
                ,vw_car_rte_nbr - (((sum(rt_pivot_dly_opp)/#client.avar_adHocDelDays#)/8)*prod_fters_fact) rt_pivot_dly_opp
                ,vw_car_rte_nbr - (((sum(rt_pivot_perf_dly_act) /#client.avar_adHocDelDays#)/8)*prod_fters_fact) rt_pivot_perf_dly_act
            from var_cluster_summary with (nolock),
                #application.dsn2#.dbo.avar_cdv_prod with (nolock),
                dbo.area_nbr_rts_vw with (nolock)
            where b_area=vw_area
            and left(b_area, 1) = '4'
            and period in (#client.lstWeeks#)
            group by b_area,b_area_name,prod_fters_fact,vw_car_rte_nbr;
        </cfquery>
    </cfif>
    <cfquery name="totals" dbtype="query">
        select sum(b_car_rte_nbr) b_car_rte_nbr,
            sum(ern_rt_equiv_workload) as ern_rt_equiv_workload,
            sum(act_rt_equiv_workload) as act_rt_equiv_workload,
            sum(rt_pivot_dly_opp) as rt_pivot_dly_opp,
            sum(rt_pivot_perf_dly_act) as rt_pivot_perf_dly_act,
            sum(rt_pivot_perf_dly_act)/sum(rt_pivot_dly_opp) as pivot_opp_pct_ach
        from getOpp
    </cfquery>
    <cfif totals.pivot_opp_pct_ach LT 0>
        <cfset totals.pivot_opp_pct_ach = 0>
    <cfelseif totals.pivot_opp_pct_ach GT 100>
        <cfset totals.pivot_opp_pct_ach = 100>
    </cfif>

    <!--- ******************************************************************************************* --->
    <!---                                   Write Data to Table                                       --->
    <!--- ******************************************************************************************* --->

    <form name="form1" method="post">
        <cfoutput>
        <input type="hidden" id="isPces" name="isPces" value="#pcesFormVal#" />
        </cfoutput>
        <table width="100%" border="2" summary="This table provides an analysis of Delivery Unit's Pivot Opportunity" cellpadding="1" cellspacing="0" border="0" align="center">
            <tr>
                <td colspan="3" bgcolor="#003263">
                    <font face="verdana,arial,helvetica" color="#ffffff" size="2"><b>Return to -->&nbsp;&nbsp;<a href="avar_pivot.cfm" title="Link to Return to Pivot Summary Range Selection" class="alink">Range Selection</a>&nbsp;&nbsp; -->                    
                </td>
            </tr>
            <tr>
            <td bgcolor="003263" height="25" align="center" colspan="3">
                <font face="verdana,arial,helvetica" color="ffffff" size="2">
                <cfoutput>
                    <b>#pcesText# National City Delivery Pivot Opportunity Model #client.avar_adHocDelDays# Delivery Days &nbsp;&nbsp;#dateformat(client.avar_wk_beg_dte,"mm/dd/yyyy")#&nbsp;&nbsp;to&nbsp;&nbsp;#dateformat(client.avar_wk_end_dte,"mm/dd/yyyy")#</b></font>
                </cfoutput>
            </td>
            </tr>
            <tr bgcolor="#003263">
                <cfoutput>
                    <cfset basRteMsg="<b>Number of base routes</b><br>#NumberFormat(totals.b_car_rte_nbr,"___,___,___,___")#">
                    <cfset ernRteMsg="<b>Earned routes equivalent workload</b><br>#NumberFormat(totals.ern_rt_equiv_workload,"___,___,___,___")#">
                    <cfset actRteMsg="<b>Actual routes equivalent workload</b><br>#NumberFormat(totals.act_rt_equiv_workload,"___,___,___,___")#">

                     <td width="33%" <cfif client.pivotHelpPrompt EQ 1>style="text-align: left; cursor:help" ONMOUSEOVER="ddrivetip('#basRteMsg#','DFDFFF', 250)"; ONMOUSEOUT="hideddrivetip()"</cfif>><font face="Verdana" size="1" color="##FFFFFF"><b>&nbsp;
                       Base number of Equivalent City Routes:&nbsp;#NumberFormat(totals.b_car_rte_nbr,"___,___,___,___")#</b></font></td>
                     <td width="33%" <cfif client.pivotHelpPrompt EQ 1>style="text-align: left; cursor:help" ONMOUSEOVER="ddrivetip('#ernRteMsg#','DFDFFF', 250)"; ONMOUSEOUT="hideddrivetip()"</cfif>><font face="Verdana" size="1" color="##FFFFFF"><b>&nbsp;
                       Earned Rts Equivalent Workload:&nbsp;#NumberFormat(totals.ern_rt_equiv_workload,"___,___,___,___")#</b></font></td>
                     <td width="33%" <cfif client.pivotHelpPrompt EQ 1>style="text-align: left; cursor:help" ONMOUSEOVER="ddrivetip('#actRteMsg#','DFDFFF', 250)"; ONMOUSEOUT="hideddrivetip()"</cfif>><font face="Verdana" size="1" color="##FFFFFF"><b>&nbsp;
                       Actual Rts Equivalent Workhours:&nbsp;#NumberFormat(totals.act_rt_equiv_workload,"___,___,___,___")#</b></font></td>
                 </cfoutput>
            </tr>
            <tr bgcolor="#003263">
                <cfoutput>
                    <cfset pivPlnMsg="<b>Route Pivot Opportunity Plan</b><br>Daily pivot opportunity = #NumberFormat(totals.rt_pivot_dly_opp,"___,___,___,___")# routes.">
                    <cfset pivActMsg="<b>Route Pivot Performance Actual</b><br>Daily pivot captured = #NumberFormat(totals.rt_pivot_perf_dly_act,"___,___,___,___")# routes.<br>Opportunity lost: = #NumberFormat(totals.rt_pivot_dly_opp-totals.rt_pivot_perf_dly_act,"___,___,___,___")#<br><i>(Rte Pivot Opp Plan #NumberFormat(totals.rt_pivot_dly_opp,"___,___,___,___")#) - (Rte Pivot Perf Act #NumberFormat(totals.rt_pivot_perf_dly_act,"___,___,___,___")#).</i>">
                    <cfset pctOppMsg="<b>Percent Opportunity Achieved</b><br>#DecimalFormat(totals.pivot_opp_pct_ach*100)#% of pivoting opportunity captured.">
                     <td width="33%" <cfif client.pivotHelpPrompt EQ 1>style="text-align: left; cursor:help" ONMOUSEOVER="ddrivetip('#pivPlnMsg#','DFDFFF', 250)"; ONMOUSEOUT="hideddrivetip()"</cfif>><font face="Verdana" size="1" color="##FFFFFF"><b>&nbsp;
                       Daily Pivot Opportunity:&nbsp;#NumberFormat(totals.rt_pivot_dly_opp,"___,___,___,___")#</b></font></td>
                     <td width="33%" <cfif client.pivotHelpPrompt EQ 1>style="text-align: left; cursor:help" ONMOUSEOVER="ddrivetip('#pivActMsg#','DFDFFF', 375)"; ONMOUSEOUT="hideddrivetip()"</cfif>><font face="Verdana" size="1" color="##FFFFFF"><b>&nbsp;
                       Rts Pivot Performance Actual:&nbsp;#NumberFormat(totals.rt_pivot_perf_dly_act,"___,___,___,___")#</b></font></td>
                     <td width="33%" <cfif client.pivotHelpPrompt EQ 1>style="text-align: left; cursor:help" ONMOUSEOVER="ddrivetip('#pctOppMsg#','DFDFFF', 250)"; ONMOUSEOUT="hideddrivetip()"</cfif>><font face="Verdana" size="1" color="##FFFFFF"><b>&nbsp;
                     Pivot Opportunity Percent Achieved:&nbsp;#IIF(totals.pivot_opp_pct_ach GT 1,DE('100'),DE(NumberFormat(totals.pivot_opp_pct_ach*100,'999')))#</b></font></td>
                </cfoutput>
            </tr>

            <tr>
            <td bgcolor="003263" colspan="3">
                <table border="0" width="100%" cellspacing="0" border="0" cellpadding="1">
                <tr>
                    <td colspan="2" bgcolor="FFFFFF" height="20">
                        <table cellpadding="0" width="100%" cellspacing="0" class="generique style-alternative;sortable-onload-9-reverse;" style="font-size:11px">
                          <thead>
                                  <TR>
                                      <th align="center" width="25" valign="bottom">Chart</th>
                                    <th class="sortable" align="center" width="50" valign="bottom">Area Code</th>
                                    <th class="sortable" align="center" width="150" valign="bottom">Area Name</th>
                                    <th class="sortable-currency" align="center" width="100" valign="bottom">Base Nbr of Equivalent City Rts</th>
                                    <th class="sortable-currency" align="center" width="100" valign="bottom">Earned Rts Equivalent Workload</th>
                                    <th class="sortable-currency" align="center" width="100" valign="bottom">Actual Rts Equivalent Workhours</th>
                                    <th class="sortable-currency" align="center" width="100" valign="bottom">Daily Pivot Opportunity</th>
                                    <th class="sortable-currency" align="center" width="100" valign="bottom">Rts Pivot Performance Actual</th>
                                    <th class="sortable-currency" align="center" width="100" valign="bottom">Pivot Opportunity % Achieved</th>
                                </TR>
                            </thead>
                            <tbody>
                                <cfoutput query="getOpp">
                                    <cfset ubasRteMsg="<b>Number of base routes</b><br>#NumberFormat(b_car_rte_nbr,'999,999.00')#">
                                    <cfset uernRteMsg="<b>Earned routes equivalent workload</b><br>#DecimalFormat(ern_rt_equiv_workload)#">
                                    <cfset uactRteMsg="<b>Actual routes equivalent workload</b><br>#DecimalFormat(act_rt_equiv_workload)#">
                                    <cfset upivPlnMsg="<b>Route Pivot Opportunity Plan</b><br>Daily pivot opportunity = #DecimalFormat(rt_pivot_dly_opp)# routes.">
                                    <CF_WAD_Capitalize TitleCase="yes" string="#b_area_name#" outvar="OutputArea">
                                    <cfif rt_pivot_perf_dly_act LT 0><cfset ActMsgMinus="<br><font color=FF0000>#OutputArea# Area ran #DecimalFormat(ABS(rt_pivot_perf_dly_act))# daily equivalent routes over the base routes.</font>"><cfelse><cfset ActMsgMinus=""></cfif>
                                    <cfset upivActMsg="<b>Route Pivot Performance Actual</b><br>Daily pivot captured = #DecimalFormat(rt_pivot_perf_dly_act)# routes.<br>Opportunity lost: = #DecimalFormat(rt_pivot_dly_opp-rt_pivot_perf_dly_act)#<br><i>(Rte Pivot Opp Plan #DecimalFormat(rt_pivot_dly_opp)#) - (Rte Pivot Perf Act #DecimalFormat(rt_pivot_perf_dly_act)#)#ActMsgMinus#</i>">
                                    <cfif rt_pivot_dly_opp LTE 0 AND rt_pivot_perf_dly_act GT 0>
                                        <cfset opp_pct_ach=1>
                                    <cfelseif rt_pivot_perf_dly_act LTE 0 AND rt_pivot_dly_opp LTE 0>
                                        <cfset opp_pct_ach=0>
                                    <cfelseif rt_pivot_dly_opp GT 0 AND rt_pivot_perf_dly_act LT 0>
                                        <cfset opp_pct_ach=0>
                                    <cfelse>
                                        <cfset opp_pct_ach=#rt_pivot_perf_dly_act#/#rt_pivot_dly_opp#>
                                        <cfif opp_pct_ach GTE 1>
                                            <cfset opp_pct_ach=1>
                                        </cfif>
                                    </cfif>
                                    <cfset upctOppMsg="<b>Percent Opportunity Achieved</b><br>#DecimalFormat(opp_pct_ach*100)#% of pivoting opportunity captured.">

                                    <tr>
                                        <td align="center" width="25" valign="bottom"><a href="pivot/pivot_main.cfm?area_no=#b_area#&do=1&scope=A&cftrk=1&isPces=#pcesFormVal#" title="Link to Area Pivot Chart" target="_blank"><img src="/images/avar_graph.gif" width="14" height="15" id="Chart Image"></a></td>
                                        <td align="center" width="75" valign="bottom">
                                            <a href="avar_pivot2.cfm?viewLevel=C&b_area=#b_area#&isPces=#pcesFormVal#" title="Link to Area Pivot Report">#b_area#</a>
                                        </td>
                                        <td align="left" width="125" valign="bottom" style="text-align:left;"><a href="avar_pivot2.cfm?viewLevel=C&b_area=#b_area#&isPces=#pcesFormVal#" title="Link to Area Pivot Report">#b_area_name#</a></td>
                                        <td align="center" width="95" valign="bottom" <cfif client.pivotHelpPrompt EQ 1>style="text-align: center; cursor:help" ONMOUSEOVER="ddrivetip('#ubasRteMsg#','DFDFFF', 250)"; ONMOUSEOUT="hideddrivetip()"</cfif>>#NumberFormat(b_car_rte_nbr,'999,999.00')#</td>
                                        <td align="center" width="95" valign="bottom" <cfif client.pivotHelpPrompt EQ 1>style="text-align: center; cursor:help" ONMOUSEOVER="ddrivetip('#uernRteMsg#','DFDFFF', 250)"; ONMOUSEOUT="hideddrivetip()"</cfif>>#DecimalFormat(ern_rt_equiv_workload)#</td>
                                        <td align="center" width="95" valign="bottom" <cfif client.pivotHelpPrompt EQ 1>style="text-align: center; cursor:help" ONMOUSEOVER="ddrivetip('#uactRteMsg#','DFDFFF', 250)"; ONMOUSEOUT="hideddrivetip()"</cfif>>#DecimalFormat(act_rt_equiv_workload)#</td>
                                        <td align="center" width="95" valign="bottom" bgcolor="#dailyOppColor#" <cfif client.pivotHelpPrompt EQ 1>style="text-align: center; cursor:help" ONMOUSEOVER="ddrivetip('#upivPlnMsg#','DFDFFF', 250)"; ONMOUSEOUT="hideddrivetip()"</cfif>>#DecimalFormat(rt_pivot_dly_opp)#</td>
                                        <td align="center" width="95" valign="bottom" <cfif client.pivotHelpPrompt EQ 1>style="text-align: center; cursor:help" ONMOUSEOVER="ddrivetip('#upivActMsg#','DFDFFF', 375)"; ONMOUSEOUT="hideddrivetip()"</cfif>>#DecimalFormat(rt_pivot_perf_dly_act)#</td>
                                        <cfsilent>
                                            <cfset pachbgcolor=arrColor[arrLen].color>
                                            <cfloop index="i" from="#arrLen#" to="1" step="-1">
                                                <cfif arrColor[i].limit GTE opp_pct_ach>
                                                    <cfset pachbgcolor=arrColor[i].color>
                                                </cfif>
                                            </cfloop>
                                        </cfsilent>
                                        <td align="center" width="100" valign="bottom" <cfif client.pivotHelpPrompt EQ 1>style="text-align: center; cursor:help" ONMOUSEOVER="ddrivetip('#upctOppMsg#','DFDFFF', 250)"; ONMOUSEOUT="hideddrivetip()"</cfif> bgcolor="#pachbgcolor#">#DecimalFormat(opp_pct_ach*100)#</td>
                                    </tr>
                                </cfoutput>
                                <cfoutput query="totals">
                                    <cfset ubasRteMsg="<b>Number of base routes</b><br>#NumberFormat(b_car_rte_nbr,'999,999.00')#">
                                    <cfset uernRteMsg="<b>Earned routes equivalent workload</b><br>#DecimalFormat(ern_rt_equiv_workload)#">
                                    <cfset uactRteMsg="<b>Actual routes equivalent workload</b><br>#DecimalFormat(act_rt_equiv_workload)#">
                                    <cfset upivPlnMsg="<b>Route Pivot Opportunity Plan</b><br>Daily pivot opportunity = #DecimalFormat(rt_pivot_dly_opp)# routes.">
                                    <cfif rt_pivot_perf_dly_act LT 0><cfset ActMsgMinus="<br><font color=FF0000>National ran #DecimalFormat(ABS(rt_pivot_perf_dly_act))# daily equivalent routes over the base routes.</font>"><cfelse><cfset ActMsgMinus=""></cfif>
                                    <cfset upivActMsg="<b>Route Pivot Performance Actual</b><br>Daily pivot captured = #DecimalFormat(rt_pivot_perf_dly_act)# routes.<br>Opportunity lost: = #DecimalFormat(rt_pivot_dly_opp-rt_pivot_perf_dly_act)#<br><i>(Rte Pivot Opp Plan #DecimalFormat(rt_pivot_dly_opp)#) - (Rte Pivot Perf Act #DecimalFormat(rt_pivot_perf_dly_act)#)#ActMsgMinus#</i>">
                                    <cfif rt_pivot_dly_opp LTE 0 AND rt_pivot_perf_dly_act GT 0>
                                        <cfset opp_pct_ach=1>
                                    <cfelseif rt_pivot_perf_dly_act LTE 0 AND rt_pivot_dly_opp LTE 0>
                                        <cfset opp_pct_ach=0>
                                    <cfelseif rt_pivot_dly_opp GT 0 AND rt_pivot_perf_dly_act LT 0>
                                        <cfset opp_pct_ach=0>
                                    <cfelse>
                                        <cfset opp_pct_ach=#rt_pivot_perf_dly_act#/#rt_pivot_dly_opp#>
                                        <cfif opp_pct_ach GTE 1>
                                            <cfset opp_pct_ach=1>
                                        </cfif>
                                    </cfif>
                                    <cfset upctOppMsg="<b>Percent Opportunity Achieved</b><br>#DecimalFormat(opp_pct_ach*100)#% of pivoting opportunity captured.">

                                    <tr>
                                        <td align="center" width="25" valign="bottom"><a href="pivot/pivot_main.cfm?area_no=4Z&area_name=National&scope=N&do=1&cftrk=1&isPces=#pcesFormVal#" title="Link to National Level Pivot Chart" target="_blank"><img src="/images/avar_graph.gif" width="14" height="15" id="Chart Image"></a></td>
                                        <td align="left" width="75" valign="bottom">
                                            <a href="avar_pivot2.cfm?viewLevel=NC&b_area=4Z&isPces=#pcesFormVal#" title="Link to Cluster Level Pivot Report">4Z</a>
                                        </td>
                                        <td align="center" width="125" valign="bottom" style="text-align:left;"><a href="avar_pivot2.cfm?viewLevel=NC&b_area=4Z&b_area_name=National&isPces=#pcesFormVal#" title="Link to Cluster Level Pivot Report">NATIONAL</a></td>
                                        <td align="center" width="95" valign="bottom" <cfif client.pivotHelpPrompt EQ 1>style="text-align: center; cursor:help" ONMOUSEOVER="ddrivetip('#ubasRteMsg#','DFDFFF', 250)"; ONMOUSEOUT="hideddrivetip()"</cfif>>#NumberFormat(b_car_rte_nbr,'999,999.00')#</td>
                                        <td align="center" width="95" valign="bottom" <cfif client.pivotHelpPrompt EQ 1>style="text-align: center; cursor:help" ONMOUSEOVER="ddrivetip('#uernRteMsg#','DFDFFF', 250)"; ONMOUSEOUT="hideddrivetip()"</cfif>>#DecimalFormat(ern_rt_equiv_workload)#</td>
                                        <td align="center" width="95" valign="bottom" <cfif client.pivotHelpPrompt EQ 1>style="text-align: center; cursor:help" ONMOUSEOVER="ddrivetip('#uactRteMsg#','DFDFFF', 250)"; ONMOUSEOUT="hideddrivetip()"</cfif>>#DecimalFormat(act_rt_equiv_workload)#</td>
                                        <td align="center" width="95" valign="bottom" bgcolor="#dailyOppColor#" <cfif client.pivotHelpPrompt EQ 1>style="text-align: center; cursor:help" ONMOUSEOVER="ddrivetip('#upivPlnMsg#','DFDFFF', 250)"; ONMOUSEOUT="hideddrivetip()"</cfif>>#DecimalFormat(rt_pivot_dly_opp)#</td>
                                        <td align="center" width="95" valign="bottom" <cfif client.pivotHelpPrompt EQ 1>style="text-align: center; cursor:help" ONMOUSEOVER="ddrivetip('#upivActMsg#','DFDFFF', 375)"; ONMOUSEOUT="hideddrivetip()"</cfif>>#DecimalFormat(rt_pivot_perf_dly_act)#</td>
                                        <cfsilent>
                                            <cfset pachbgcolor=arrColor[arrLen].color>
                                            <cfloop index="i" from="#arrLen#" to="1" step="-1">
                                                <cfif arrColor[i].limit GTE opp_pct_ach>
                                                    <cfset pachbgcolor=arrColor[i].color>
                                                </cfif>
                                            </cfloop>
                                        </cfsilent>
                                        <td align="center" width="100" valign="bottom" <cfif client.pivotHelpPrompt EQ 1>style="text-align: center; cursor:help" ONMOUSEOVER="ddrivetip('#upctOppMsg#','DFDFFF', 250)"; ONMOUSEOUT="hideddrivetip()"</cfif> bgcolor="#pachbgcolor#">#DecimalFormat(opp_pct_ach*100)#</td>
                                    </tr>
                                </cfoutput>
                            </tbody>
                        </table>
                    </td>
                </tr>
                </table>
            </td>
            </tr>
            <tr>
                <td align="center" width="100%" colspan="4">
                    <table border="0" cellspacing="0" width="100%" height="44" align="center">
                          <tr align="center" valign="middle">
                             <td width="100%" height="44" bgcolor="#F8F8FF" valign="middle" align="center" valign="middle">
                                <font size="2"><a href="avar_pivot_xls.cfm?viewLevel=N" title="Download Area Level City Delivery Pivot Opportunity to Excel"><img src="/images/avar_send2excel.gif" width="80" height="15" alt="Download Area Level City Delivery Pivot Opportunity to Excel" border="0" align="middle"></a> National Area Level Data&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
                                <a href="avar_pivot_xls.cfm?viewLevel=NU" title="Download Unit Level City Delivery Pivot Opportunity to Excel"><img src="/images/avar_send2excel.gif" width="80" height="15" alt="Download Unit Level City Delivery Pivot Opportunity to Excel" border="0" align="middle"></a> National Unit Level Data</font>
                             </td>
                        </tr>
                    </table>
                </td>
            </tr>

            </table>
        </form>
    </cfif>

    <!--- ********************************************************************************************************************** --->
    <cfif viewLevel EQ "C">
    
    <cftry>
    <cfif isPcesRequest>
        <cfquery name="getOpp" datasource="#application.dsn#">
            Select b_cluster,replace(b_cluster_name, ' DISTRICT', '') b_cluster_name, rtrim(ltrim(b_area_name)) b_area_name,
                #client.avar_adHocDelDays#  calc_del_days,
                (SUM(vw_car_rte_nbr)/#avar_nbr_wks#) b_car_rte_nbr,
                ((sum(ern_rt_equiv_workload)/#client.avar_adHocDelDays# )/8)*prod_fters_fact ern_rt_equiv_workload,
                ((sum(act_rt_equiv_workload)/#client.avar_adHocDelDays# )/8) * prod_fters_fact act_rt_equiv_workload,
            
                (SUM(vw_car_rte_nbr)/#avar_nbr_wks#) - (((sum(rt_pivot_dly_opp)/#client.avar_adHocDelDays# )/8)*prod_fters_fact) rt_pivot_dly_opp,
                (SUM(vw_car_rte_nbr)/#avar_nbr_wks#) - (((sum(rt_pivot_perf_dly_act) /#client.avar_adHocDelDays# )/8)*prod_fters_fact) rt_pivot_perf_dly_act
            from var_cluster_summary_pces,
                pcdv_delpvar.dbo.avar_cdv_prod,
                lead_nbr_rts_vw with (nolock)
            where b_cluster=vw_cluster 
            and period in (#client.lstWeeks#)
            and b_area='#url.b_area#' 
            and b_lead_fin_nbr=vw_lead_fin_nbr
            group by b_cluster,b_cluster_name,prod_fters_fact,b_area_name;    
        </cfquery>    
    <cfelse>
        <cfquery name="getOpp" datasource="#application.dsn#">
            Select b_cluster,replace(b_cluster_name, ' DISTRICT', '') b_cluster_name, rtrim(ltrim(b_area_name)) b_area_name,
                #client.avar_adHocDelDays# calc_del_days,
                AVG(vw_car_rte_nbr) b_car_rte_nbr,
                ((sum(ern_rt_equiv_workload)/#client.avar_adHocDelDays#)/8)*prod_fters_fact ern_rt_equiv_workload,
                ((sum(act_rt_equiv_workload)/#client.avar_adHocDelDays#)/8) * prod_fters_fact act_rt_equiv_workload,
                AVG(vw_car_rte_nbr) - (((sum(rt_pivot_dly_opp)/#client.avar_adHocDelDays#)/8)*prod_fters_fact) rt_pivot_dly_opp,
                AVG(vw_car_rte_nbr) - (((sum(rt_pivot_perf_dly_act) /#client.avar_adHocDelDays#)/8)*prod_fters_fact) rt_pivot_perf_dly_act
            from var_cluster_summary with (nolock),
                #application.dsn2#.dbo.avar_cdv_prod with (nolock),
                cluster_nbr_rts_vw with (nolock)
            where b_cluster=vw_cluster AND period in (#client.lstWeeks#)
            and b_area='#url.b_area#'
            group by b_cluster,b_cluster_name, b_area_name, prod_fters_fact;    
        </cfquery>
    </cfif>
    <cfcatch>
    	<cfdump var="#cfcatch#" format="text" abort="true" />
    </cfcatch>
    </cftry>
    
    <cfquery name="totals" dbtype="query">
        select sum(b_car_rte_nbr) b_car_rte_nbr,
            sum(ern_rt_equiv_workload) as ern_rt_equiv_workload,
            sum(act_rt_equiv_workload) as act_rt_equiv_workload,
            sum(rt_pivot_dly_opp) as rt_pivot_dly_opp,
            sum(rt_pivot_perf_dly_act) as rt_pivot_perf_dly_act,
            sum(rt_pivot_perf_dly_act)/sum(rt_pivot_dly_opp) as pivot_opp_pct_ach
        from getOpp
    </cfquery>
    <cfif totals.pivot_opp_pct_ach LT 0>
        <cfset totals.pivot_opp_pct_ach = 0>
    <cfelseif totals.pivot_opp_pct_ach GT 100>
        <cfset totals.pivot_opp_pct_ach = 100>
    </cfif>

    <!--- ******************************************************************************************* --->
    <!---                                   Write Data to Table                                       --->
    <!--- ******************************************************************************************* --->

    <form name="form1" method="post">
        <table width="100%" border="2" summary="This table provides an analysis of Delivery Unit's Pivot Opportunity" cellpadding="1" cellspacing="0" border="0" align="center">
            <tr>
                <td colspan="3" bgcolor="#003263">
                    <font face="verdana,arial,helvetica" color="#ffffff" size="2"><b>Return to -->&nbsp;&nbsp;<a href="avar_pivot.cfm" title="Link to Return to Pivot Summary Range Selection" class="alink">Range Selection</a>&nbsp;&nbsp; -->
                    <cfoutput><a href="avar_pivot2.cfm?viewLevel=N&isPces=#pcesFormVal#" title="Link to National Level" class="alink">National Level</a></cfoutput>
                </td>
            </tr>
            <tr>
            <td bgcolor="003263" height="25" align="center" colspan="3">
            <font face="verdana,arial,helvetica" color="ffffff" size="2"><b><cfoutput>#pcesText#<CF_WAD_Capitalize TitleCase="yes">#getOpp.b_area_name[1]# Area</CF_WAD_Capitalize> City Delivery Pivot Opportunity Model #client.avar_adHocDelDays# Delivery Days &nbsp;&nbsp;#dateformat(client.avar_wk_beg_dte,"mm/dd/yyyy")#&nbsp;&nbsp;to&nbsp;&nbsp;#dateformat(client.avar_wk_end_dte,"mm/dd/yyyy")#</cfoutput></b></font></td>
            </tr>
            <tr bgcolor="#003263">
                <cfoutput>
                    <cfset basRteMsg="<b>Number of base routes</b><br>#NumberFormat(totals.b_car_rte_nbr,"___,___,___,___")#">
                    <cfset ernRteMsg="<b>Earned routes equivalent workload</b><br>#NumberFormat(totals.ern_rt_equiv_workload,"___,___,___,___")#">
                    <cfset actRteMsg="<b>Actual routes equivalent workload</b><br>#NumberFormat(totals.act_rt_equiv_workload,"___,___,___,___")#">

                     <td width="33%" <cfif client.pivotHelpPrompt EQ 1>style="text-align: left; cursor:help" ONMOUSEOVER="ddrivetip('#basRteMsg#','DFDFFF', 250)"; ONMOUSEOUT="hideddrivetip()"</cfif>><font face="Verdana" size="1" color="##FFFFFF"><b>&nbsp;
                       Base number of Equivalent City Routes:&nbsp;#NumberFormat(totals.b_car_rte_nbr,"___,___,___,___")#</b></font></td>
                     <td width="33%" <cfif client.pivotHelpPrompt EQ 1>style="text-align: left; cursor:help" ONMOUSEOVER="ddrivetip('#ernRteMsg#','DFDFFF', 250)"; ONMOUSEOUT="hideddrivetip()"</cfif>><font face="Verdana" size="1" color="##FFFFFF"><b>&nbsp;
                       Earned Rts Equivalent Workload:&nbsp;#NumberFormat(totals.ern_rt_equiv_workload,"___,___,___,___")#</b></font></td>
                     <td width="33%" <cfif client.pivotHelpPrompt EQ 1>style="text-align: left; cursor:help" ONMOUSEOVER="ddrivetip('#actRteMsg#','DFDFFF', 250)"; ONMOUSEOUT="hideddrivetip()"</cfif>><font face="Verdana" size="1" color="##FFFFFF"><b>&nbsp;
                       Actual Rts Equivalent Workhours:&nbsp;#NumberFormat(totals.act_rt_equiv_workload,"___,___,___,___")#</b></font></td>
                 </cfoutput>
            </tr>
            <tr bgcolor="#003263">
                <cfoutput>
                    <cfset pivPlnMsg="<b>Route Pivot Opportunity Plan</b><br>Daily pivot opportunity = #NumberFormat(totals.rt_pivot_dly_opp,"___,___,___,___")# routes.">
                    <cfset pivActMsg="<b>Route Pivot Performance Actual</b><br>Daily pivot captured = #NumberFormat(totals.rt_pivot_perf_dly_act,"___,___,___,___")# routes.<br>Opportunity lost: = #NumberFormat(totals.rt_pivot_dly_opp-totals.rt_pivot_perf_dly_act,"___,___,___,___")#<br><i>(Rte Pivot Opp Plan #NumberFormat(totals.rt_pivot_dly_opp,"___,___,___,___")#) - (Rte Pivot Perf Act #NumberFormat(totals.rt_pivot_perf_dly_act,"___,___,___,___")#).</i>">
                    <cfset pctOppMsg="<b>Percent Opportunity Achieved</b><br>#DecimalFormat(totals.pivot_opp_pct_ach*100)#% of pivoting opportunity captured.">
                     <td width="33%" <cfif client.pivotHelpPrompt EQ 1>style="text-align: left; cursor:help" ONMOUSEOVER="ddrivetip('#pivPlnMsg#','DFDFFF', 250)"; ONMOUSEOUT="hideddrivetip()"</cfif>><font face="Verdana" size="1" color="##FFFFFF"><b>&nbsp;
                       Daily Pivot Opportunity:&nbsp;#NumberFormat(totals.rt_pivot_dly_opp,"___,___,___,___")#</b></font></td>
                     <td width="33%" <cfif client.pivotHelpPrompt EQ 1>style="text-align: left; cursor:help" ONMOUSEOVER="ddrivetip('#pivActMsg#','DFDFFF', 375)"; ONMOUSEOUT="hideddrivetip()"</cfif>><font face="Verdana" size="1" color="##FFFFFF"><b>&nbsp;
                       Rts Pivot Performance Actual:&nbsp;#NumberFormat(totals.rt_pivot_perf_dly_act,"___,___,___,___")#</b></font></td>
                     <td width="33%" <cfif client.pivotHelpPrompt EQ 1>style="text-align: left; cursor:help" ONMOUSEOVER="ddrivetip('#pctOppMsg#','DFDFFF', 250)"; ONMOUSEOUT="hideddrivetip()"</cfif>><font face="Verdana" size="1" color="##FFFFFF"><b>&nbsp;
                     Pivot Opportunity Percent Achieved:&nbsp;#IIF(totals.pivot_opp_pct_ach GT 1,DE('100'),DE(NumberFormat(totals.pivot_opp_pct_ach*100,'999')))#</b></font></td>
                </cfoutput>
            </tr>

            <tr>
            <td bgcolor="003263" colspan="3">
                <table border="0" width="100%" cellspacing="0" border="0" cellpadding="1">
                <tr>
                    <td colspan="2" bgcolor="FFFFFF" height="20">
                        <table cellpadding="0" width="100%" cellspacing="0" class="generique style-alternative;sortable-onload-9-reverse;" style="font-size:11px">
                          <thead>
                                  <TR>
                                      <th align="center" width="25" valign="bottom">Chart</th>
                                    <th class="sortable" align="center" width="50" valign="bottom">Cluster</th>
                                    <th class="sortable" align="center" width="170" valign="bottom">Cluster Name</th>
                                    <th class="sortable-currency" align="center" width="100" valign="bottom">Base Nbr of Equivalent City Rts</th>
                                    <th class="sortable-currency" align="center" width="100" valign="bottom">Earned Rts Equivalent Workload</th>
                                    <th class="sortable-currency" align="center" width="100" valign="bottom">Actual Rts Equivalent Workhours</th>
                                    <th class="sortable-currency" align="center" width="100" valign="bottom">Daily Pivot Opportunity</th>
                                    <th class="sortable-currency" align="center" width="100" valign="bottom">Rts Pivot Performance Actual</th>
                                    <th class="sortable-currency" align="center" width="100" valign="bottom">Pivot Opportunity % Achieved</th>
                                </TR>
                            </thead>
                            <tbody>
                                <cfoutput query="getOpp">
                                    <cfset ubasRteMsg="<b>Number of base routes</b><br>#NumberFormat(b_car_rte_nbr,'999,999.00')#">
                                    <cfset uernRteMsg="<b>Earned routes equivalent workload</b><br>#DecimalFormat(ern_rt_equiv_workload)#">
                                    <cfset uactRteMsg="<b>Actual routes equivalent workload</b><br>#DecimalFormat(act_rt_equiv_workload)#">
                                    <cfset upivPlnMsg="<b>Route Pivot Opportunity Plan</b><br>Daily pivot opportunity = #DecimalFormat(rt_pivot_dly_opp)# routes.">
                                    <cfif rt_pivot_perf_dly_act LT 0><cfset ActMsgMinus="<br><font color=FF0000>#b_cluster_name# ran #DecimalFormat(ABS(rt_pivot_perf_dly_act))# daily equivalent routes over the base routes.</font>"><cfelse><cfset ActMsgMinus=""></cfif>
                                    <cfset upivActMsg="<b>Route Pivot Performance Actual</b><br>Daily pivot captured = #DecimalFormat(rt_pivot_perf_dly_act)# routes.<br>Opportunity lost: = #DecimalFormat(rt_pivot_dly_opp-rt_pivot_perf_dly_act)#<br><i>(Rte Pivot Opp Plan #DecimalFormat(rt_pivot_dly_opp)#) - (Rte Pivot Perf Act #DecimalFormat(rt_pivot_perf_dly_act)#)#ActMsgMinus#</i>">
                                    <cfif rt_pivot_dly_opp LTE 0 AND rt_pivot_perf_dly_act GT 0>
                                        <cfset opp_pct_ach=1>
                                    <cfelseif rt_pivot_perf_dly_act LTE 0 AND rt_pivot_dly_opp LTE 0>
                                        <cfset opp_pct_ach=0>
                                    <cfelseif rt_pivot_dly_opp GT 0 AND rt_pivot_perf_dly_act LT 0>
                                        <cfset opp_pct_ach=0>
                                    <cfelse>
                                        <cfset opp_pct_ach=#rt_pivot_perf_dly_act#/#rt_pivot_dly_opp#>
                                        <cfif opp_pct_ach GTE 1>
                                            <cfset opp_pct_ach=1>
                                        </cfif>
                                    </cfif>
                                    <cfset upctOppMsg="<b>Percent Opportunity Achieved</b><br>#DecimalFormat(opp_pct_ach*100)#% of pivoting opportunity captured.">

                                    <tr>
                                        <td align="center" width="25" valign="bottom"><a href="pivot/pivot_main.cfm?area_no=#b_area#&cluster_no=#b_cluster#&scope=C&do=2&cftrk=1&isPces=#pcesFormVal#" title="Link to Cluster Level Pivot Chart" target="_blank"><img src="/images/avar_graph.gif" width="14" height="15" id="Chart Image"></a></td>
                                        <td align="center" width="50" valign="bottom">
                                            <a href="avar_pivot2.cfm?viewLevel=M&b_cluster=#b_cluster#&b_area=#b_area#&isPces=#pcesFormVal#" title="Link to Cluster Level Pivot Report">#b_cluster#</a>
                                        </td>
                                        <td align="center" width="170" valign="bottom" style="text-align:left;" nowrap><a href="avar_pivot2.cfm?viewLevel=M&b_cluster=#b_cluster#&b_area=#b_area#&isPces=#pcesFormVal#" title="Link to Cluster Level Pivot Report">#b_cluster_name#</a></td>
                                        <td align="center" width="95" valign="bottom" <cfif client.pivotHelpPrompt EQ 1>style="text-align: center; cursor:help" ONMOUSEOVER="ddrivetip('#ubasRteMsg#','DFDFFF', 250)"; ONMOUSEOUT="hideddrivetip()"</cfif>>#NumberFormat(b_car_rte_nbr,'999,999.00')#</td>
                                            <td align="center" width="95" valign="bottom" <cfif client.pivotHelpPrompt EQ 1>style="text-align: center; cursor:help" ONMOUSEOVER="ddrivetip('#uernRteMsg#','DFDFFF', 250)"; ONMOUSEOUT="hideddrivetip()"</cfif>>#DecimalFormat(ern_rt_equiv_workload)#</td>
                                            <td align="center" width="95" valign="bottom" <cfif client.pivotHelpPrompt EQ 1>style="text-align: center; cursor:help" ONMOUSEOVER="ddrivetip('#uactRteMsg#','DFDFFF', 250)"; ONMOUSEOUT="hideddrivetip()"</cfif>>#DecimalFormat(act_rt_equiv_workload)#</td>
                                            <td align="center" width="95" bgcolor="#dailyOppColor#" valign="bottom" <cfif client.pivotHelpPrompt EQ 1>style="text-align: center; cursor:help" ONMOUSEOVER="ddrivetip('#upivPlnMsg#','DFDFFF', 250)"; ONMOUSEOUT="hideddrivetip()"</cfif>>#DecimalFormat(rt_pivot_dly_opp)#</td>
                                            <td align="center" width="95" valign="bottom" <cfif client.pivotHelpPrompt EQ 1>style="text-align: center; cursor:help" ONMOUSEOVER="ddrivetip('#upivActMsg#','DFDFFF', 375)"; ONMOUSEOUT="hideddrivetip()"</cfif>>#DecimalFormat(rt_pivot_perf_dly_act)#</td>
                                            <cfsilent>
                                                <cfset pachbgcolor=arrColor[arrLen].color>
                                                <cfloop index="i" from="#arrLen#" to="1" step="-1">
                                                    <cfif arrColor[i].limit GTE opp_pct_ach>
                                                        <cfset pachbgcolor=arrColor[i].color>
                                                    </cfif>
                                                </cfloop>
                                            </cfsilent>
                                            <td align="center" width="100" valign="bottom" <cfif client.pivotHelpPrompt EQ 1>style="text-align: center; cursor:help" ONMOUSEOVER="ddrivetip('#upctOppMsg#','DFDFFF', 250)"; ONMOUSEOUT="hideddrivetip()"</cfif> bgcolor="#pachbgcolor#">#DecimalFormat(opp_pct_ach*100)#</td>
                                        </tr>
                                </cfoutput>
                            </tbody>
                        </table>
                    </td>
                </tr>
                </table>
            </td>
            </tr>
            <tr>
                <td align="center" width="100%" colspan="4">
                    <table border="0" cellspacing="0" width="100%" height="44" align="center">
                          <tr align="center" valign="middle">
                             <td width="100%" height="44" bgcolor="#F8F8FF" valign="middle" align="center" valign="middle">
                                <cfoutput><a href="avar_pivot_xls.cfm?viewLevel=C&b_area=#b_area#" title="Download City Delivery Pivot Opportunity to Excel"><img src="/images/avar_send2excel.gif" width="80" height="15" alt="Download City Delivery Pivot Opportunity to Excel" border="0"></a></cfoutput>
                             </td>
                        </tr>
                    </table>
                </td>
            </tr>
            </table>
        </form>
    </cfif>

    <!--- ********************************************************************************************************************** --->
    <cfif viewLevel EQ "M">
    
    <cfif isPcesRequest>
    	<cfquery name="getOpp" datasource="#application.dsn#">
            select b_mpoo,b_lead_name,#client.avar_adhocdeldays# calc_del_days,(vw_car_rte_nbr) b_car_rte_nbr, rtrim(ltrim(b_area_name)) b_area_name,
            b_cluster, replace(b_cluster_name, ' DISTRICT', '') b_cluster_name,
            ((sum(cd_ern_hrs_ldc21+cd_ern_hrs_ldc22+cd_ern_hrs_ldc26)/
            #client.avar_adhocdeldays#)/8)*prod_fters_fact
            ern_rt_equiv_workload,
    
            (((cast(sum(w_hrs_ldc21+w_hrs_ldc22+w_hrs_ldc26+w_hrs_ldc29) as decimal(18,2)) /#client.avar_adhocdeldays#)/8)
            *prod_fters_fact)
            act_rt_equiv_workload,
    
            ((vw_car_rte_nbr))-
            (((cast(sum(cd_ern_hrs_ldc21+cd_ern_hrs_ldc22+cd_ern_hrs_ldc26) as decimal(18,2)) /#client.avar_adhocdeldays#)/8)
            *prod_fters_fact)
            rt_pivot_dly_opp,
    
            ((vw_car_rte_nbr))-
            (((cast(sum(w_hrs_ldc21+w_hrs_ldc22+w_hrs_ldc26+w_hrs_ldc29) as decimal(18,2)) /#client.avar_adhocdeldays#)/8)
            *prod_fters_fact)
            rt_pivot_perf_dly_act
    
            from var_calc_cdv with (nolock), var_base with (nolock), var_weekly with (nolock),
                #application.dsn2#.dbo.avar_cdv_prod with (nolock), mpoo_nbr_rts_vw with (nolock)
            where b_cluster='#b_cluster#' and b_mpoo<>'x' and b_collection_unit_ind=0
            and b_fin_nbr = calc_fin_nbr and b_fin_nbr = w_fin_nbr
            and b_mpoo=vw_mpoo and b_cluster=vw_cluster
            and calc_fy=w_fy and calc_wk=w_wk and b_cdv_ind=1 and b_pce_ind=1 and b_dois_ind=1 
            and cast(w_fy as char(4))+cast(w_wk as varchar(2)) in (#client.avar_oppweeks#)
            group by b_mpoo,b_lead_name,prod_fters_fact,vw_car_rte_nbr, b_area_name, b_cluster, b_cluster_name;
        </cfquery>
    <cfelse>
        <cfquery name="getOpp" datasource="#application.dsn#">
            declare 
             @testString varchar(4000) = '#client.avar_oppWeeks#'
            ,@minFyWk int
            ,@maxFyWk int
            ,@cntFyWk int
            ,@delDays int
            ,@cluster varchar(16);
            
             set @cluster = '#b_cluster#';
             set @delDays = #client.avar_adHocDelDays#;
    
             if object_id('tempdb..##fyWks2') is not null begin drop table ##fyWks2 end;
    
             create table ##fyWks2(fy int, wk int, fyWk int);
             insert into ##fyWks2(fy,wk,fyWk) select left(sp_weeks,4), right(sp_weeks,len(sp_weeks)-4) * 1 wk , left(sp_weeks,4)*100 + right(sp_weeks,len(sp_weeks)-4)
             from dbo.fnSplitter(@testString);
             --select * from ##fyWks2;
    
             set @cntFyWk = (select count(*) from ##fyWks2);
    
            SELECT 
               b_mpoo,
               b_cluster_name,
               calc_del_days,
               car_rte_nbr AS b_car_rte_nbr,
               car_rte_nbr - part_rt_pivot_dly_opp AS rt_pivot_dly_opp,   
               car_rte_nbr- part_rt_pivot_perf_dly_act AS rt_pivot_perf_dly_act,
               ern_rt_equiv_workload,
               act_rt_equiv_workload
            from (
                    SELECT 
                        b_mpoo
                      , replace(b_cluster_name, ' DISTRICT', '') b_cluster_name
                      , @delDays calc_del_days
                        
                      , SUM(vb.b_hrs_ldc21 
                            + vb.b_hrs_ldc22 
                            + vb.b_hrs_ldc29 
                            + CAST(vb.b_car_rte_nbr AS DECIMAL(18, 2))* 4 / dbo.var_annual.ann_del_days 
                             )
                            / (8 * @cntFyWk) AS car_rte_nbr
    
                        --((vw_car_rte_nbr))-
                      , CAST(SUM((cd_ern_hrs_ldc21+cd_ern_hrs_ldc22+cd_ern_hrs_ldc26)* prod_fters_fact/(@delDays*8)) AS DECIMAL(18,2))
                        part_rt_pivot_dly_opp             
                    
                        --((vw_car_rte_nbr))-
                      , CAST( SUM((w_hrs_ldc21+w_hrs_ldc22+w_hrs_ldc26+w_hrs_ldc29)*prod_fters_fact/(@delDays*8))
                           AS DECIMAL(18,2))
                    
                        part_rt_pivot_perf_dly_act
                    
                      , sum((cd_ern_hrs_ldc21+cd_ern_hrs_ldc22+cd_ern_hrs_ldc26) * prod_fters_fact  /(@delDays * 8)) 
                        ern_rt_equiv_workload
                        
                      , CAST(SUM((w_hrs_ldc21+w_hrs_ldc22+w_hrs_ldc26+w_hrs_ldc29)* prod_fters_fact/(@delDays*8))AS DECIMAL(18,2))
                        act_rt_equiv_workload
                    
                    from (var_base vb with (nolock)
    
                         INNER JOIN var_calc_cdv vcc with (nolock) 
                             ON vcc.calc_fin_nbr = vb.b_fin_nbr
    
                             and vb.b_cluster=@cluster
                             and vb.b_mpoo<>'X'
                             and vb.b_collection_unit_ind=0
                             and vb.b_cdv_ind =1 -- and b_dois_ind=1
                           )
                         INNER JOIN ##fyWks2 yw
                             on   yw.fy= vcc.calc_fy 
                             and  yw.wk= vcc.calc_wk 
    
                         INNER JOIN var_weekly vw with (nolock)
                             ON  vb.b_fin_nbr = vw.w_fin_nbr
                             and vcc.calc_fy = vw.w_fy
                             and vcc.calc_wk = vw.w_wk
    
                        CROSS JOIN PCDV_delpVar.dbo.avar_cdv_prod with (nolock)
                        CROSS JOIN  dbo.var_annual WITH (NOLOCK)
    
                    group by b_mpoo, b_cluster_name
            )q1;
      
        </cfquery>
    </cfif>
    <cfquery name="totals" dbtype="query">
        select sum(b_car_rte_nbr) b_car_rte_nbr,
            sum(ern_rt_equiv_workload) as ern_rt_equiv_workload,
            sum(act_rt_equiv_workload) as act_rt_equiv_workload,
            sum(rt_pivot_dly_opp) as rt_pivot_dly_opp,
            sum(rt_pivot_perf_dly_act) as rt_pivot_perf_dly_act,
            sum(rt_pivot_perf_dly_act)/sum(rt_pivot_dly_opp) as pivot_opp_pct_ach
        from getOpp
    </cfquery>
    <cfif totals.pivot_opp_pct_ach LT 0>
        <cfset totals.pivot_opp_pct_ach = 0>
    <cfelseif totals.pivot_opp_pct_ach GT 100>
        <cfset totals.pivot_opp_pct_ach = 100>
    </cfif>

    <!--- ******************************************************************************************* --->
    <!---                                   Write Data to Table                                       --->
    <!--- ******************************************************************************************* --->

    <form name="form1" method="post">
        <table width="100%" border="2" summary="This table provides an analysis of Delivery Unit's Pivot Opportunity" cellpadding="1" cellspacing="0" border="0" align="center">
            <tr>
                <td colspan="3" bgcolor="#003263">
                    <font face="verdana,arial,helvetica" color="#ffffff" size="2"><b>Return to -->&nbsp;&nbsp;<a href="avar_pivot.cfm" title="Link to Return to Pivot Summary Range Selection" class="alink">Range Selection</a>&nbsp;&nbsp; -->
                    <cfoutput>
                    <a href="avar_pivot2.cfm?viewLevel=N&isPces=#pcesFormVal#" title="Link to National Level" class="alink">National Level</a>&nbsp;&nbsp;-->
                    <a href="avar_pivot2.cfm?viewLevel=C&b_cluster=#b_cluster#&b_area=#b_area#&isPces=#pcesFormVal#" title="Link to Cluster Level" class="alink" >Cluster Level</a>&nbsp;&nbsp;
                    </cfoutput>
                    </b></font>
                </td>
            </tr>
            <tr>
            <td bgcolor="003263" height="25" align="center" colspan="3">
            <font face="verdana,arial,helvetica" color="ffffff" size="2"><b>
                <cfoutput>
                    <cfsavecontent variable="cluster">#pcesText#<CF_WAD_Capitalize TitleCase="yes">#getOpp.b_cluster_name[1]#</CF_WAD_Capitalize></cfsavecontent>
                    <cfset cluster = replace(cluster,"Pfc","PFC","ALL")>
                    #cluster# City Delivery Pivot Opportunity Model #client.avar_adHocDelDays# Delivery Days &nbsp;&nbsp;#dateformat(client.avar_wk_beg_dte,"mm/dd/yyyy")#&nbsp;&nbsp;to&nbsp;&nbsp;#dateformat(client.avar_wk_end_dte,"mm/dd/yyyy")#
                </cfoutput>
            </b></font>
            </td>
            </tr>
            <tr bgcolor="#003263">
                <cfoutput>
                    <cfset basRteMsg="<b>Number of base routes</b><br>#NumberFormat(totals.b_car_rte_nbr,"___,___,___,___")#">
                    <cfset ernRteMsg="<b>Earned routes equivalent workload</b><br>#NumberFormat(totals.ern_rt_equiv_workload,"___,___,___,___")#">
                    <cfset actRteMsg="<b>Actual routes equivalent workload</b><br>#NumberFormat(totals.act_rt_equiv_workload,"___,___,___,___")#">

                     <td width="33%" <cfif client.pivotHelpPrompt EQ 1>style="text-align: left; cursor:help" ONMOUSEOVER="ddrivetip('#basRteMsg#','DFDFFF', 250)"; ONMOUSEOUT="hideddrivetip()"</cfif>><font face="Verdana" size="1" color="##FFFFFF"><b>&nbsp;
                       Base number of Equivalent City Routes:&nbsp;#NumberFormat(totals.b_car_rte_nbr,"___,___,___,___")#</b></font></td>
                     <td width="33%" <cfif client.pivotHelpPrompt EQ 1>style="text-align: left; cursor:help" ONMOUSEOVER="ddrivetip('#ernRteMsg#','DFDFFF', 250)"; ONMOUSEOUT="hideddrivetip()"</cfif>><font face="Verdana" size="1" color="##FFFFFF"><b>&nbsp;
                       Earned Rts Equivalent Workload:&nbsp;#NumberFormat(totals.ern_rt_equiv_workload,"___,___,___,___")#</b></font></td>
                     <td width="33%" <cfif client.pivotHelpPrompt EQ 1>style="text-align: left; cursor:help" ONMOUSEOVER="ddrivetip('#actRteMsg#','DFDFFF', 250)"; ONMOUSEOUT="hideddrivetip()"</cfif>><font face="Verdana" size="1" color="##FFFFFF"><b>&nbsp;
                       Actual Rts Equivalent Workhours:&nbsp;#NumberFormat(totals.act_rt_equiv_workload,"___,___,___,___")#</b></font></td>
                 </cfoutput>
            </tr>
            <tr bgcolor="#003263">
                <cfoutput>
                    <cfset pivPlnMsg="<b>Route Pivot Opportunity Plan</b><br>Daily pivot opportunity = #NumberFormat(totals.rt_pivot_dly_opp,"___,___,___,___")# routes.">
                    <cfset pivActMsg="<b>Route Pivot Performance Actual</b><br>Daily pivot captured = #NumberFormat(totals.rt_pivot_perf_dly_act,"___,___,___,___")# routes.<br>Opportunity lost: = #NumberFormat(totals.rt_pivot_dly_opp-totals.rt_pivot_perf_dly_act,"___,___,___,___")#<br><i>(Rte Pivot Opp Plan #NumberFormat(totals.rt_pivot_dly_opp,"___,___,___,___")#) - (Rte Pivot Perf Act #NumberFormat(totals.rt_pivot_perf_dly_act,"___,___,___,___")#).</i>">
                    <cfset pctOppMsg="<b>Percent Opportunity Achieved</b><br>#DecimalFormat(totals.pivot_opp_pct_ach*100)#% of pivoting opportunity captured.">
                     <td width="33%" <cfif client.pivotHelpPrompt EQ 1>style="text-align: left; cursor:help" ONMOUSEOVER="ddrivetip('#pivPlnMsg#','DFDFFF', 250)"; ONMOUSEOUT="hideddrivetip()"</cfif>><font face="Verdana" size="1" color="##FFFFFF"><b>&nbsp;
                       Daily Pivot Opportunity:&nbsp;#NumberFormat(totals.rt_pivot_dly_opp,"___,___,___,___")#</b></font></td>
                     <td width="33%" <cfif client.pivotHelpPrompt EQ 1>style="text-align: left; cursor:help" ONMOUSEOVER="ddrivetip('#pivActMsg#','DFDFFF', 375)"; ONMOUSEOUT="hideddrivetip()"</cfif>><font face="Verdana" size="1" color="##FFFFFF"><b>&nbsp;
                       Rts Pivot Performance Actual:&nbsp;#NumberFormat(totals.rt_pivot_perf_dly_act,"___,___,___,___")#</b></font></td>
                     <td width="33%" <cfif client.pivotHelpPrompt EQ 1>style="text-align: left; cursor:help" ONMOUSEOVER="ddrivetip('#pctOppMsg#','DFDFFF', 250)"; ONMOUSEOUT="hideddrivetip()"</cfif>><font face="Verdana" size="1" color="##FFFFFF"><b>&nbsp;
                     Pivot Opportunity Percent Achieved:&nbsp;#IIF(totals.pivot_opp_pct_ach GT 1,DE('100'),DE(NumberFormat(totals.pivot_opp_pct_ach*100,'999')))#</b></font></td>
                </cfoutput>
            </tr>

            <tr>
            <td bgcolor="003263" colspan="3">
                <table border="0" width="100%" cellspacing="0" border="0" cellpadding="1">
                <tr>
                    <td colspan="2" bgcolor="FFFFFF" height="20">
                        <table cellpadding="0" width="100%" cellspacing="0" class="generique style-alternative;sortable-onload-8-reverse;" style="font-size:11px">
                          <thead>
                                  <TR>
                                      <th align="center" width="25" valign="bottom">Chart</th>
                                    <th class="sortable" align="center" width="50" valign="bottom">Mpoo</th>
                                    <!--- <th class="sortable" align="center" width="150" valign="bottom">Cluster Name</th> --->
                                    <th class="sortable-currency" align="center" width="100" valign="bottom">Base Nbr of Equivalent City Rts</th>
                                    <th class="sortable-currency" align="center" width="100" valign="bottom">Earned Rts Equivalent Workload</th>
                                    <th class="sortable-currency" align="center" width="100" valign="bottom">Actual Rts Equivalent Workhours</th>
                                    <th class="sortable-currency" align="center" width="100" valign="bottom">Daily Pivot Opportunity</th>
                                    <th class="sortable-currency" align="center" width="100" valign="bottom">Rts Pivot Performance Actual</th>
                                    <th class="sortable-currency" align="center" width="100" valign="bottom">Pivot Opportunity % Achieved</th>
                                </TR>
                            </thead>
                            <tbody>
                                <cfoutput query="getOpp">
                                    <cfset ubasRteMsg="<b>Number of base routes</b><br>#NumberFormat(b_car_rte_nbr,'999,999.00')#">
                                    <cfset uernRteMsg="<b>Earned routes equivalent workload</b><br>#DecimalFormat(ern_rt_equiv_workload)#">
                                    <cfset uactRteMsg="<b>Actual routes equivalent workload</b><br>#DecimalFormat(act_rt_equiv_workload)#">
                                    <cfset upivPlnMsg="<b>Route Pivot Opportunity Plan</b><br>Daily pivot opportunity = #DecimalFormat(rt_pivot_dly_opp)# routes.">
                                    <cfif rt_pivot_perf_dly_act LT 0><cfset ActMsgMinus="<br><font color=FF0000>MPOO #b_mpoo# ran #DecimalFormat(ABS(rt_pivot_perf_dly_act))# daily equivalent routes over the base routes.</font>"><cfelse><cfset ActMsgMinus=""></cfif>
                                    <cfset upivActMsg="<b>Route Pivot Performance Actual</b><br>Daily pivot captured = #DecimalFormat(rt_pivot_perf_dly_act)# routes.<br>Opportunity lost: = #DecimalFormat(rt_pivot_dly_opp-rt_pivot_perf_dly_act)#<br><i>(Rte Pivot Opp Plan #DecimalFormat(rt_pivot_dly_opp)#) - (Rte Pivot Perf Act #DecimalFormat(rt_pivot_perf_dly_act)#)#ActMsgMinus#</i>">
                                    <cfif rt_pivot_dly_opp LTE 0 AND rt_pivot_perf_dly_act GT 0>
                                        <cfset opp_pct_ach=1>
                                    <cfelseif rt_pivot_perf_dly_act LTE 0 AND rt_pivot_dly_opp LTE 0>
                                        <cfset opp_pct_ach=0>
                                    <cfelseif rt_pivot_dly_opp GT 0 AND rt_pivot_perf_dly_act LT 0>
                                        <cfset opp_pct_ach=0>
                                    <cfelse>
                                        <cfset opp_pct_ach=#rt_pivot_perf_dly_act#/#rt_pivot_dly_opp#>
                                        <cfif opp_pct_ach GTE 1>
                                            <cfset opp_pct_ach=1>
                                        </cfif>
                                    </cfif>
                                    <cfset upctOppMsg="<b>Percent Opportunity Achieved</b><br>#DecimalFormat(opp_pct_ach*100)#% of pivoting opportunity captured.">

                                    <tr>
                                        <td align="center" width="25" valign="bottom"><a href="pivot/pivot_main.cfm?area_no=#b_area#&cluster_no=#b_cluster#&mpoo_no=#b_mpoo#&scope=M&do=3&cftrk=1&isPces=#pcesFormVal#" title="Link to MPOO Level Pivot Chart" target="_blank"><img src="/images/avar_graph.gif" width="14" height="15" id="Chart Image"></a></td>
                                        <td align="center" width="50" valign="bottom" style="text-align:left;">
                                            <a href="avar_pivot2.cfm?viewLevel=U&b_cluster=#b_cluster#&b_mpoo=#b_mpoo#&b_area=#b_area#&isPces=#pcesFormVal#" title="Link to MPOO Level Report">MPOO #b_mpoo#</a>
                                        </td>
                                        <!--- <td align="center" width="150" valign="bottom">#b_cluster_name#</td> --->
                                        <td align="center" width="95" valign="bottom" <cfif client.pivotHelpPrompt EQ 1>style="text-align: center; cursor:help" ONMOUSEOVER="ddrivetip('#ubasRteMsg#','DFDFFF', 250)"; ONMOUSEOUT="hideddrivetip()"</cfif>>#NumberFormat(b_car_rte_nbr,'999,999.00')#</td>
                                            <td align="center" width="95" valign="bottom" <cfif client.pivotHelpPrompt EQ 1>style="text-align: center; cursor:help" ONMOUSEOVER="ddrivetip('#uernRteMsg#','DFDFFF', 250)"; ONMOUSEOUT="hideddrivetip()"</cfif>>#DecimalFormat(ern_rt_equiv_workload)#</td>
                                            <td align="center" width="95" valign="bottom" <cfif client.pivotHelpPrompt EQ 1>style="text-align: center; cursor:help" ONMOUSEOVER="ddrivetip('#uactRteMsg#','DFDFFF', 250)"; ONMOUSEOUT="hideddrivetip()"</cfif>>#DecimalFormat(act_rt_equiv_workload)#</td>
                                            <td align="center" width="95" bgcolor="#dailyOppColor#" valign="bottom" <cfif client.pivotHelpPrompt EQ 1>style="text-align: center; cursor:help" ONMOUSEOVER="ddrivetip('#upivPlnMsg#','DFDFFF', 250)"; ONMOUSEOUT="hideddrivetip()"</cfif>>#DecimalFormat(rt_pivot_dly_opp)#</td>
                                            <td align="center" width="95" valign="bottom" <cfif client.pivotHelpPrompt EQ 1>style="text-align: center; cursor:help" ONMOUSEOVER="ddrivetip('#upivActMsg#','DFDFFF', 375)"; ONMOUSEOUT="hideddrivetip()"</cfif>>#DecimalFormat(rt_pivot_perf_dly_act)#</td>
                                            <cfsilent>
                                                <cfset pachbgcolor=arrColor[arrLen].color>
                                                <cfloop index="i" from="#arrLen#" to="1" step="-1">
                                                    <cfif arrColor[i].limit GTE opp_pct_ach>
                                                        <cfset pachbgcolor=arrColor[i].color>
                                                    </cfif>
                                                </cfloop>
                                            </cfsilent>
                                            <td align="center" width="100" valign="bottom" <cfif client.pivotHelpPrompt EQ 1>style="text-align: center; cursor:help" ONMOUSEOVER="ddrivetip('#upctOppMsg#','DFDFFF', 250)"; ONMOUSEOUT="hideddrivetip()"</cfif> bgcolor="#pachbgcolor#">#DecimalFormat(opp_pct_ach*100)#</td>
                                        </tr>
                                </cfoutput>
                            </tbody>
                        </table>

                    </td>
                </tr>

                </table>


            </td>
            </tr>
            <tr>
                <td align="center" width="100%" colspan="4">
                    <table border="0" cellspacing="0" width="100%" height="44" align="center">
                          <tr align="center" valign="middle">
                             <td width="100%" height="44" bgcolor="#F8F8FF" valign="middle" align="center" valign="middle">
                                <cfoutput><a href="avar_pivot_xls.cfm?viewLevel=M&b_cluster=#b_cluster#" title="Download City Delivery Pivot Opportunity to Excel"><img src="/images/avar_send2excel.gif" width="80" height="15" alt="Download City Delivery Pivot Opportunity to Excel" border="0"></a></cfoutput>
                             </td>
                        </tr>
                    </table>
                </td>
            </tr>

            </table>
        </form>
    </cfif>
    <!--- Unit Level ********************************************************************************************************************** --->
    <cfif viewLevel EQ "U">
    	
    	<cfquery name="getOpp" datasource="#application.dsn#">
            SELECT b_fin_name,b_fin_nbr,#client.avar_adHocDelDays# calc_del_days,(vw_car_rte_nbr) b_car_rte_nbr,
                replace(b_cluster_name, ' DISTRICT', '') b_cluster_name,
        
                ((sum(cd_ern_hrs_ldc21+cd_ern_hrs_ldc22+cd_ern_hrs_ldc26)/
                #client.avar_adHocDelDays#)/8)*prod_fters_fact
                ern_rt_equiv_workload,
        
                (((CAST(SUM(w_hrs_ldc21+w_hrs_ldc22+w_hrs_ldc26+w_hrs_ldc29) AS DECIMAL(18,2)) /#client.avar_adHocDelDays#)/8)
                *prod_fters_fact)
                act_rt_equiv_workload,
        
                ((vw_car_rte_nbr))-
                (((CAST(SUM(cd_ern_hrs_ldc21+cd_ern_hrs_ldc22+cd_ern_hrs_ldc26) AS DECIMAL(18,2)) /#client.avar_adHocDelDays#)/8)
                *prod_fters_fact)
                rt_pivot_dly_opp,
        
                ((vw_car_rte_nbr))-
                (((CAST(SUM(w_hrs_ldc21+w_hrs_ldc22+w_hrs_ldc26+w_hrs_ldc29) AS DECIMAL(18,2)) /#client.avar_adHocDelDays#)/8)
                *prod_fters_fact)
                rt_pivot_perf_dly_act
    
            from var_calc_cdv with (nolock), var_base with (nolock), var_weekly with (nolock),
                #application.dsn2#.dbo.avar_cdv_prod with (nolock), unit_nbr_rts_vw with (nolock)
            where b_cluster='#b_cluster#' 
            and b_mpoo='#b_mpoo#' #pcesDbFlag# 
            and b_collection_unit_ind=0
            and b_fin_nbr = calc_fin_nbr 
            and b_fin_nbr = w_fin_nbr 
            and b_fin_nbr=vw_fin_nbr
            and calc_fy=w_fy 
            and calc_wk=w_wk 
            and b_cdv_ind = 1
            and CAST(w_fy AS CHAR(4))+CAST(w_wk as VARCHAR(2)) IN (#client.avar_oppWeeks#)
            group by b_fin_name,b_fin_nbr,prod_fters_fact,vw_car_rte_nbr, b_cluster_name
            <cfif isPcesRequest>
            having cast(vw_car_rte_nbr as decimal(18, 0)) > 0; /* attempt to stop district/other non-CDV offices from being included in PCES output */
            </cfif>
        </cfquery>

        <cfquery name="totals" dbtype="query">
            select sum(b_car_rte_nbr) b_car_rte_nbr,
                sum(ern_rt_equiv_workload) as ern_rt_equiv_workload,
                sum(act_rt_equiv_workload) as act_rt_equiv_workload,
                sum(rt_pivot_dly_opp) as rt_pivot_dly_opp,
                sum(rt_pivot_perf_dly_act) as rt_pivot_perf_dly_act,
                sum(rt_pivot_perf_dly_act)/sum(rt_pivot_dly_opp) as pivot_opp_pct_ach
            from getOpp
        </cfquery>
        <cfif totals.pivot_opp_pct_ach LT 0>
            <cfset totals.pivot_opp_pct_ach = 0>
        <cfelseif totals.pivot_opp_pct_ach GT 100>
            <cfset totals.pivot_opp_pct_ach = 100>
        </cfif>

        <!--- ******************************************************************************************* --->
        <!---                                   Write Data to Table                                       --->
        <!--- ******************************************************************************************* --->

        <form name="form1" method="post">
            <table width="100%" border="2" summary="This table provides an analysis of Delivery Unit's Pivot Opportunity" cellpadding="1" cellspacing="0" border="0" align="center">
                <tr>
                    <td colspan="3" bgcolor="#003263">
                        <font face="verdana,arial,helvetica" color="#ffffff" size="2"><b>Return to -->&nbsp;&nbsp;<a href="avar_pivot.cfm" title="Link to Return to Pivot Summary Range Selection" class="alink">Range Selection</a>&nbsp;&nbsp; -->
                        <cfoutput>
                        <a href="avar_pivot2.cfm?viewLevel=N&isPces=#pcesFormVal#" title="Link to National Level" class="alink">National Level</a>&nbsp;&nbsp;-->                        
                        <a href="avar_pivot2.cfm?viewLevel=C&b_cluster=#b_cluster#&isPces=#pcesFormVal#" title="Link to Cluster Level" class="alink">Cluster Level</a>&nbsp;&nbsp;-->
                        <a href="avar_pivot2.cfm?viewLevel=M&b_cluster=#b_cluster#&b_mpoo=#b_mpoo#&isPces=#pcesFormVal#" title="Link to MPOO Level" class="alink">MPOO Level</a>&nbsp;&nbsp;
                        </cfoutput>
                        </b></font>
                    </td>
                </tr>
                <tr>
                <td bgcolor="003263" height="25" align="center" colspan="3">
                <font face="verdana,arial,helvetica" color="ffffff" size="2"><b>
                <cfoutput>
                    <cfsavecontent variable="cluster">#pcesText#<CF_WAD_Capitalize TitleCase="yes">#getOpp.b_cluster_name[1]#</CF_WAD_Capitalize></cfsavecontent>
                    <cfset cluster = replace(cluster,"Pfc","PFC","ALL")>
                    #cluster# - MPOO <CF_WAD_Capitalize TitleCase="yes">#b_mpoo#</CF_WAD_Capitalize> City Delivery Pivot Opportunity Model #client.avar_adHocDelDays# Delivery Days &nbsp;&nbsp;#dateformat(client.avar_wk_beg_dte,"mm/dd/yyyy")#&nbsp;&nbsp;to&nbsp;&nbsp;#dateformat(client.avar_wk_end_dte,"mm/dd/yyyy")#
                </cfoutput>
                </b></font>
                </td>
                </tr>
                <tr bgcolor="#003263">
                <cfoutput>
                    <cfset basRteMsg="<b>Number of base routes</b><br>#NumberFormat(totals.b_car_rte_nbr,"___,___,___,___")#">
                    <cfset ernRteMsg="<b>Earned routes equivalent workload</b><br>#NumberFormat(totals.ern_rt_equiv_workload,"___,___,___,___")#">
                    <cfset actRteMsg="<b>Actual routes equivalent workload</b><br>#NumberFormat(totals.act_rt_equiv_workload,"___,___,___,___")#">

                     <td width="33%" <cfif client.pivotHelpPrompt EQ 1>style="text-align: left; cursor:help" ONMOUSEOVER="ddrivetip('#basRteMsg#','DFDFFF', 250)"; ONMOUSEOUT="hideddrivetip()"</cfif>><font face="Verdana" size="1" color="##FFFFFF"><b>&nbsp;
                       Base number of Equivalent City Routes:&nbsp;#NumberFormat(totals.b_car_rte_nbr,"___,___,___,___")#</b></font></td>
                     <td width="33%" <cfif client.pivotHelpPrompt EQ 1>style="text-align: left; cursor:help" ONMOUSEOVER="ddrivetip('#ernRteMsg#','DFDFFF', 250)"; ONMOUSEOUT="hideddrivetip()"</cfif>><font face="Verdana" size="1" color="##FFFFFF"><b>&nbsp;
                       Earned Rts Equivalent Workload:&nbsp;#NumberFormat(totals.ern_rt_equiv_workload,"___,___,___,___")#</b></font></td>
                     <td width="33%" <cfif client.pivotHelpPrompt EQ 1>style="text-align: left; cursor:help" ONMOUSEOVER="ddrivetip('#actRteMsg#','DFDFFF', 250)"; ONMOUSEOUT="hideddrivetip()"</cfif>><font face="Verdana" size="1" color="##FFFFFF"><b>&nbsp;
                       Actual Rts Equivalent Workhours:&nbsp;#NumberFormat(totals.act_rt_equiv_workload,"___,___,___,___")#</b></font></td>
                 </cfoutput>
            </tr>
            <tr bgcolor="#003263">
                <cfoutput>
                    <cfset pivPlnMsg="<b>Route Pivot Opportunity Plan</b><br>Daily pivot opportunity = #NumberFormat(totals.rt_pivot_dly_opp,"___,___,___,___")# routes.">
                    <cfset pivActMsg="<b>Route Pivot Performance Actual</b><br>Daily pivot captured = #NumberFormat(totals.rt_pivot_perf_dly_act,"___,___,___,___")# routes.<br>Opportunity lost: = #NumberFormat(totals.rt_pivot_dly_opp-totals.rt_pivot_perf_dly_act,"___,___,___,___")#<br><i>(Rte Pivot Opp Plan #NumberFormat(totals.rt_pivot_dly_opp,"___,___,___,___")#) - (Rte Pivot Perf Act #NumberFormat(totals.rt_pivot_perf_dly_act,"___,___,___,___")#).</i>">
                    <cfset pctOppMsg="<b>Percent Opportunity Achieved</b><br>#DecimalFormat(totals.pivot_opp_pct_ach*100)#% of pivoting opportunity captured.">
                     <td width="33%" <cfif client.pivotHelpPrompt EQ 1>style="text-align: left; cursor:help" ONMOUSEOVER="ddrivetip('#pivPlnMsg#','DFDFFF', 250)"; ONMOUSEOUT="hideddrivetip()"</cfif>><font face="Verdana" size="1" color="##FFFFFF"><b>&nbsp;
                       Daily Pivot Opportunity:&nbsp;#NumberFormat(totals.rt_pivot_dly_opp,"___,___,___,___")#</b></font></td>
                     <td width="33%" <cfif client.pivotHelpPrompt EQ 1>style="text-align: left; cursor:help" ONMOUSEOVER="ddrivetip('#pivActMsg#','DFDFFF', 375)"; ONMOUSEOUT="hideddrivetip()"</cfif>><font face="Verdana" size="1" color="##FFFFFF"><b>&nbsp;
                       Rts Pivot Performance Actual:&nbsp;#NumberFormat(totals.rt_pivot_perf_dly_act,"___,___,___,___")#</b></font></td>
                     <td width="33%" <cfif client.pivotHelpPrompt EQ 1>style="text-align: left; cursor:help" ONMOUSEOVER="ddrivetip('#pctOppMsg#','DFDFFF', 250)"; ONMOUSEOUT="hideddrivetip()"</cfif>><font face="Verdana" size="1" color="##FFFFFF"><b>&nbsp;
                     Pivot Opportunity Percent Achieved:&nbsp;#IIF(totals.pivot_opp_pct_ach GT 1,DE('100'),DE(NumberFormat(totals.pivot_opp_pct_ach*100,'999')))#</b></font></td>
                </cfoutput>
            </tr>

                <tr>
                <td bgcolor="003263" colspan="3">
                    <table border="0" width="100%" cellspacing="0" border="0" cellpadding="1">
                    <tr>
                        <td colspan="2" bgcolor="FFFFFF" height="20">
                            <table cellpadding="0" width="100%" cellspacing="0" class="generique style-alternative;sortable-onload-9-reverse;" style="font-size:11px">
                              <thead>
                                      <TR>
                                          <th align="center" width="25" valign="bottom">Chart</th>
                                        <th class="sortable" align="center" width="50" valign="bottom">Fin Nbr</th>
                                        <th class="sortable" align="center" width="180" valign="bottom">Unit Name</th>
                                        <th class="sortable-currency" align="center" width="95" valign="bottom">Base Nbr of Equivalent City Rts</th>
                                        <th class="sortable-currency" align="center" width="95" valign="bottom">Earned Rts Equivalent Workload</th>
                                        <th class="sortable-currency" align="center" width="95" valign="bottom">Actual Rts Equivalent Workhours</th>
                                        <th class="sortable-currency" align="center" width="95" valign="bottom">Daily Pivot Opportunity</th>
                                        <th class="sortable-currency" align="center" width="95" valign="bottom">Rts Pivot Performance Actual</th>
                                        <th class="sortable-currency" align="center" width="95" valign="bottom">Pivot Opportunity % Achieved</th>
                                    </TR>
                                </thead>
                                <tbody>
                                    <cfoutput query="getOpp">
                                        <cfset ubasRteMsg="<b>Number of base routes</b><br>#NumberFormat(b_car_rte_nbr,'999,999.00')#">
                                        <cfset uernRteMsg="<b>Earned routes equivalent workload</b><br>#DecimalFormat(ern_rt_equiv_workload)#">
                                        <cfset uactRteMsg="<b>Actual routes equivalent workload</b><br>#DecimalFormat(act_rt_equiv_workload)#">
                                        <cfset upivPlnMsg="<b>Route Pivot Opportunity Plan</b><br>Daily pivot opportunity = #DecimalFormat(rt_pivot_dly_opp)# routes.">
                                        <cfif rt_pivot_perf_dly_act LT 0><cfset ActMsgMinus="<br><font color=FF0000>#b_fin_name# ran #DecimalFormat(ABS(rt_pivot_perf_dly_act))# daily equivalent routes over the base routes.</font>"><cfelse><cfset ActMsgMinus=""></cfif>
                                        <cfset upivActMsg="<b>Route Pivot Performance Actual</b><br>Daily pivot captured = #DecimalFormat(rt_pivot_perf_dly_act)# routes.<br>Opportunity lost: = #DecimalFormat(rt_pivot_dly_opp-rt_pivot_perf_dly_act)#<br><i>(Rte Pivot Opp Plan #DecimalFormat(rt_pivot_dly_opp)#) - (Rte Pivot Perf Act #DecimalFormat(rt_pivot_perf_dly_act)#)#ActMsgMinus#</i>">
                                        <cfif rt_pivot_dly_opp LTE 0 AND rt_pivot_perf_dly_act GT 0>
                                            <cfset opp_pct_ach=1>
                                        <cfelseif rt_pivot_perf_dly_act LTE 0 AND rt_pivot_dly_opp LTE 0>
                                            <cfset opp_pct_ach=0>
                                        <cfelseif rt_pivot_dly_opp GT 0 AND rt_pivot_perf_dly_act LT 0>
                                            <cfset opp_pct_ach=0>
                                        <cfelse>
                                            <cfset opp_pct_ach=#rt_pivot_perf_dly_act#/#rt_pivot_dly_opp#>
                                            <cfif opp_pct_ach GTE 1>
                                                <cfset opp_pct_ach=1>
                                            </cfif>
                                        </cfif>
                                        <cfset upctOppMsg="<b>Percent Opportunity Achieved</b><br>#DecimalFormat(opp_pct_ach*100)#% of pivoting opportunity captured.">

                                        <tr>
                                            <td align="center" width="25" valign="bottom"><a href="pivot/pivot_main.cfm?area_no=#b_area#&cluster_no=#b_cluster#&mpoo_no=#b_mpoo#&fin_no=#b_fin_nbr#&fin_name=#b_fin_name#&scope=U&do=4&cftrk=1&isPces=#pcesFormVal#" title="Link to Unit Level Pivot Chart" target="_blank"><img src="/images/avar_graph.gif" width="14" height="15" id="Chart Image"></a></td>
                                            <td align="center" width="50" valign="bottom">#b_fin_nbr#</td>
                                            <td align="left" width="180" valign="bottom" nowrap style="text-align:left;">&nbsp;#b_fin_name#</td>
                                            <td align="center" width="95" valign="bottom" <cfif client.pivotHelpPrompt EQ 1>style="text-align: center; cursor:help" ONMOUSEOVER="ddrivetip('#ubasRteMsg#','DFDFFF', 250)"; ONMOUSEOUT="hideddrivetip()"</cfif>>#NumberFormat(b_car_rte_nbr,'999,999.00')#</td>
                                            <td align="center" width="95" valign="bottom" <cfif client.pivotHelpPrompt EQ 1>style="text-align: center; cursor:help" ONMOUSEOVER="ddrivetip('#uernRteMsg#','DFDFFF', 250)"; ONMOUSEOUT="hideddrivetip()"</cfif>>#DecimalFormat(ern_rt_equiv_workload)#</td>
                                            <td align="center" width="95" valign="bottom" <cfif client.pivotHelpPrompt EQ 1>style="text-align: center; cursor:help" ONMOUSEOVER="ddrivetip('#uactRteMsg#','DFDFFF', 250)"; ONMOUSEOUT="hideddrivetip()"</cfif>>#DecimalFormat(act_rt_equiv_workload)#</td>
                                            <td align="center" width="95" bgcolor="#dailyOppColor#" valign="bottom" <cfif client.pivotHelpPrompt EQ 1>style="text-align: center; cursor:help" ONMOUSEOVER="ddrivetip('#upivPlnMsg#','DFDFFF', 250)"; ONMOUSEOUT="hideddrivetip()"</cfif>>#DecimalFormat(rt_pivot_dly_opp)#</td>
                                            <td align="center" width="95" valign="bottom" <cfif client.pivotHelpPrompt EQ 1>style="text-align: center; cursor:help" ONMOUSEOVER="ddrivetip('#upivActMsg#','DFDFFF', 375)"; ONMOUSEOUT="hideddrivetip()"</cfif>>#DecimalFormat(rt_pivot_perf_dly_act)#</td>
                                            <cfsilent>
                                                <cfset pachbgcolor=arrColor[arrLen].color>
                                                <cfloop index="i" from="#arrLen#" to="1" step="-1">
                                                    <cfif arrColor[i].limit GTE opp_pct_ach>
                                                        <cfset pachbgcolor=arrColor[i].color>
                                                    </cfif>
                                                </cfloop>
                                            </cfsilent>
                                            <td align="center" width="100" valign="bottom" <cfif client.pivotHelpPrompt EQ 1>style="text-align: center; cursor:help" ONMOUSEOVER="ddrivetip('#upctOppMsg#','DFDFFF', 250)"; ONMOUSEOUT="hideddrivetip()"</cfif> bgcolor="#pachbgcolor#">#DecimalFormat(opp_pct_ach*100)#</td>
                                        </tr>
                                    </cfoutput>
                                </tbody>
                            </table>

                        </td>
                    </tr>

                    </table>


                </td>
                </tr>
                <tr>
                    <td align="center" width="100%" colspan="4">
                        <table border="0" cellspacing="0" width="100%" height="44" align="center">
                              <tr align="center" valign="middle">
                                 <td width="100%" height="44" bgcolor="#F8F8FF" valign="middle" align="center" valign="middle">
                                    <cfoutput><a href="avar_pivot_xls.cfm?viewLevel=U&b_cluster=#b_cluster#&b_mpoo=#b_mpoo#" title="Download City Delivery Pivot Opportunity to Excel"><img src="/images/avar_send2excel.gif" width="80" height="15" alt="Download City Delivery Pivot Opportunity to Excel" border="0"></a></cfoutput>
                                 </td>
                            </tr>
                        </table>
                    </td>
                </tr>
                </table>
            </form>
    </cfif>
    <!--- National Cluster Level ********************************************************************************************************************** --->
    <cfif viewLevel EQ "NC">
    <cfif isPcesRequest>
    	<cfquery name="getOpp" datasource="#application.dsn#">
            SELECT b_area, b_area_name, b_cluster,replace(b_cluster_name, ' DISTRICT', '') b_cluster_name,
                b_lead_name,b_lead_fin_nbr,#client.avar_adHocDelDays# calc_del_days,(vw_car_rte_nbr) b_car_rte_nbr,
    
                ((sum(cd_ern_hrs_ldc21+cd_ern_hrs_ldc22+cd_ern_hrs_ldc26)/
                #client.avar_adHocDelDays#)/8)*prod_fters_fact
                ern_rt_equiv_workload,
    
                (((CAST(SUM(w_hrs_ldc21+w_hrs_ldc22+w_hrs_ldc26+w_hrs_ldc29) AS DECIMAL(18,2)) /#client.avar_adHocDelDays#)/8)
                *prod_fters_fact)
                act_rt_equiv_workload,
    
                ((vw_car_rte_nbr))-
                (((CAST(SUM(cd_ern_hrs_ldc21+cd_ern_hrs_ldc22+cd_ern_hrs_ldc26) AS DECIMAL(18,2)) /#client.avar_adHocDelDays#)/8)
                *prod_fters_fact)
                rt_pivot_dly_opp,
    
                ((vw_car_rte_nbr))-
                (((CAST(SUM(w_hrs_ldc21+w_hrs_ldc22+w_hrs_ldc26+w_hrs_ldc29) AS DECIMAL(18,2)) /#client.avar_adHocDelDays#)/8)
                *prod_fters_fact)
                rt_pivot_perf_dly_act
    
                from var_calc_cdv with (nolock), var_base with (nolock), var_weekly with (nolock),
                    #application.dsn2#.dbo.avar_cdv_prod with (nolock), lead_nbr_rts_vw with (nolock)
                where b_collection_unit_ind=0
                and b_lead_fin_nbr=vw_lead_fin_nbr and w_fin_nbr=calc_fin_nbr and b_fin_nbr=w_fin_nbr
                   and calc_fy=w_fy and calc_wk=w_wk and b_cdv_ind=1 and b_pce_ind=1 and b_dois_ind=1
                and CAST(w_fy AS CHAR(4))+CAST(w_wk as VARCHAR(2)) IN (#client.avar_oppWeeks#)
                group by b_area,b_area_name, b_cluster_name,b_cluster,b_lead_name,b_lead_fin_nbr,prod_fters_fact,vw_car_rte_nbr;    
        </cfquery>
    <cfelse>
        <cfquery name="getOpp" datasource="#application.dsn#">
            
            Select b_area,rtrim(ltrim(b_area_name)) b_area_name,b_cluster,replace(b_cluster_name, ' DISTRICT', '') b_cluster_name,
                #client.avar_adHocDelDays# calc_del_days, AVG(b_car_rte_nbr) b_car_rte_nbr,
                ((sum(ern_rt_equiv_workload)/#client.avar_adHocDelDays#)/8)*prod_fters_fact ern_rt_equiv_workload,
    
                (((CAST(SUM(act_rt_equiv_workload) AS DECIMAL(18,2)) /#client.avar_adHocDelDays#)/8)*prod_fters_fact)
                 act_rt_equiv_workload,
    
                AVG(b_car_rte_nbr) - (((sum(rt_pivot_dly_opp)/#client.avar_adHocDelDays#)/8)*prod_fters_fact) rt_pivot_dly_opp,
                AVG(b_car_rte_nbr) - (((sum(rt_pivot_perf_dly_act) /#client.avar_adHocDelDays#)/8)*prod_fters_fact) rt_pivot_perf_dly_act
            from var_cluster_summary#pcesSqlTable#,
            #application.dsn2#.dbo.avar_cdv_prod,area_nbr_rts_vw with (nolock)
            where b_area=vw_area AND period in (#client.lstWeeks#)
            group by b_area,b_area_name,b_cluster,b_cluster_name,prod_fters_fact;    
        </cfquery>
    </cfif>        

    <cfquery name="totals" dbtype="query">
        select sum(b_car_rte_nbr) b_car_rte_nbr,
            sum(ern_rt_equiv_workload) as ern_rt_equiv_workload,
            sum(act_rt_equiv_workload) as act_rt_equiv_workload,
            sum(rt_pivot_dly_opp) as rt_pivot_dly_opp,
            sum(rt_pivot_perf_dly_act) as rt_pivot_perf_dly_act,
            sum(rt_pivot_perf_dly_act)/sum(rt_pivot_dly_opp) as pivot_opp_pct_ach
        from getOpp
    </cfquery>
    <cfif totals.pivot_opp_pct_ach LT 0>
        <cfset totals.pivot_opp_pct_ach = 0>
    <cfelseif totals.pivot_opp_pct_ach GT 100>
        <cfset totals.pivot_opp_pct_ach = 100>
    </cfif>
    <!--- ******************************************************************************************* --->
    <!---                                   Write Data to Table                                       --->
    <!--- ******************************************************************************************* --->

    <form name="form1" method="post">
        <table width="100%" border="2" summary="This table provides an analysis of Delivery Unit's Pivot Opportunity" cellpadding="1" cellspacing="0" border="0" align="center">
            <tr>
                <td colspan="3" bgcolor="#003263">
                    <font face="verdana,arial,helvetica" color="#ffffff" size="2"><b>Return to -->&nbsp;&nbsp;<a href="avar_pivot.cfm" title="Link to Return to Pivot Summary Range Selection" class="alink">Range Selection</a>&nbsp;&nbsp; -->
                    <cfoutput>
                    <a href="avar_pivot2.cfm?viewLevel=N&isPces=#pcesFormVal#" title="Link to National Level" class="alink">National Level</a>
                    </cfoutput>
                </td>
            </tr>
            <tr>
            <td bgcolor="003263" height="25" align="center" colspan="3">
            <cfoutput>
            <font face="verdana,arial,helvetica" color="ffffff" size="2"><b>#pcesText#<CF_WAD_Capitalize TitleCase="yes">#getOpp.b_area_name[1]# Area</CF_WAD_Capitalize> City Delivery Pivot Opportunity Model #client.avar_adHocDelDays# Delivery Days &nbsp;&nbsp;#dateformat(client.avar_wk_beg_dte,"mm/dd/yyyy")#&nbsp;&nbsp;to&nbsp;&nbsp;#dateformat(client.avar_wk_end_dte,"mm/dd/yyyy")#</b></font></td>
            </cfoutput>
            </tr>
            <tr bgcolor="#003263">
                <cfoutput>
                    <cfset basRteMsg="<b>Number of base routes</b><br>#NumberFormat(totals.b_car_rte_nbr,"___,___,___,___")#">
                    <cfset ernRteMsg="<b>Earned routes equivalent workload</b><br>#NumberFormat(totals.ern_rt_equiv_workload,"___,___,___,___")#">
                    <cfset actRteMsg="<b>Actual routes equivalent workload</b><br>#NumberFormat(totals.act_rt_equiv_workload,"___,___,___,___")#">

                     <td width="33%" <cfif client.pivotHelpPrompt EQ 1>style="text-align: left; cursor:help" ONMOUSEOVER="ddrivetip('#basRteMsg#','DFDFFF', 250)"; ONMOUSEOUT="hideddrivetip()"</cfif>><font face="Verdana" size="1" color="##FFFFFF"><b>&nbsp;
                       Base number of Equivalent City Routes:&nbsp;#NumberFormat(totals.b_car_rte_nbr,"___,___,___,___")#</b></font></td>
                     <td width="33%" <cfif client.pivotHelpPrompt EQ 1>style="text-align: left; cursor:help" ONMOUSEOVER="ddrivetip('#ernRteMsg#','DFDFFF', 250)"; ONMOUSEOUT="hideddrivetip()"</cfif>><font face="Verdana" size="1" color="##FFFFFF"><b>&nbsp;
                       Earned Rts Equivalent Workload:&nbsp;#NumberFormat(totals.ern_rt_equiv_workload,"___,___,___,___")#</b></font></td>
                     <td width="33%" <cfif client.pivotHelpPrompt EQ 1>style="text-align: left; cursor:help" ONMOUSEOVER="ddrivetip('#actRteMsg#','DFDFFF', 250)"; ONMOUSEOUT="hideddrivetip()"</cfif>><font face="Verdana" size="1" color="##FFFFFF"><b>&nbsp;
                       Actual Rts Equivalent Workhours:&nbsp;#NumberFormat(totals.act_rt_equiv_workload,"___,___,___,___")#</b></font></td>
                 </cfoutput>
            </tr>
            <tr bgcolor="#003263">
                <cfoutput>
                    <cfset pivPlnMsg="<b>Route Pivot Opportunity Plan</b><br>Daily pivot opportunity = #NumberFormat(totals.rt_pivot_dly_opp,"___,___,___,___")# routes.">
                    <cfset pivActMsg="<b>Route Pivot Performance Actual</b><br>Daily pivot captured = #NumberFormat(totals.rt_pivot_perf_dly_act,"___,___,___,___")# routes.<br>Opportunity lost: = #NumberFormat(totals.rt_pivot_dly_opp-totals.rt_pivot_perf_dly_act,"___,___,___,___")#<br><i>(Rte Pivot Opp Plan #NumberFormat(totals.rt_pivot_dly_opp,"___,___,___,___")#) - (Rte Pivot Perf Act #NumberFormat(totals.rt_pivot_perf_dly_act,"___,___,___,___")#).</i>">
                    <cfset pctOppMsg="<b>Percent Opportunity Achieved</b><br>#DecimalFormat(totals.pivot_opp_pct_ach*100)#% of pivoting opportunity captured.">
                     <td width="33%" <cfif client.pivotHelpPrompt EQ 1>style="text-align: left; cursor:help" ONMOUSEOVER="ddrivetip('#pivPlnMsg#','DFDFFF', 250)"; ONMOUSEOUT="hideddrivetip()"</cfif>><font face="Verdana" size="1" color="##FFFFFF"><b>&nbsp;
                       Daily Pivot Opportunity:&nbsp;#NumberFormat(totals.rt_pivot_dly_opp,"___,___,___,___")#</b></font></td>
                     <td width="33%" <cfif client.pivotHelpPrompt EQ 1>style="text-align: left; cursor:help" ONMOUSEOVER="ddrivetip('#pivActMsg#','DFDFFF', 375)"; ONMOUSEOUT="hideddrivetip()"</cfif>><font face="Verdana" size="1" color="##FFFFFF"><b>&nbsp;
                       Rts Pivot Performance Actual:&nbsp;#NumberFormat(totals.rt_pivot_perf_dly_act,"___,___,___,___")#</b></font></td>
                     <td width="33%" <cfif client.pivotHelpPrompt EQ 1>style="text-align: left; cursor:help" ONMOUSEOVER="ddrivetip('#pctOppMsg#','DFDFFF', 250)"; ONMOUSEOUT="hideddrivetip()"</cfif>><font face="Verdana" size="1" color="##FFFFFF"><b>&nbsp;
                     Pivot Opportunity Percent Achieved:&nbsp;#IIF(totals.pivot_opp_pct_ach GT 1,DE('100'),DE(NumberFormat(totals.pivot_opp_pct_ach*100,'999')))#</b></font></td>
                </cfoutput>
            </tr>

            <tr>
            <td bgcolor="003263" colspan="3">
                <table border="0" width="100%" cellspacing="0" border="0" cellpadding="1">
                <tr>
                    <td colspan="2" bgcolor="FFFFFF" height="20">
                        <table cellpadding="0" width="100%" cellspacing="0" class="generique style-alternative;sortable-onload-10-reverse;" style="font-size:11px">
                          <thead>
                                  <TR>
                                      <th align="center" width="25" valign="bottom">Chart</th>
                                    <th class="sortable" align="center" width="95" valign="bottom">Area</th>
                                    <th class="sortable" align="center" width="50" valign="bottom">Cluster</th>
                                    <th class="sortable" align="center" width="170" valign="bottom">Cluster Name</th>
                                    <th class="sortable-currency" align="center" width="85" valign="bottom">Base Nbr of Equivalent City Rts</th>
                                    <th class="sortable-currency" align="center" width="85" valign="bottom">Earned Rts Equivalent Workload</th>
                                    <th class="sortable-currency" align="center" width="85" valign="bottom">Actual Rts Equivalent Workhours</th>
                                    <th class="sortable-currency" align="center" width="85" valign="bottom">Daily Pivot Opportunity</th>
                                    <th class="sortable-currency" align="center" width="85" valign="bottom">Rts Pivot Performance Actual</th>
                                    <th class="sortable-currency" align="center" width="85" valign="bottom">Pivot Opportunity % Achieved</th>
                                </TR>
                            </thead>
                            <tbody>
                                <cfoutput query="getOpp">
                                    <cfset ncbasRteMsg="<b>Number of base routes</b><br>#NumberFormat(b_car_rte_nbr,'999,999.00')#">
                                    <cfset ncernRteMsg="<b>Earned routes equivalent workload</b><br>#DecimalFormat(ern_rt_equiv_workload)#">
                                    <cfset ncactRteMsg="<b>Actual routes equivalent workload</b><br>#DecimalFormat(act_rt_equiv_workload)#">
                                    <cfset ncpivPlnMsg="<b>Route Pivot Opportunity Plan</b><br>Daily pivot opportunity = #DecimalFormat(rt_pivot_dly_opp)# routes.">
                                    <cfif rt_pivot_perf_dly_act LT 0><cfset ActMsgMinus="<br><font color=FF0000>#b_cluster_name# ran #DecimalFormat(ABS(rt_pivot_perf_dly_act))# daily equivalent routes over the base routes.</font>"><cfelse><cfset ActMsgMinus=""></cfif>
                                    <cfset ncpivActMsg="<b>Route Pivot Performance Actual</b><br>Daily pivot captured = #DecimalFormat(rt_pivot_perf_dly_act)# routes.<br>Opportunity lost: = #DecimalFormat(rt_pivot_dly_opp-rt_pivot_perf_dly_act)#<br><i>(Rte Pivot Opp Plan #DecimalFormat(rt_pivot_dly_opp)#) - (Rte Pivot Perf Act #DecimalFormat(rt_pivot_perf_dly_act)#)#ActMsgMinus#</i>">
                                    <cfif rt_pivot_dly_opp LTE 0 AND rt_pivot_perf_dly_act GT 0>
                                        <cfset opp_pct_ach=1>
                                    <cfelseif rt_pivot_perf_dly_act LTE 0 AND rt_pivot_dly_opp LTE 0>
                                        <cfset opp_pct_ach=0>
                                    <cfelseif rt_pivot_dly_opp GT 0 AND rt_pivot_perf_dly_act LT 0>
                                        <cfset opp_pct_ach=0>
                                    <cfelse>
                                        <cfset opp_pct_ach=#rt_pivot_perf_dly_act#/#rt_pivot_dly_opp#>
                                        <cfif opp_pct_ach GTE 1>
                                            <cfset opp_pct_ach=1>
                                        </cfif>
                                    </cfif>
                                    <cfset ncpctOppMsg="<b>Percent Opportunity Achieved</b><br>#DecimalFormat(opp_pct_ach*100)#% of pivoting opportunity captured.">

                                    <tr>
                                        <td align="center" width="25" valign="bottom"><a href="pivot/pivot_main.cfm?area_no=#getOpp.b_area#&cluster_no=#b_cluster#&scope=C&do=2&cftrk=1&isPces=#pcesFormVal#" title="Link to Cluster Level Pivot Chart" target="_blank"><img src="/images/avar_graph.gif" width="14" height="15" id="Chart Image"></a></td>
                                        <td align="center" width="95" valign="bottom" style="text-align:left;"><CF_WAD_Capitalize TitleCase="yes">#b_area_name#</CF_WAD_Capitalize></td>
                                        <td align="center" width="50" valign="bottom">
                                            <a href="avar_pivot2.cfm?viewLevel=M&b_cluster=#b_cluster#&b_cluster_name=#b_cluster_name#&b_area=#getOpp.b_area#&b_area_name=#b_area_name#&isPces=#pcesFormVal#" title="Link to Cluster Level Pivot Report">#b_cluster#</a>
                                        </td>
                                        <td align="left" width="170" valign="bottom" style="text-align:left;"><a href="avar_pivot2.cfm?viewLevel=M&b_cluster=#b_cluster#&b_cluster_name=#b_cluster_name#&b_area=#getOpp.b_area#&b_area_name=#b_area_name#&isPces=#pcesFormVal#" title="Link to Cluster Level Pivot Report">#b_cluster_name#</a></td>
                                        <td align="center" width="85" valign="bottom" <cfif client.pivotHelpPrompt EQ 1>style="text-align: center; cursor:help" ONMOUSEOVER="ddrivetip('#ncbasRteMsg#','DFDFFF', 250)"; ONMOUSEOUT="hideddrivetip()"</cfif>>#NumberFormat(b_car_rte_nbr,'999,999.00')#</td>
                                        <td align="center" width="85" valign="bottom" <cfif client.pivotHelpPrompt EQ 1>style="text-align: center; cursor:help" ONMOUSEOVER="ddrivetip('#ncernRteMsg#','DFDFFF', 250)"; ONMOUSEOUT="hideddrivetip()"</cfif>>#DecimalFormat(ern_rt_equiv_workload)#</td>
                                        <td align="center" width="85" valign="bottom" <cfif client.pivotHelpPrompt EQ 1>style="text-align: center; cursor:help" ONMOUSEOVER="ddrivetip('#ncactRteMsg#','DFDFFF', 250)"; ONMOUSEOUT="hideddrivetip()"</cfif>>#DecimalFormat(act_rt_equiv_workload)#</td>
                                        <td align="center" width="85" bgcolor="#dailyOppColor#" valign="bottom" <cfif client.pivotHelpPrompt EQ 1>style="text-align: center; cursor:help" ONMOUSEOVER="ddrivetip('#ncpivPlnMsg#','DFDFFF', 250)"; ONMOUSEOUT="hideddrivetip()"</cfif>>#DecimalFormat(rt_pivot_dly_opp)#</td>
                                        <td align="center" width="85" valign="bottom" <cfif client.pivotHelpPrompt EQ 1>style="text-align: center; cursor:help" ONMOUSEOVER="ddrivetip('#ncpivActMsg#','DFDFFF', 375)"; ONMOUSEOUT="hideddrivetip()"</cfif>>#DecimalFormat(rt_pivot_perf_dly_act)#</td>
                                        <cfsilent>
                                            <cfset pachbgcolor=arrColor[arrLen].color>
                                            <cfloop index="i" from="#arrLen#" to="1" step="-1">
                                                <cfif arrColor[i].limit GTE opp_pct_ach>
                                                    <cfset pachbgcolor=arrColor[i].color>
                                                </cfif>
                                            </cfloop>
                                        </cfsilent>
                                        <td align="center" width="85" valign="bottom" <cfif client.pivotHelpPrompt EQ 1>style="text-align: center; cursor:help" ONMOUSEOVER="ddrivetip('#ncpctOppMsg#','DFDFFF', 250)"; ONMOUSEOUT="hideddrivetip()"</cfif> bgcolor="#pachbgcolor#">#DecimalFormat(opp_pct_ach*100)#</td>
                                    </tr>
                                </cfoutput>
                            </tbody>
                        </table>

                    </td>
                </tr>

                </table>
                </td>
            </tr>
            <tr>
                <td align="center" width="100%" colspan="4">
                    <table border="0" cellspacing="0" width="100%" height="44" align="center">
                          <tr align="center" valign="middle">
                             <td width="100%" height="44" bgcolor="#F8F8FF" valign="middle" align="center" valign="middle">
                                <a href="avar_pivot_xls.cfm?viewLevel=NC" title="Download City Delivery Pivot Opportunity to Excel"><img src="/images/avar_send2excel.gif" width="80" height="15" alt="Download City Delivery Pivot Opportunity to Excel" border="0"></a>
                             </td>
                        </tr>
                    </table>
                </td>
            </tr>

            </table>
        </form>
    </cfif>
</body>
</html>

