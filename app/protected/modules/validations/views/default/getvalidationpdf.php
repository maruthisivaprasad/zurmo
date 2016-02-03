<?php ini_set("memory_limit","512M");?>
<table border="1" style="border-collapse:collapse;" cellpadding="0" cellspacing="1">
    <tbody>
    	<tr>
            <td width="25%">Number of Units</td>
            <td width="25%"><?php echo $data['no_units'];?></td>
            <td style="padding-left:30px" width="25%">Contract Term (Years)</td>
            <td style="padding-left:20px" width="25%"><?php echo $data['contract_term'];?></td>
        </tr>
        <tr>
            <td width="25%">Door Fee</td>
            <td width="25%">$<?php echo !empty($data['door_fee']) ? number_format($data['door_fee'],2) : '0.00';?></td>
            <td style="padding-left:30px" width="25%">Total Key Monies</td>
            <td style="padding-left:20px" width="25%">$<?php echo !empty($data['total_key']) ? number_format($data['total_key'],2) : '0.00';?></td>
        </tr>
        <tr><td colspan="4"><h4>Video</h4></td></tr>
        <tr>
            <td width="25%">Bulk Services</td>
            <td width="25%"><?php echo $data['video_bulk_services'];?></td>
            <td style="padding-left:30px" width="25%">Bulk Cost Base</td>
            <td style="padding-left:20px" width="25%">$<?php echo !empty($data['video_bulk_cost']) ? number_format($data['video_bulk_cost'],2) : '0.00';?></td>
        </tr>
        <tr>
            <td width="25%">Bulk MRR</td>
            <td width="25%">$<?php echo !empty($data['video_bulk_mmr']) ? number_format($data['video_bulk_mmr'],2) : '0.00';?></td>
            <td style="padding-left:30px" width="25%">Retail Cost Base</td>
            <td style="padding-left:20px" width="25%">$<?php echo !empty($data['video_retail_cost']) ? number_format($data['video_retail_cost'],2) : '0.00';?></td>
        </tr>
        <tr>
            <td width="25%">Retail MRR</td>
            <td width="25%">$<?php echo !empty($data['video_retail_mmr']) ? number_format($data['video_retail_mmr'],2) : '0.00';?></td>
            <td style="padding-left:30px" width="25%">Projected Penetration</td>
            <td style="padding-left:20px" width="25%">$<?php echo !empty($data['video_penetration']) ? number_format($data['video_penetration'],2) : '0.00';?></td>
        </tr>
        <tr>
            <td width="25%">Total MRR</td>
            <td width="25%">$<?php echo !empty($data['video_total_mmr']) ? number_format($data['video_total_mmr'],2) : '0.00';?></td>
            <td style="padding-left:30px" width="25%">Net Bulk</td>
            <td style="padding-left:20px" width="25%">$<?php echo !empty($data['video_net_bulk']) ? number_format($data['video_net_bulk'],2) : '0.00';?></td>
        </tr>
        <tr>
            <td width="25%">Net Retail</td>
            <td width="25%">$<?php echo !empty($data['video_net_retail']) ? number_format($data['video_net_retail'],2) : '0.00';?></td>
            <td style="padding-left:30px" width="25%">Total Profit</td>
            <td style="padding-left:20px" width="25%">$<?php echo !empty($data['video_total_profit']) ? number_format($data['video_total_profit'],2) : '0.00';?></td>
        </tr>
        <tr><td colspan="4"><h4>Internet</h4></td></tr>
        <tr>
            <td width="25%">Bulk Services</td>
            <td width="25%"><?php echo $data['internet_bulk_services'];?></td>
            <td style="padding-left:30px" width="25%">Bulk Cost Base</td>
            <td style="padding-left:20px" width="25%">$<?php echo !empty($data['internet_bulk_cost']) ? number_format($data['internet_bulk_cost'],2) : '0.00';?></td>
        </tr>
        <tr>
            <td width="25%">Bulk MRR</td>
            <td width="25%">$<?php echo !empty($data['internet_bulk_mmr']) ? number_format($data['internet_bulk_mmr'],2) : '0.00';?></td>
            <td style="padding-left:30px" width="25%">Retail Cost Base</td>
            <td style="padding-left:20px" width="25%">$<?php echo !empty($data['internet_retail_cost']) ? number_format($data['internet_retail_cost'],2) : '0.00';?></td>
        </tr>
        <tr>
            <td width="25%">Retail MRR</td>
            <td width="25%">$<?php echo !empty($data['internet_retail_mmr']) ? number_format($data['internet_retail_mmr'],2) : '0.00';?></td>
            <td style="padding-left:30px" width="25%">Projected Penetration</td>
            <td style="padding-left:20px" width="25%">$<?php echo !empty($data['internet_penetration']) ? number_format($data['internet_penetration'],2) : '0.00';?></td>
        </tr>
        <tr>
            <td width="25%">Total MRR</td>
            <td width="25%">$<?php echo !empty($data['internet_total_mmr']) ? number_format($data['internet_total_mmr'],2) : '0.00';?></td>
            <td style="padding-left:30px" width="25%">Net Bulk</td>
            <td style="padding-left:20px" width="25%">$<?php echo !empty($data['internet_net_bulk']) ? number_format($data['internet_net_bulk'],2) : '0.00';?></td>
        </tr>
        <tr>
            <td width="25%">Net Retail</td>
            <td width="25%">$<?php echo !empty($data['internet_net_retail']) ? number_format($data['internet_net_retail'],2) : '0.00';?></td>
            <td style="padding-left:30px" width="25%">Total Profit</td>
            <td style="padding-left:20px" width="25%">$<?php echo !empty($data['internet_total_profit']) ? number_format($data['internet_total_profit'],2) : '0.00';?></td>
        </tr>
        <tr><td colspan="4"><h4>Phone</h4></td></tr>
        <tr>
            <td width="25%">Bulk Services</td>
            <td width="25%"><?php echo $data['phone_bulk_services'];?></td>
            <td style="padding-left:30px" width="25%">Bulk Cost Base</td>
            <td style="padding-left:20px" width="25%">$<?php echo !empty($data['phone_bulk_cost']) ? number_format($data['phone_bulk_cost'],2) : '0.00';?></td>
        </tr>
        <tr>
            <td width="25%">Bulk MRR</td>
            <td width="25%">$<?php echo !empty($data['phone_bulk_mmr']) ? number_format($data['phone_bulk_mmr'],2) : '0.00';?></td>
            <td style="padding-left:30px" width="25%">Retail Cost Base</td>
            <td style="padding-left:20px" width="25%">$<?php echo !empty($data['phone_retail_cost']) ? number_format($data['phone_retail_cost'],2) : '0.00';?></td>
        </tr>
        <tr>
            <td width="25%">Retail MRR</td>
            <td width="25%">$<?php echo !empty($data['phone_retail_mmr']) ? number_format($data['phone_retail_mmr'],2) : '0.00';?></td>
            <td style="padding-left:30px" width="25%">Projected Penetration</td>
            <td style="padding-left:20px" width="25%">$<?php echo !empty($data['phone_penetration']) ? number_format($data['phone_penetration'],2) : '0.00';?></td>
        </tr>
        <tr>
            <td width="25%">Total MRR</td>
            <td width="25%">$<?php echo !empty($data['phone_total_mmr']) ? number_format($data['phone_total_mmr'],2) : '0.00';?></td>
            <td style="padding-left:30px" width="25%">Net Bulk</td>
            <td style="padding-left:20px" width="25%">$<?php echo !empty($data['phone_net_bulk']) ? number_format($data['phone_net_bulk'],2) : '0.00';?></td>
        </tr>
        <tr>
            <td width="25%">Net Retail</td>
            <td width="25%">$<?php echo !empty($data['phone_net_retail']) ? number_format($data['phone_net_retail'],2) : '0.00';?></td>
            <td style="padding-left:30px" width="25%">Total Profit</td>
            <td style="padding-left:20px" width="25%">$<?php echo !empty($data['phone_total_profit']) ? number_format($data['phone_total_profit'],2) : '0.00';?></td>
        </tr>
        <tr><td colspan="4"><h4>Alarm</h4></td></tr>
        <tr>
            <td width="25%">Bulk Services</td>
            <td width="25%"><?php echo $data['alarm_bulk_services'];?></td>
            <td style="padding-left:30px" width="25%">Bulk Cost Base</td>
            <td style="padding-left:20px" width="25%">$<?php echo !empty($data['alarm_bulk_cost']) ? number_format($data['alarm_bulk_cost'],2) : '0.00';?></td>
        </tr>
        <tr>
            <td width="25%">Bulk MRR</td>
            <td width="25%">$<?php echo !empty($data['alarm_bulk_mmr']) ? number_format($data['alarm_bulk_mmr'],2) : '0.00';?></td>
            <td style="padding-left:30px" width="25%">Retail Cost Base</td>
            <td style="padding-left:20px" width="25%">$<?php echo !empty($data['alarm_retail_cost']) ? number_format($data['alarm_retail_cost'],2) : '0.00';?></td>
        </tr>
        <tr>
            <td width="25%">Retail MRR</td>
            <td width="25%">$<?php echo !empty($data['alarm_retail_mmr']) ? number_format($data['alarm_retail_mmr'],2) : '0.00';?></td>
            <td style="padding-left:30px" width="25%">Projected Penetration</td>
            <td style="padding-left:20px" width="25%">$<?php echo !empty($data['alarm_penetration']) ? number_format($data['alarm_penetration'],2) : '0.00';?></td>
        </tr>
        <tr>
            <td width="25%">Total MRR</td>
            <td width="25%">$<?php echo !empty($data['alarm_total_mmr']) ? number_format($data['alarm_total_mmr'],2) : '0.00';?></td>
            <td style="padding-left:30px" width="25%">Net Bulk</td>
            <td style="padding-left:20px" width="25%">$<?php echo !empty($data['alarm_net_bulk']) ? number_format($data['alarm_net_bulk'],2) : '0.00';?></td>
        </tr>
        <tr>
            <td width="25%">Net Retail</td>
            <td width="25%">$<?php echo !empty($data['alarm_net_retail']) ? number_format($data['alarm_net_retail'],2) : '0.00';?></td>
            <td style="padding-left:30px" width="25%">Total Profit</td>
            <td style="padding-left:20px" width="25%">$<?php echo !empty($data['alarm_total_profit']) ? number_format($data['alarm_total_profit'],2) : '0.00';?></td>
        </tr>
        <tr><td colspan="4"><h4>Totals</h4></td></tr>
        <tr>
            <td width="25%">Bulk Cost Base</td>
            <td width="25%">$<?php echo !empty($data['total_bulk_cost']) ? number_format($data['total_bulk_cost'],2) : '0.00';?></td>
            <td style="padding-left:30px" width="25%">Bulk MRR</td>
            <td style="padding-left:20px" width="25%">$<?php echo !empty($data['total_bulk_mmr']) ? number_format($data['total_bulk_mmr'],2) : '0.00';?></td>
        </tr>
        <tr>
            <td width="25%">Retail Cost Base</td>
            <td width="25%">$<?php echo !empty($data['total_retail_cost']) ? number_format($data['total_retail_cost'],2) : '0.00';?></td>
            <td style="padding-left:30px" width="25%">Retail MRR</td>
            <td style="padding-left:20px" width="25%">$<?php echo !empty($data['total_retail_mmr']) ? number_format($data['total_retail_mmr'],2) : '0.00';?></td>
        </tr>
        <tr>
            <td width="25%">Total MRR</td>
            <td width="25%">$<?php echo !empty($data['total_total_mmr']) ? number_format($data['total_total_mmr'],2) : '0.00';?></td>
            <td style="padding-left:30px" width="25%">Net Bulk</td>
            <td style="padding-left:20px" width="25%">$<?php echo !empty($data['total_net_bulk']) ? number_format($data['total_net_bulk'],2) : '0.00';?></td>
        </tr>
        <tr>
            <td width="25%">Net Retail</td>
            <td width="25%">$<?php echo !empty($data['total_net_retail']) ? number_format($data['total_net_retail'],2) : '0.00';?></td>
            <td style="padding-left:30px" width="25%">Total Profit</td>
            <td style="padding-left:20px" width="25%">$<?php echo !empty($data['total_total_profit']) ? number_format($data['total_total_profit'],2) : '0.00';?></td>
        </tr>
        <tr><td colspan="4"><h4>Construction Analysis</h4></td></tr>
        <tr>
            <td width="25%">Construction Cost Per Unit</td>
            <td width="25%">$<?php echo !empty($data['const_qty']) ? number_format($data['const_qty'],2) : '0.00';?></td>
            <td style="padding-left:30px" width="25%">$<?php echo !empty($data['const_per']) ? number_format($data['const_per'],2) : '0.00';?></td>
        </tr>
        <tr>
            <td width="25%">Totals</td>
            <td width="25%">$<?php echo !empty($data['cosnt_totals']) ? number_format($data['cosnt_totals'],2) : '0.00';?></td>
            <td style="padding-left:30px" width="25%">Cost per Unit</td>
            <td style="padding-left:20px" width="25%">$<?php echo !empty($data['cost_per_unit']) ? number_format($data['cost_per_unit'],2) : '0.00';?></td>
        </tr>
        <tr><td colspan="4"><h4>Overall Assessment</h4></td></tr>
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
        <tr><td colspan="4"><h4>Overall Score</h4></td></tr>
        <tr><td colspan="4"><?php echo $data['overall_score'];?></td></tr>
    </tbody>
</table>