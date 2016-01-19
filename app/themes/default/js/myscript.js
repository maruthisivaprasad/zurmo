$(document).ready(function()
{
    var unitscr = parseInt($("#unitscr").val());
    var totalbulkpricstm =  parseInt($("#totalbulkpricstm").val()); 
    var totalcostprccstm =  parseInt($("#totalcostprccstm").val()); 
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
    if(videopricstm > 0)
    {
    	document.getElementById("Contract_propbillCstmCstm").required = true;
    	$("#Contract_propbillCstmCstm").closest('td').prev('th').append("<span class='required'>*</span>");
    }	
    if(alarampricstm > 0)
    {
    	document.getElementById("Contract_propAlaramCstm").required = true;
    	$("#Contract_propAlaramCstm").closest('td').prev('th').append("<span class='required'>*</span>");
    }
    if(phonepricstm > 0)
    {
    	document.getElementById("Contract_propphoneCstm").required = true;
    	$("#Contract_propphoneCstm").closest('td').prev('th').append("<span class='required'>*</span>");
    }
    if(internetpricstm > 0)
    {
    	document.getElementById("Contract_propInternetCstm").required = true;
    	$("#Contract_propInternetCstm").closest('td').prev('th').append("<span class='required'>*</span>");
    }
    
    	
    $( "#Opportunity_vidpricingCsCstm_value" ).keyup(function() {
            var video = parseInt($("#Opportunity_vidpricingCsCstm_value").val());
            var internet = parseInt($("#Opportunity_internetbulkCstm_value").val());
            var phone = parseInt($("#Opportunity_phonebulkCstCstm_value").val());
            var alaram = parseInt($("#Opportunity_alarmbulkCstCstm_value").val());
            var totalBulk = video + internet + phone + alaram
            var totalProposed = totalBulk * unitscr;
            $("#Opportunity_totalbulkpriCstm_value").val(totalBulk);
            $("#Opportunity_tprmonreCstm_value").val(totalProposed);
            
    });
    $( "#Opportunity_internetbulkCstm_value" ).keyup(function() {
            var video = parseInt($("#Opportunity_vidpricingCsCstm_value").val());
            var internet = parseInt($("#Opportunity_internetbulkCstm_value").val());
            var phone = parseInt($("#Opportunity_phonebulkCstCstm_value").val());
            var alaram = parseInt($("#Opportunity_alarmbulkCstCstm_value").val());
            var totalBulk = video + internet + phone + alaram
            var totalProposed = totalBulk * unitscr;
            $("#Opportunity_totalbulkpriCstm_value").val(totalBulk);
            $("#Opportunity_tprmonreCstm_value").val(totalProposed);
    });
    $( "#Opportunity_phonebulkCstCstm_value" ).keyup(function() {
            var video = parseInt($("#Opportunity_vidpricingCsCstm_value").val());
            var internet = parseInt($("#Opportunity_internetbulkCstm_value").val());
            var phone = parseInt($("#Opportunity_phonebulkCstCstm_value").val());
            var alaram = parseInt($("#Opportunity_alarmbulkCstCstm_value").val());
            var totalBulk = video + internet + phone + alaram
            var totalProposed = totalBulk * unitscr;
            $("#Opportunity_totalbulkpriCstm_value").val(totalBulk);
            $("#Opportunity_tprmonreCstm_value").val(totalProposed);
    });
    $( "#Opportunity_alarmbulkCstCstm_value" ).keyup(function() {
            var video = parseInt($("#Opportunity_vidpricingCsCstm_value").val());
            var internet = parseInt($("#Opportunity_internetbulkCstm_value").val());
            var phone = parseInt($("#Opportunity_phonebulkCstCstm_value").val());
            var alaram = parseInt($("#Opportunity_alarmbulkCstCstm_value").val());
            var totalBulk = video + internet + phone + alaram
            var totalProposed = totalBulk * unitscr;
            $("#Opportunity_totalbulkpriCstm_value").val(totalBulk);
            $("#Opportunity_tprmonreCstm_value").val(totalProposed);
    });
    $( "#Opportunity_constructcosCstm_value" ).keyup(function() {
            var conscst = parseInt($("#Opportunity_constructcosCstm_value").val());
            var totalProject = conscst * unitscr;
            $("#Opportunity_amount_value").val(totalProject);
    });
    $( "#Contract_doorfeeCstmCstm_value" ).keyup(function() {
            var doorfee = parseInt($("#Contract_doorfeeCstmCstm_value").val());
            var totalkey = doorfee * unitscr;
            $("#Contract_amount_value").val(totalkey);
            var pjcost1 = (totalcostprccstm + totalkey)/monthrec;
            var pjcost = Math.round(pjcost1);
            $("#Contract_roiCstmCstm").val(pjcost);
    });
    $( "#Contract_blendedbulkCstm" ).keyup(function() {
            var bulkmargin = parseInt($("#Contract_blendedbulkCstm").val());
            var totalnet = (monthrec * bulkmargin) / 100;
            $("#Contract_monthlynetCsCstm_value").val(totalnet);
    });
});
