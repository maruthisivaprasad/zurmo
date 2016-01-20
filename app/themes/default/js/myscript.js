$(document).ready(function()
{
    var unitscr = $("#unitscr").val();
    var totalbulkpricstm =  $("#totalbulkpricstm").val(); 
    var totalcostprccstm =  $("#totalcostprccstm").val(); 
    var monthrec = totalbulkpricstm * unitscr;
    $("#Contract_monthlynetCsCstm_value").val(monthrec);
    $("#Contract_monthlynetCsCstm_value").attr('readonly', true);
    $("#Opportunity_totalbulkpriCstm_value").attr('readonly', true);
    $("#Opportunity_tprmonreCstm_value").attr('readonly', true);
    $("#Opportunity_amount_value").attr('readonly', true);
    
    var videopricstm = $("#videopricstm").val();
    var alarampricstm = $("#alarampricstm").val();
    var phonepricstm = $("#phonepricstm").val();
    var internetpricstm = $("#internetpricstm").val();
    var bulkval = $("#bulkval").val();
    //if(videopricstm > 0)
    if (bulkval.indexOf("Video") >= 0)
    {
    	document.getElementById("Contract_propbillCstmCstm").required = true;
    	$("#Contract_propbillCstmCstm").closest('td').prev('th').append("<span class='required'>*</span>");
    }	
    //if(alarampricstm > 0)
    if (bulkval.indexOf("Alarm") >= 0)
    {
    	document.getElementById("Contract_propAlaramCstm").required = true;
    	$("#Contract_propAlaramCstm").closest('td').prev('th').append("<span class='required'>*</span>");
    }
    //if(phonepricstm > 0)
    if (bulkval.indexOf("Phone") >= 0)
    {
    	document.getElementById("Contract_propphoneCstm").required = true;
    	$("#Contract_propphoneCstm").closest('td').prev('th').append("<span class='required'>*</span>");
    }
    //if(internetpricstm > 0)
    if (bulkval.indexOf("Internet") >= 0)
    {
    	document.getElementById("Contract_propInternetCstm").required = true;
    	$("#Contract_propInternetCstm").closest('td').prev('th').append("<span class='required'>*</span>");
    }
    $( "#Opportunity_vidpricingCsCstm_value" ).keyup(function() {
            var video = $("#Opportunity_vidpricingCsCstm_value").val();
            var internet = $("#Opportunity_internetbulkCstm_value").val();
            var phone = $("#Opportunity_phonebulkCstCstm_value").val();
            var alaram = $("#Opportunity_alarmbulkCstCstm_value").val();
            var totalBulk = video + internet + phone + alaram
            var totalProposed = totalBulk * unitscr;
            $("#Opportunity_totalbulkpriCstm_value").val(totalBulk);
            $("#Opportunity_tprmonreCstm_value").val(totalProposed);
            
    });
    $( "#Opportunity_internetbulkCstm_value" ).keyup(function() {
            var video = $("#Opportunity_vidpricingCsCstm_value").val();
            var internet = $("#Opportunity_internetbulkCstm_value").val();
            var phone = $("#Opportunity_phonebulkCstCstm_value").val();
            var alaram = $("#Opportunity_alarmbulkCstCstm_value").val();
            var totalBulk = video + internet + phone + alaram
            var totalProposed = totalBulk * unitscr;
            $("#Opportunity_totalbulkpriCstm_value").val(totalBulk);
            $("#Opportunity_tprmonreCstm_value").val(totalProposed);
    });
    $( "#Opportunity_phonebulkCstCstm_value" ).keyup(function() {
            var video = $("#Opportunity_vidpricingCsCstm_value").val();
            var internet = $("#Opportunity_internetbulkCstm_value").val();
            var phone = $("#Opportunity_phonebulkCstCstm_value").val();
            var alaram = $("#Opportunity_alarmbulkCstCstm_value").val();
            var totalBulk = video + internet + phone + alaram
            var totalProposed = totalBulk * unitscr;
            $("#Opportunity_totalbulkpriCstm_value").val(totalBulk);
            $("#Opportunity_tprmonreCstm_value").val(totalProposed);
    });
    $( "#Opportunity_alarmbulkCstCstm_value" ).keyup(function() {
            var video = $("#Opportunity_vidpricingCsCstm_value").val();
            var internet = $("#Opportunity_internetbulkCstm_value").val();
            var phone = $("#Opportunity_phonebulkCstCstm_value").val();
            var alaram = $("#Opportunity_alarmbulkCstCstm_value").val();
            var totalBulk = video + internet + phone + alaram
            var totalProposed = totalBulk * unitscr;
            $("#Opportunity_totalbulkpriCstm_value").val(totalBulk);
            $("#Opportunity_tprmonreCstm_value").val(totalProposed);
    });
    $( "#Opportunity_constructcosCstm_value" ).keyup(function() {
            var conscst = $("#Opportunity_constructcosCstm_value").val();
            var totalProject = conscst * unitscr;
            $("#Opportunity_amount_value").val(totalProject);
    });
    $( "#Contract_doorfeeCstmCstm_value" ).keyup(function() {
            var doorfee = $("#Contract_doorfeeCstmCstm_value").val();
            var totalkey = doorfee * unitscr;
            $("#Contract_amount_value").val(totalkey);
            var pjcost1 = (totalcostprccstm + totalkey)/monthrec;
            var pjcost = Math.round(pjcost1);
            $("#Contract_roiCstmCstm").val(pjcost);
    });
    $( "#Contract_blendedbulkCstm" ).keyup(function() {
            var bulkmargin = $("#Contract_blendedbulkCstm").val();
            var totalnet = (monthrec * bulkmargin) / 100;
            $("#Contract_monthlynetCsCstm_value").val(totalnet);
    });
});
function getvideototal()
{
    var no_units = $("#no_units").val();
    var video_bulk_cost = $("#video_bulk_cost").val();
    var video_retail_cost = $("#video_retail_cost").val();
    var video_bulk_mmr = $("#video_bulk_mmr").val();
    var video_retail_mmr = $("#video_retail_mmr").val();
    var video_penetration = $("#video_penetration").val();
    
    var video_totalmmr = (no_units * video_bulk_mmr) + (video_retail_mmr * (no_units * video_penetration));
    var video_netbulk = no_units * (video_bulk_mmr - video_bulk_cost);
    var video_netretail = (video_retail_mmr - video_retail_cost) * (no_units * video_penetration);
    var video_totalprofit = video_netbulk + video_netretail;
    
    $("#video_total_mmr").val(video_totalmmr.toFixed(2));
    $("#video_net_bulk").val(video_netbulk.toFixed(2));
    $("#video_net_retail").val(video_netretail.toFixed(2));
    $("#video_total_profit").val(video_totalprofit.toFixed(2));
}

function getinternettotal()
{
    var no_units = $("#no_units").val();
    var internet_bulk_cost = $("#internet_bulk_cost").val();
    var internet_retail_cost = $("#internet_retail_cost").val();
    var internet_bulk_mmr = $("#internet_bulk_mmr").val();
    var internet_retail_mmr = $("#internet_retail_mmr").val();
    var internet_penetration = $("#internet_penetration").val();
    
    var internet_totalmmr = (no_units * internet_bulk_mmr) + (internet_retail_mmr * (no_units * internet_penetration));
    var internet_netbulk = no_units * (internet_bulk_mmr - internet_bulk_cost);
    var internet_netretail = (internet_retail_mmr - internet_retail_cost) * (no_units * internet_penetration);
    var internet_totalprofit = internet_netbulk + internet_netretail;
    
    $("#internet_total_mmr").val(internet_totalmmr.toFixed(2));
    $("#internet_net_bulk").val(internet_netbulk.toFixed(2));
    $("#internet_net_retail").val(internet_netretail.toFixed(2));
    $("#internet_total_profit").val(internet_totalprofit.toFixed(2));
}

function getphonetotal()
{
    var no_units = $("#no_units").val();
    var phone_bulk_cost = $("#phone_bulk_cost").val();
    var phone_retail_cost = $("#phone_retail_cost").val();
    var phone_bulk_mmr = $("#phone_bulk_mmr").val();
    var phone_retail_mmr = $("#phone_retail_mmr").val();
    var phone_penetration = $("#phone_penetration").val();
    
    var phone_totalmmr = (no_units * phone_bulk_mmr) + (phone_retail_mmr * (no_units * phone_penetration));
    var phone_netbulk = no_units * (phone_bulk_mmr - phone_bulk_cost);
    var phone_netretail = (phone_retail_mmr - phone_retail_cost) * (no_units * phone_penetration);
    var phone_totalprofit = phone_netbulk + phone_netretail;
    
    $("#phone_total_mmr").val(phone_totalmmr.toFixed(2));
    $("#phone_net_bulk").val(phone_netbulk.toFixed(2));
    $("#phone_net_retail").val(phone_netretail.toFixed(2));
    $("#phone_total_profit").val(phone_totalprofit.toFixed(2));
}

function getalarmtotal()
{
    var no_units = $("#no_units").val();
    var alarm_bulk_cost = $("#alarm_bulk_cost").val();
    var alarm_retail_cost = $("#alarm_retail_cost").val();
    var alarm_bulk_mmr = $("#alarm_bulk_mmr").val();
    var alarm_retail_mmr = $("#alarm_retail_mmr").val();
    var alarm_penetration = $("#alarm_penetration").val();
    
    var alarm_totalmmr = (no_units * alarm_bulk_mmr) + (alarm_retail_mmr * (no_units * alarm_penetration));
    var alarm_netbulk = no_units * (alarm_bulk_mmr - alarm_bulk_cost);
    var alarm_netretail = (alarm_retail_mmr - alarm_retail_cost) * (no_units * alarm_penetration);
    var alarm_totalprofit = alarm_netbulk + alarm_netretail;
    
    $("#alarm_total_mmr").val(alarm_totalmmr.toFixed(2));
    $("#alarm_net_bulk").val(alarm_netbulk.toFixed(2));
    $("#alarm_net_retail").val(alarm_netretail.toFixed(2));
    $("#alarm_total_profit").val(alarm_totalprofit.toFixed(2));
}

function gettotal()
{
    var video_bulk_cost = $("#video_bulk_cost").val();
    var internet_bulk_cost = $("#internet_bulk_cost").val();
    var phone_bulk_cost = $("#phone_bulk_cost").val();
    var alarm_bulk_cost = $("#alarm_bulk_cost").val();
    
    var video_bulk_mmr = $("#video_bulk_mmr").val();
    var internet_bulk_mmr = $("#internet_bulk_mmr").val();
    var phone_bulk_mmr = $("#phone_bulk_mmr").val();
    var alarm_bulk_mmr = $("#alarm_bulk_mmr").val();
    
    var video_retail_cost = $("#video_retail_cost").val();
    var internet_retail_cost = $("#internet_retail_cost").val();
    var phone_retail_cost = $("#phone_retail_cost").val();
    var alarm_retail_cost = $("#alarm_retail_cost").val();
    
    var video_retail_mmr = $("#video_retail_mmr").val();
    var internet_retail_mmr = $("#internet_retail_mmr").val();
    var phone_retail_mmr = $("#phone_retail_mmr").val();
    var alarm_retail_mmr = $("#alarm_retail_mmr").val();
    
    var video_total_mmr = $("#video_total_mmr").val();
    var internet_total_mmr = $("#internet_total_mmr").val();
    var phone_total_mmr = $("#phone_total_mmr").val();
    var alarm_total_mmr = $("#alarm_total_mmr").val();
    
    var video_net_retail = $("#video_net_retail").val();
    var internet_net_retail = $("#internet_net_retail").val();
    var phone_net_retail = $("#phone_net_retail").val();
    var alarm_net_retail = $("#alarm_net_retail").val();
    
    var video_net_bulk = $("#video_net_bulk").val();
    var internet_net_bulk = $("#internet_net_bulk").val();
    var phone_net_bulk = $("#phone_net_bulk").val();
    var alarm_net_bulk = $("#alarm_net_bulk").val();
    
    var video_total_profit = $("#video_total_profit").val();
    var internet_total_profit = $("#internet_total_profit").val();
    var phone_total_profit = $("#phone_total_profit").val();
    var alarm_total_profit = $("#alarm_total_profit").val();
    
    var total_bulk_cost = (video_bulk_cost*1) + (internet_bulk_cost*1) + (phone_bulk_cost*1) + (alarm_bulk_cost*1);
    var total_bulk_mmr = (video_bulk_mmr*1) + (internet_bulk_mmr*1) + (phone_bulk_mmr*1) + (alarm_bulk_mmr*1);
    var total_retail_cost = (video_retail_cost*1) + (internet_retail_cost*1) + (phone_retail_cost*1) + (alarm_retail_cost*1);
    var total_retail_mmr = (video_retail_mmr*1) + (internet_retail_mmr*1) + (phone_retail_mmr*1) + (alarm_retail_mmr*1);
    var total_total_mmr = (video_total_mmr*1) + (internet_total_mmr*1) + (phone_total_mmr*1) + (alarm_total_mmr*1);
    var total_net_retail = (video_net_retail*1) + (internet_net_retail*1) + (phone_net_retail*1) + (alarm_net_retail*1);
    var total_net_bulk = (video_net_bulk*1) + (internet_net_bulk*1) + (phone_net_bulk*1) + (alarm_net_bulk*1);
    var total_total_profit = (video_total_profit*1) + (internet_total_profit*1) + (phone_total_profit*1) + (alarm_total_profit*1);
    
    $("#total_bulk_cost").val(total_bulk_cost.toFixed(2));
    $("#total_bulk_mmr").val(total_bulk_mmr.toFixed(2));
    $("#total_retail_cost").val(total_retail_cost.toFixed(2));
    $("#total_retail_mmr").val(total_retail_mmr.toFixed(2));
    $("#total_total_mmr").val(total_total_mmr.toFixed(2));
    $("#total_net_retail").val(total_net_retail.toFixed(2));
    $("#total_net_bulk").val(total_net_bulk.toFixed(2));
    $("#total_total_profit").val(total_total_profit.toFixed(2));
}
function getconstruct()
{
    var const_qty = $("#const_qty").val();
    var const_per = $("#const_per").val();
    var no_units = $("#no_units").val();
    var cosnt_totals = const_qty * const_per;
    if(no_units > 0)
        var cost_per_unit = cosnt_totals/no_units;
    else
        var cost_per_unit = 0;
    $("#cosnt_totals").val(cosnt_totals.toFixed(2));
    $("#cost_per_unit").val(cost_per_unit.toFixed(2));
}
