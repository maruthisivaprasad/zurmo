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

    Yii::import('application.modules.Contracts.controllers.DefaultController', true);
    Yii::import('application.modules.designer.tests.unit.DesignerTestHelper', true);
    class ContractsDemoController extends ContractsDefaultController
    {
        public function actionCreateCustomFieldsForContractsModule()
        {
            if (!Group::isUserASuperAdministrator(Yii::app()->user->userModel))
            {
                throw new NotSupportedException();
            }
            DesignerTestHelper::createCheckBoxAttribute           ('checkBox', false, 'Contract');
            DesignerTestHelper::createDateTimeAttribute           ('dateTime', false, 'Contract');
            DesignerTestHelper::createIntegerAttribute            ('integers', false, 'Contract');
            DesignerTestHelper::createMultiSelectDropDownAttribute('multiSelectDropDown', false, 'Contract');
            DesignerTestHelper::createTagCloudAttribute           ('tagCloud', false, 'Contract');
            DesignerTestHelper::createPhoneAttribute              ('phone', false, 'Contract');
            DesignerTestHelper::createRadioDropDownAttribute      ('radioDropDown', false, 'Contract');
            DesignerTestHelper::createUrlAttribute                ('url', false, 'Contract');
        }

        //Load Contract for functional testing of mass delete
        public function actionLoadContractsSampler()
        {
            if (!Group::isUserASuperAdministrator(Yii::app()->user->userModel))
            {
                throw new NotSupportedException();
            }

            for ($i = 0; $i < 11; $i++)
            {
                $owner                      = Yii::app()->user->userModel;
                $name                       = 'Mass Delete '. $i;
                $currencies                 = Currency::getAll();
                $currencyValue              = new CurrencyValue();
                $currencyValue->value       = 500.54;
                $currencyValue->currency    = $currencies[0];
                $contract                   = new Contract();
                $contract->owner         = $owner;
                $contract->name          = $name;
                $contract->amount        = $currencyValue;
                $contract->closeDate     = '2011-01-01'; //eventually fix to make correct format
                $contract->stage->value  = 'Negotiating';
                $saved                      = $contract->save();
                if (!$saved)
                {
                    throw new NotSupportedException();
                }
            }
        }
    }
?>
