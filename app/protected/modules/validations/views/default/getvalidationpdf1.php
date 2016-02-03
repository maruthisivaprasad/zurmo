<?php ini_set("memory_limit","512M");?>
<table border="1" style="border-collapse:collapse;" cellpadding="0" cellspacing="1">
    <tbody>
    	<tr><td colspan="4"><h3><center>Validations</center></h3></td></tr>
    	<tr>
            <td>Number of Units</td>
            <td><?php echo $data['no_units'];?></td>
            <td style="padding-left:30px">Contract Term (Years)</td>
            <td style="padding-left:20px"><?php echo $data['contract_term'];?></td>
        </tr>
        <tr>
            <td>Door Fee</td>
            <td>$<?php echo !empty($data['door_fee']) ? number_format($data['door_fee'],2) : '0.00';?></td>
            <td style="padding-left:30px">Total Key Monies</td>
            <td style="padding-left:20px">$<?php echo !empty($data['total_key']) ? number_format($data['total_key'],2) : '0.00';?></td>
        </tr>
        <tr><td colspan="4"><h3>Video</h3></td></tr>
        <tr>
            <td>Bulk Services</td>
            <td><?php echo !empty($data['video_bulk_services']) ? number_format($data['video_bulk_services'],2) : '0.00';?></td>
            <td style="padding-left:30px">Bulk Cost Base</td>
            <td style="padding-left:20px"><?php echo !empty($data['video_bulk_cost']) ? number_format($data['video_bulk_cost'],2) : '0.00';?></td>
        </tr>
        <tr>
            <td>Bulk MRR</td>
            <td><?php echo $data['video_bulk_mmr'];?></td>
            <td style="padding-left:30px">Retail Cost Base</td>
            <td style="padding-left:20px"><?php echo $data['video_retail_cost'];?></td>
        </tr>
        <tr>
            <td>Retail MRR</td>
            <td><?php echo $data['video_retail_mmr'];?></td>
            <td style="padding-left:30px">Projected Penetration</td>
            <td style="padding-left:20px"><?php echo $data['video_penetration'];?></td>
        </tr>
        <tr>
            <td>Total MRR</td>
            <td><?php echo $data['video_total_mmr'];?></td>
            <td style="padding-left:30px">Net Bulk</td>
            <td style="padding-left:20px"><?php echo $data['video_net_bulk'];?></td>
        </tr>
        <tr>
            <td>Net Retail</td>
            <td><?php echo $data['video_net_retail'];?></td>
            <td style="padding-left:30px">Total Profit</td>
            <td style="padding-left:20px"><?php echo $data['video_total_profit'];?></td>
        </tr>
        <tr><td colspan="4"><h3>Internet</h3></td></tr>
        <tr>
            <td>Bulk Services</td>
            <td><?php echo $data['internet_bulk_services'];?></td>
            <td style="padding-left:30px">Bulk Cost Base</td>
            <td style="padding-left:20px"><?php echo $data['internet_bulk_cost'];?></td>
        </tr>
        <tr>
            <td>Bulk MRR</td>
            <td><?php echo $data['internet_bulk_mmr'];?></td>
            <td style="padding-left:30px">Retail Cost Base</td>
            <td style="padding-left:20px"><?php echo $data['internet_retail_cost'];?></td>
        </tr>
        <tr>
            <td>Retail MRR</td>
            <td><?php echo $data['internet_retail_mmr'];?></td>
            <td style="padding-left:30px">Projected Penetration</td>
            <td style="padding-left:20px"><?php echo $data['internet_penetration'];?></td>
        </tr>
        <tr>
            <td>Total MRR</td>
            <td><?php echo $data['internet_total_mmr'];?></td>
            <td style="padding-left:30px">Net Bulk</td>
            <td style="padding-left:20px"><?php echo $data['internet_net_bulk'];?></td>
        </tr>
        <tr>
            <td>Net Retail</td>
            <td><?php echo $data['internet_net_retail'];?></td>
            <td style="padding-left:30px">Total Profit</td>
            <td style="padding-left:20px"><?php echo $data['internet_total_profit'];?></td>
        </tr>
        <tr><td colspan="4"><h3>Phone</h3></td></tr>
        <tr>
            <td>Bulk Services</td>
            <td><?php echo $data['phone_bulk_services'];?></td>
            <td style="padding-left:30px">Bulk Cost Base</td>
            <td style="padding-left:20px"><?php echo $data['phone_bulk_cost'];?></td>
        </tr>
        <tr>
            <td>Bulk MRR</td>
            <td><?php echo $data['phone_bulk_mmr'];?></td>
            <td style="padding-left:30px">Retail Cost Base</td>
            <td style="padding-left:20px"><?php echo $data['phone_retail_cost'];?></td>
        </tr>
        <tr>
            <td>Retail MRR</td>
            <td><?php echo $data['phone_retail_mmr'];?></td>
            <td style="padding-left:30px">Projected Penetration</td>
            <td style="padding-left:20px"><?php echo $data['phone_penetration'];?></td>
        </tr>
        <tr>
            <td>Total MRR</td>
            <td><?php echo $data['phone_total_mmr'];?></td>
            <td style="padding-left:30px">Net Bulk</td>
            <td style="padding-left:20px"><?php echo $data['phone_net_bulk'];?></td>
        </tr>
        <tr>
            <td>Net Retail</td>
            <td><?php echo $data['phone_net_retail'];?></td>
            <td style="padding-left:30px">Total Profit</td>
            <td style="padding-left:20px"><?php echo $data['phone_total_profit'];?></td>
        </tr>
        <tr><td colspan="4"><h3>Alarm</h3></td></tr>
        <tr>
            <td>Bulk Services</td>
            <td><?php echo $data['alarm_bulk_services'];?></td>
            <td style="padding-left:30px">Bulk Cost Base</td>
            <td style="padding-left:20px"><?php echo $data['alarm_bulk_cost'];?></td>
        </tr>
        <tr>
            <td>Bulk MRR</td>
            <td><?php echo $data['alarm_bulk_mmr'];?></td>
            <td style="padding-left:30px">Retail Cost Base</td>
            <td style="padding-left:20px"><?php echo $data['alarm_retail_cost'];?></td>
        </tr>
        <tr>
            <td>Retail MRR</td>
            <td><?php echo $data['alarm_retail_mmr'];?></td>
            <td style="padding-left:30px">Projected Penetration</td>
            <td style="padding-left:20px"><?php echo $data['alarm_penetration'];?></td>
        </tr>
        <tr>
            <td>Total MRR</td>
            <td><?php echo $data['alarm_total_mmr'];?></td>
            <td style="padding-left:30px">Net Bulk</td>
            <td style="padding-left:20px"><?php echo $data['alarm_net_bulk'];?></td>
        </tr>
        <tr>
            <td>Net Retail</td>
            <td><?php echo $data['alarm_net_retail'];?></td>
            <td style="padding-left:30px">Total Profit</td>
            <td style="padding-left:20px"><?php echo $data['alarm_total_profit'];?></td>
        </tr>
        <tr><td colspan="4"><h3>Totals</h3></td></tr>
        <tr>
            <td>Bulk Cost Base</td>
            <td><?php echo $data['total_bulk_cost'];?></td>
            <td style="padding-left:30px">Bulk MRR</td>
            <td style="padding-left:20px"><?php echo $data['total_bulk_mmr'];?></td>
        </tr>
        <tr>
            <td>Retail Cost Base</td>
            <td><?php echo $data['total_retail_cost'];?></td>
            <td style="padding-left:30px">Retail MRR</td>
            <td style="padding-left:20px"><?php echo $data['total_retail_mmr'];?></td>
        </tr>
        <tr>
            <td>Total MRR</td>
            <td><?php echo $data['total_total_mmr'];?></td>
            <td style="padding-left:30px">Net Bulk</td>
            <td style="padding-left:20px"><?php echo $data['total_net_bulk'];?></td>
        </tr>
        <tr>
            <td>Net Retail</td>
            <td><?php echo $data['total_net_retail'];?></td>
            <td style="padding-left:30px">Total Profit</td>
            <td style="padding-left:20px"><?php echo $data['total_total_profit'];?></td>
        </tr>
        <tr><td colspan="4"><h3>Construction Analysis</h3></td></tr>
        <tr>
            <td>Construction Cost Per Unit</td>
            <td><?php echo $data['const_qty'];?></td>
            <td style="padding-left:30px"><?php echo $data['const_per'];?></td>
        </tr>
        <tr>
            <td>Totals</td>
            <td><?php echo $data['cosnt_totals'];?></td>
            <td style="padding-left:30px">Cost per Unit</td>
            <td style="padding-left:20px"><?php echo $data['cost_per_unit'];?></td>
        </tr>
        <tr><td colspan="4"><h3>Overall Assessment</h3></td></tr>
        <tr>
            <td colspan="2"><strong>Qualifyers</strong></td>
            <td><strong>Calculations</strong></td>
            <td><strong>Results</strong></td>
        </tr>
        <tr>
            <td colspan="2">Bulk Margin(%):</td>
            <td><?php echo $data['bulk_cal'];?></td>
            <td style="padding-left:30px"><?php echo $data['bulk_res'];?></td>
        </tr>
        <tr>
            <td colspan="2">Blended Margin(%):</td>
            <td><?php echo $data['blended_cal'];?></td>
            <td style="padding-left:30px"><?php echo $data['blended_res'];?></td>
        </tr>
        <tr>
            <td colspan="2">ROI Calculation (Bulk Only):</td>
            <td><?php echo $data['roi_cal'];?></td>
            <td style="padding-left:30px"><?php echo $data['roi_res'];?></td>
        </tr>
        <tr>
            <td colspan="2">ROI Calculation (Blended):</td>
            <td><?php echo $data['roi_blended'];?></td>
            <td style="padding-left:30px"><?php echo $data['roi_blend_res'];?></td>
        </tr>
        <tr>
            <td colspan="2">CapX ROI w/ Key Money (Bulk):</td>
            <td><?php echo $data['roi_money'];?></td>
            <td style="padding-left:30px"><?php echo $data['roi_money_res'];?></td>
        </tr>
        <tr>
            <td colspan="2">CapX ROI w/ Key Money (Blended):</td>
            <td><?php echo $data['roi_key'];?></td>
            <td style="padding-left:30px"><?php echo $data['roi_key_res'];?></td>
        </tr>
        <tr><td colspan="4"><h3>Overall Score</h3></td></tr>
        <tr><td colspan="4"><?php echo $data['overall_score'];?></td></tr>
    </tbody>
</table>