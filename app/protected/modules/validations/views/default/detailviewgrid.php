<?php $this->renderpartial('customheader');?>
<div class="wrapper">
    <h1><span class="truncated-title"><span class="ellipsis-content">Validations</span></span></h1>
    <div class="wide double-column form">
        <form id="edit-form" action="<?php echo Yii::app()->request->baseUrl;?>/index.php/validations/default/create" method="post">
            <div style="display:none">
                <input type="hidden" value="01d6cbc28740a40361af50c64f493abb02186e2b" name="YII_CSRF_TOKEN" />
            </div>
            <div class="attributesContainer">
                <div class="left-column">
                    <div class="panel">
                        <table class="form-fields double-column">
                            <colgroup><col class="col-0" /><col class="col-1" />
                            <col class="col-2" /><col class="col-3" /></colgroup>
                            <tbody>
                                <tr>
                                    <td>Number of Units</td>
                                    <td><input type="text" name="no_units" id="no_units" value="<?php echo $_SESSION['unitsCstmCstm'];?>"></td>
                                    <td style="padding-left:30px">Contract Term (Years)</td>
                                    <td style="padding-left:20px"><input type="text" name="contract_term" id="contract_term" value=""></td>
                                </tr>
                                <tr>
                                    <td>Door Fee</td>
                                    <td><input type="text" name="door_fee" id="door_fee" value="<?php echo $_SESSION['unitsCstmCstm'];?>"></td>
                                    <td style="padding-left:30px">Total Key Monies</td>
                                    <td style="padding-left:20px"><input type="text" name="total_key" id="total_key" value=""></td>
                                </tr>
                                <tr><td colspan="4"><h3>Video</h3></td></tr>
                                <tr>
                                    <td>Bulk Services</td>
                                    <td><input type="text" name="video_bulk_services" id="video_bulk_services" value=""></td>
                                    <td style="padding-left:30px">Bulk Cost Base</td>
                                    <td style="padding-left:20px"><input type="text" name="video_bulk_cost" id="video_bulk_cost" value=""></td>
                                </tr>
                                <tr>
                                    <td>Bulk MRR</td>
                                    <td><input type="text" name="video_bulk_mmr" id="video_bulk_mmr" value=""></td>
                                    <td style="padding-left:30px">Retail Cost Base</td>
                                    <td style="padding-left:20px"><input type="text" name="video_retail_cost" id="video_retail_cost" value=""></td>
                                </tr>
                                <tr>
                                    <td>Retail MRR</td>
                                    <td><input type="text" name="video_retail_mmr" id="video_retail_mmr" value=""></td>
                                    <td style="padding-left:30px">Projected Penetration</td>
                                    <td style="padding-left:20px"><input type="text" name="video_penetration" id="video_penetration" value=""></td>
                                </tr>
                                <tr>
                                    <td>Total MRR</td>
                                    <td><input type="text" name="video_total_mmr" id="video_total_mmr" value=""></td>
                                    <td style="padding-left:30px">Net Bulk</td>
                                    <td style="padding-left:20px"><input type="text" name="video_net_bulk" id="video_net_bulk" value=""></td>
                                </tr>
                                <tr>
                                    <td>Net Retail</td>
                                    <td><input type="text" name="video_net_retail" id="video_net_retail" value=""></td>
                                    <td style="padding-left:30px">Total Profit</td>
                                    <td style="padding-left:20px"><input type="text" name="video_total_profit" id="video_total_profit" value=""></td>
                                </tr>
                                <tr><td colspan="4"><h3>Internet</h3></td></tr>
                                <tr>
                                    <td>Bulk Services</td>
                                    <td><input type="text" name="internet_bulk_services" id="internet_bulk_services" value=""></td>
                                    <td style="padding-left:30px">Bulk Cost Base</td>
                                    <td style="padding-left:20px"><input type="text" name="internet_bulk_cost" id="internet_bulk_cost" value=""></td>
                                </tr>
                                <tr>
                                    <td>Bulk MRR</td>
                                    <td><input type="text" name="internet_bulk_mmr" id="internet_bulk_mmr" value=""></td>
                                    <td style="padding-left:30px">Retail Cost Base</td>
                                    <td style="padding-left:20px"><input type="text" name="internet_retail_cost" id="internet_retail_cost" value=""></td>
                                </tr>
                                <tr>
                                    <td>Retail MRR</td>
                                    <td><input type="text" name="internet_retail_mmr" id="internet_retail_mmr" value=""></td>
                                    <td style="padding-left:30px">Projected Penetration</td>
                                    <td style="padding-left:20px"><input type="text" name="internet_penetration" id="internet_penetration" value=""></td>
                                </tr>
                                <tr>
                                    <td>Total MRR</td>
                                    <td><input type="text" name="internet_total_mmr" id="internet_total_mmr" value=""></td>
                                    <td style="padding-left:30px">Net Bulk</td>
                                    <td style="padding-left:20px"><input type="text" name="internet_net_bulk" id="internet_net_bulk" value=""></td>
                                </tr>
                                <tr>
                                    <td>Net Retail</td>
                                    <td><input type="text" name="internet_net_retail" id="internet_net_retail" value=""></td>
                                    <td style="padding-left:30px">Total Profit</td>
                                    <td style="padding-left:20px"><input type="text" name="internet_total_profit" id="internet_total_profit" value=""></td>
                                </tr>
                                <tr><td colspan="4"><h3>Phone</h3></td></tr>
                                <tr>
                                    <td>Bulk Services</td>
                                    <td><input type="text" name="phone_bulk_services" id="phone_bulk_services" value=""></td>
                                    <td style="padding-left:30px">Bulk Cost Base</td>
                                    <td style="padding-left:20px"><input type="text" name="phone_bulk_cost" id="phone_bulk_cost" value=""></td>
                                </tr>
                                <tr>
                                    <td>Bulk MRR</td>
                                    <td><input type="text" name="phone_bulk_mmr" id="phone_bulk_mmr" value=""></td>
                                    <td style="padding-left:30px">Retail Cost Base</td>
                                    <td style="padding-left:20px"><input type="text" name="phone_retail_cost" id="phone_retail_cost" value=""></td>
                                </tr>
                                <tr>
                                    <td>Retail MRR</td>
                                    <td><input type="text" name="phone_retail_mmr" id="phone_retail_mmr" value=""></td>
                                    <td style="padding-left:30px">Projected Penetration</td>
                                    <td style="padding-left:20px"><input type="text" name="phone_penetration" id="phone_penetration" value=""></td>
                                </tr>
                                <tr>
                                    <td>Total MRR</td>
                                    <td><input type="text" name="phone_total_mmr" id="phone_total_mmr" value=""></td>
                                    <td style="padding-left:30px">Net Bulk</td>
                                    <td style="padding-left:20px"><input type="text" name="phone_net_bulk" id="phone_net_bulk" value=""></td>
                                </tr>
                                <tr>
                                    <td>Net Retail</td>
                                    <td><input type="text" name="phone_net_retail" id="phone_net_retail" value=""></td>
                                    <td style="padding-left:30px">Total Profit</td>
                                    <td style="padding-left:20px"><input type="text" name="phone_total_profit" id="phone_total_profit" value=""></td>
                                </tr>
                                <tr><td colspan="4"><h3>Alarm</h3></td></tr>
                                <tr>
                                    <td>Bulk Services</td>
                                    <td><input type="text" name="alarm_bulk_services" id="alarm_bulk_services" value=""></td>
                                    <td style="padding-left:30px">Bulk Cost Base</td>
                                    <td style="padding-left:20px"><input type="text" name="alarm_bulk_cost" id="alarm_bulk_cost" value=""></td>
                                </tr>
                                <tr>
                                    <td>Bulk MRR</td>
                                    <td><input type="text" name="alarm_bulk_mmr" id="alarm_bulk_mmr" value=""></td>
                                    <td style="padding-left:30px">Retail Cost Base</td>
                                    <td style="padding-left:20px"><input type="text" name="alarm_retail_cost" id="alarm_retail_cost" value=""></td>
                                </tr>
                                <tr>
                                    <td>Retail MRR</td>
                                    <td><input type="text" name="alarm_retail_mmr" id="alarm_retail_mmr" value=""></td>
                                    <td style="padding-left:30px">Projected Penetration</td>
                                    <td style="padding-left:20px"><input type="text" name="alarm_penetration" id="alarm_penetration" value=""></td>
                                </tr>
                                <tr>
                                    <td>Total MRR</td>
                                    <td><input type="text" name="alarm_total_mmr" id="alarm_total_mmr" value=""></td>
                                    <td style="padding-left:30px">Net Bulk</td>
                                    <td style="padding-left:20px"><input type="text" name="alarm_net_bulk" id="alarm_net_bulk" value=""></td>
                                </tr>
                                <tr>
                                    <td>Net Retail</td>
                                    <td><input type="text" name="alarm_net_retail" id="alarm_net_retail" value=""></td>
                                    <td style="padding-left:30px">Total Profit</td>
                                    <td style="padding-left:20px"><input type="text" name="alarm_total_profit" id="alarm_total_profit" value=""></td>
                                </tr>
                                <tr><td colspan="4"><h3>Construction Analysis</h3></td></tr>
                                <tr>
                                    <td colspan="2">Construction Cost Per Unit</td>
                                    <td colspan="2"><input type="text" name="const_unit" id="const_unit" value=""></td>
                                </tr>
                                <tr><td colspan="4"><h3>Overall Assessment</h3></td></tr>
                                <tr>
                                    <td colspan="2"><strong>Qualifyers</strong></td>
                                    <td><strong>Calculations</strong></td>
                                    <td><strong>Results</strong></td>
                                </tr>
                                <tr>
                                    <td colspan="2">Bulk Margin:</td>
                                    <td><input type="text" name="bulk_cal" id="bulk_cal" value=""></td>
                                    <td><input type="text" name="bulk_res" id="bulk_res" value=""></td>
                                </tr>
                                <tr>
                                    <td colspan="2">Blended Margin:</td>
                                    <td><input type="text" name="blended_cal" id="blended_cal" value=""></td>
                                    <td><input type="text" name="blended_res" id="blended_res" value=""></td>
                                </tr>
                                <tr>
                                    <td colspan="2">ROI Calculation (Bulk Only):</td>
                                    <td><input type="text" name="roi_cal" id="roi_cal" value=""></td>
                                    <td><input type="text" name="roi_res" id="roi_res" value=""></td>
                                </tr>
                                <tr>
                                    <td colspan="2">ROI Calculation (Blended):</td>
                                    <td><input type="text" name="roi_blended" id="roi_blended" value=""></td>
                                    <td><input type="text" name="roi_res" id="roi_res" value=""></td>
                                </tr>
                                <tr>
                                    <td colspan="2">CapX ROI w/ Key Money (Bulk):</td>
                                    <td><input type="text" name="roi_money" id="roi_money" value=""></td>
                                    <td><input type="text" name="roi_money_res" id="roi_money_res" value=""></td>
                                </tr>
                                <tr>
                                    <td colspan="2">CapX ROI w/ Key Money (Blended):</td>
                                    <td><input type="text" name="roi_key" id="roi_key" value=""></td>
                                    <td><input type="text" name="roi_key_res" id="roi_key_res" value=""></td>
                                </tr>
                                <tr><td colspan="4"><h3>Overall Score</h3></td></tr>
                                <tr><td colspan="4"><input type="text" name="overall_score" id="overall_score" value=""></td></tr>
                            </tbody>
                        </table>
                    </div>
                </div>
            </div>
        </form>
    </div>
</div>
<?php $this->renderpartial('customfooter');?>