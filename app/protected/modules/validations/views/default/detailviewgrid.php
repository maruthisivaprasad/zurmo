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
                                    <td>Validation</td>
                                    <td><input type="text" name="unit" id="unit" value=""></td>
                                </tr>
                            </tbody>
                        </table>
                    </div>
                </div>
            </div>
            <div class="float-bar">
                <div class="view-toolbar-container clearfix dock">
                    <div class="form-toolbar"><a id="saveyt2" name="save" class="attachLoading z-button" onclick="jQuery.yii.submitForm(this, &#039;&#039;, {&#039;save&#039;:&#039;save&#039;}); return false;" href="#">
                            <span class="z-spinner"></span><span class="z-icon"></span>
                            <span class="z-label">Save</span></a>
                        <a id="CancelLinkActionElement--30-yt3" class="cancel-button" href="<?php echo Yii::app()->request->baseUrl;?>/index.php/opportunities/default"><span class="z-label">Cancel</span></a>
                    </div>
                </div>
            </div>
        </form>
    </div>
</div>
<?php $this->renderpartial('customfooter');?>