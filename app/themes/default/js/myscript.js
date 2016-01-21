$(document).ready(function()
{
    var opportunity_closedate = $("#opportunity_closedate").val();
    $("#Contract_closeDate").val(opportunity_closedate);
    
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
    
    var video_totalmmr = (no_units * video_bulk_mmr) + (video_retail_mmr * (no_units * (video_penetration/100)));
    var video_netbulk = no_units * (video_bulk_mmr - video_bulk_cost);
    var video_netretail = (video_retail_mmr - video_retail_cost) * (no_units * (video_penetration/100));
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
    
    var internet_totalmmr = (no_units * internet_bulk_mmr) + (internet_retail_mmr * (no_units * (internet_penetration/100)));
    var internet_netbulk = no_units * (internet_bulk_mmr - internet_bulk_cost);
    var internet_netretail = (internet_retail_mmr - internet_retail_cost) * (no_units * (internet_penetration/100));
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
    
    var phone_totalmmr = (no_units * phone_bulk_mmr) + (phone_retail_mmr * (no_units * (phone_penetration/100)));
    var phone_netbulk = no_units * (phone_bulk_mmr - phone_bulk_cost);
    var phone_netretail = (phone_retail_mmr - phone_retail_cost) * (no_units * (phone_penetration/100));
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
    
    var alarm_totalmmr = (no_units * alarm_bulk_mmr) + (alarm_retail_mmr * (no_units * (alarm_penetration/100)));
    var alarm_netbulk = no_units * (alarm_bulk_mmr - alarm_bulk_cost);
    var alarm_netretail = (alarm_retail_mmr - alarm_retail_cost) * (no_units * (alarm_penetration/100));
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
function getassesmenttotal()
{
    var total_bulk_cost = $("#total_bulk_cost").val();
    var total_bulk_mmr = $("#total_bulk_mmr").val();
    var bulk_cal1 = 0;
    if(total_bulk_mmr > 0)
        var bulk_cal1 = (1-(total_bulk_cost/total_bulk_mmr));
    var bulk_cal = bulk_cal1 * 100;
    $("#bulk_cal").val(bulk_cal.toFixed(2));
    
    var total_total_profit = $("#total_total_profit").val();
    var total_total_mmr = $("#total_total_mmr").val();
    var blended_cal1 = 0;
    if(total_total_mmr > 0)
        var blended_cal1 = (total_total_profit/total_total_mmr);
    var blended_cal = blended_cal1 * 100;
    $("#blended_cal").val(blended_cal.toFixed(2));
    
    var cosnt_totals = $("#cosnt_totals").val();
    var total_net_bulk = $("#total_net_bulk").val();
    var roi_cal = 0;
    if(total_net_bulk > 0)
        var roi_cal = cosnt_totals/total_net_bulk;
    $("#roi_cal").val(roi_cal.toFixed(2));
    
    var roi_blended = 0;
    if(total_total_profit > 0)
        var roi_blended = cosnt_totals/total_total_profit;
    $("#roi_blended").val(roi_blended.toFixed(2));
    
    var total_key = $("#total_key").val();
    var roi_money = 0;
    if(total_total_profit > 0)
        var roi_money = ((total_key*1) + (cosnt_totals*1))/total_net_bulk;
    $("#roi_money").val(roi_money.toFixed(2));
    
    var roi_key = 0;
    if(total_total_profit > 0)
        var roi_key = ((total_key*1) + (cosnt_totals*1))/total_total_profit;
    $("#roi_key").val(roi_key.toFixed(2));
    
    var no_units = $("#no_units").val();
    if((no_units<400 && bulk_cal1>=0.6) || (no_units>=400 && bulk_cal1>=0.5))
    {
        $("#bulk_res").val("Pass");
        $("#bulk_res_value").val(1);
    }
    else
    {
        $("#bulk_res").val("Fail");
        $("#bulk_res_value").val(0);
    }
    if((no_units<400 && blended_cal1>=0.6) || (no_units>=400 && blended_cal1>=0.5))
    {
        $("#blended_res").val("Pass");
        $("#blended_res_value").val(1);
    }
    else
    {
        $("#blended_res").val("Fail");
        $("#blended_res_value").val(0);
    }
    var contract_term = $("#contract_term").val();
    if((contract_term>7 && roi_cal<=36) || (contract_term<=7 && roi_cal<=24))
    {
        $("#roi_res").val("Pass");
        $("#roi_res_value").val(1);
    }
    else
    {
        $("#roi_res").val("Fail");
        $("#roi_res_value").val(0);
    }
    if((contract_term>7 && roi_blended<=36) || (contract_term<=7 && roi_blended<=24))
    {
        $("#roi_blend_res").val("Pass");
        $("#roi_blend_res_value").val(1);
    }
    else
    {
        $("#roi_blend_res").val("Fail");
        $("#roi_blend_res_value").val(0);
    }
    if((contract_term>7 && roi_money<=36) || (contract_term<=7 && roi_money<=24))
    {
        $("#roi_money_res").val("Pass");
        $("#roi_money_res_value").val(1);
    }
    else
    {
        $("#roi_money_res").val("Fail");
        $("#roi_money_res_value").val(0);
    }
    if((contract_term>7 && roi_key<=36) || (contract_term<=7 && roi_key<=24))
    {
        $("#roi_key_res").val("Pass");
        $("#roi_key_res_value").val(1);
    }
    else
    {
        $("#roi_key_res").val("Fail");
        $("#roi_key_res_value").val(0);
    }
    var total_res_value = ($("#bulk_res_value").val()*1) + ($("#blended_res_value").val()*1) + ($("#roi_res_value").val()*1) + ($("#roi_blend_res_value").val()*1) + ($("#roi_money_res_value").val()*1) + ($("#roi_key_res_value").val()*1);
    $("#total_res_value").val(total_res_value);
    if(total_res_value >= 5)
        $("#overall_score").val("Excellent");
    if(total_res_value == 4)
        $("#overall_score").val("Good");
    if(total_res_value == 3)
        $("#overall_score").val("Marginal");
    if(total_res_value == 2)
        $("#overall_score").val("Disqualify");
}