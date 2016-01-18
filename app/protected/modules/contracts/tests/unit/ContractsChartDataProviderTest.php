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

    class ContractsChartDataProviderTest extends ZurmoBaseTest
    {
        public static function setUpBeforeClass()
        {
            parent::setUpBeforeClass();
            SecurityTestHelper::createSuperAdmin();
            $super = User::getByUsername('super');
            Yii::app()->user->userModel = $super;
            UserTestHelper::createBasicUser('jim');
            AllPermissionsOptimizationUtil::rebuild();
            ContractTestHelper::createContractStagesIfDoesNotExist();
            ContractTestHelper::createContractSourcesIfDoesNotExist();
            $currencies    = Currency::getAll();
            //Make Contracts for testing chart data.
            $currencyValue = new CurrencyValue();
            $currencyValue->value = 200;
            $currencyValue->currency = $currencies[0];
            $contract = new Contract();
            $contract->owner          = $super;
            $contract->name           = 'abc1';
            $contract->amount         = $currencyValue;
            $contract->closeDate      = '2011-01-01';
            $contract->stage->value   = 'Negotiating';
            $contract->source->value  = 'Outbound';
            assert($contract->save()); // Not Coding Standard
            $currencyValue = new CurrencyValue();
            $currencyValue->value = 350;
            $currencyValue->currency = $currencies[0];
            $contract = new Contract();
            $contract->owner          = $super;
            $contract->name           = 'abc2';
            $contract->amount         = $currencyValue;
            $contract->closeDate      = '2011-01-01';
            $contract->stage->value   = 'Negotiating';
            $contract->source->value  = 'Trade Show';
            assert($contract->save()); // Not Coding Standard
            $currencyValue = new CurrencyValue();
            $currencyValue->value = 100;
            $currencyValue->currency = $currencies[0];
            $contract = new Contract();
            $contract->owner          = $super;
            $contract->name           = 'abc2';
            $contract->amount         = $currencyValue;
            $contract->closeDate      = '2011-01-01';
            $contract->stage->value   = 'Verbal';
            $contract->source->value  = 'Trade Show';
            assert($contract->save()); // Not Coding Standard
        }

        public function setUp()
        {
            parent::setUp();
            Yii::app()->user->userModel = User::getByUsername('super');
        }

        public function testGetChartData()
        {
            $chartDataProvider     = ChartDataProviderFactory::createByType('ContractsByStage');
            $chartData             = $chartDataProvider->getChartData();
            $compareData           = array( array('value' => 550, 'displayLabel' => 'Negotiating'),
                                            array('value' => 100, 'displayLabel' => 'Verbal'));
            $this->assertEquals($compareData, $chartData);

            $chartDataProvider     = ChartDataProviderFactory::createByType('ContractsBySource');
            $chartData             = $chartDataProvider->getChartData();
            $compareData           = array( array('value' => 200, 'displayLabel' => 'Outbound'),
                                            array('value' => 450, 'displayLabel' => 'Trade Show'));
            $this->assertEquals($compareData, $chartData);
        }

        /**
         * @depends testGetChartData
         */
        public function testGetChartDataUsingReadOptimization()
        {
            $jim                        = User::getByUsername('jim');
            Yii::app()->user->userModel = $jim;
            $chartDataProvider     = ChartDataProviderFactory::createByType('ContractsByStage');
            $chartData             = $chartDataProvider->getChartData();
            $this->assertEquals(array(), $chartData);

            $chartDataProvider     = ChartDataProviderFactory::createByType('ContractsBySource');
            $chartData             = $chartDataProvider->getChartData();
            $this->assertEquals(array(), $chartData);
        }

        /**
         * @depends testGetChartDataUsingReadOptimization
         */
        public function testGetChartDataConvertedToNewCurrency()
        {
            $super = User::getByUsername('super');
            Yii::app()->user->userModel = $super;
            $this->assertNull($super->currency->code);

            //Make a new currency and assign to the current user.
            $currency             = new Currency();
            $currency->code       =  'EUR';
            $currency->rateToBase = .5; //I wish...
            $this->assertTrue($currency->save());
            $super->currency = $currency;
            $this->assertTrue($super->save());

            $chartDataProvider     = ChartDataProviderFactory::createByType('ContractsByStage');
            $chartData             = $chartDataProvider->getChartData();
            $compareData           = array( array('value' => 1100, 'displayLabel' => 'Negotiating'),
                                            array('value' => 200, 'displayLabel' => 'Verbal'));
            $this->assertEquals($compareData, $chartData);

            $chartDataProvider     = ChartDataProviderFactory::createByType('ContractsBySource');
            $chartData             = $chartDataProvider->getChartData();
            $compareData           = array( array('value' => 400, 'displayLabel' => 'Outbound'),
                                            array('value' => 900, 'displayLabel' => 'Trade Show'));
            $this->assertEquals($compareData, $chartData);
        }
    }
?>
