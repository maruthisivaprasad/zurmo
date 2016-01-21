<?php
    /*********************************************************************************
     * Zurmo is a customer relationship management program developed by
     * Zurmo, Inc. Copyright (C) 2014 Zurmo Inc.
     *
     * Zurmo is free software; you can redistribute it and/or modify it under
     * the terms of the GNU Affero General Public License version 3 as published by the
     * Free Software Foundation with the addition of the following permission added
     * to Section 15 as permitted in Section 7(a): FOR ANY PART OF THE COVERED WORK
     * IN WHICH THE COPYRIGHT IS OWNED BY ZURMO, ZURMO DISCLAIMS THE WARRANTY
     * OF NON INFRINGEMENT OF THIRD PARTY RIGHTS.
     *
     * Zurmo is distributed in the hope that it will be useful, but WITHOUT
     * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
     * FOR A PARTICULAR PURPOSE.  See the GNU Affero General Public License for more
     * details.
     *
     * You should have received a copy of the GNU Affero General Public License along with
     * this program; if not, see http://www.gnu.org/licenses or write to the Free
     * Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA
     * 02110-1301 USA.
     *
     * You can contact Zurmo, Inc. with a mailing address at 27 North Wacker Drive
     * Suite 370 Chicago, IL 60606. or at email address contact@zurmo.com.
     *
     * The interactive user interfaces in original and modified versions
     * of this program must display Appropriate Legal Notices, as required under
     * Section 5 of the GNU Affero General Public License version 3.
     *
     * In accordance with Section 7(b) of the GNU Affero General Public License version 3,
     * these Appropriate Legal Notices must retain the display of the Zurmo
     * logo and Zurmo copyright notice. If the display of the logo is not reasonably
     * feasible for technical reasons, the Appropriate Legal Notices must display the words
     * "Copyright Zurmo Inc. 2014. All rights reserved".
     ********************************************************************************/

    class ValidationsDefaultController extends ZurmoModuleController
    {
        public function actionCreate()
        {
            $rec_a['unitscstmcstm'] = $rec_t['value'] = $rec_c['value'] = 0;
            $sql = "select * from contract where id=".$_REQUEST['id'];
            $rec = Yii::app()->db->createCommand($sql)->queryRow();
            if(isset($rec['doorfeecstmcstm_currencyvalue_id']) && !empty($rec['doorfeecstmcstm_currencyvalue_id'])) {
                $sql_t = "select * from currencyvalue where id=".$rec['doorfeecstmcstm_currencyvalue_id'];
                $rec_t = Yii::app()->db->createCommand($sql_t)->queryRow();
            }
            if(isset($rec['amount_currencyvalue_id']) && !empty($rec['amount_currencyvalue_id'])) {
                $sql_c = "select * from currencyvalue where id=".$rec['amount_currencyvalue_id'];
                $rec_c = Yii::app()->db->createCommand($sql_c)->queryRow();
            }
            if(isset($rec['account_id']) && !empty($rec['account_id'])) {
                $sql_a = "select * from account where id=".$rec['account_id'];
                $rec_a = Yii::app()->db->createCommand($sql_a)->queryRow();
            }
            $result = array('nounits'=>$rec_a['unitscstmcstm'], 'doorfee'=>$rec_t['value'], 'totalkey'=>$rec_c['value']);
            $this->render('detailviewgrid',array('result'=>$result));
        }
    }
?>