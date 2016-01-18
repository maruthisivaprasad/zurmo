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

    class ContractTest extends ZurmoBaseTest
    {
        public static function setUpBeforeClass()
        {
            parent::setUpBeforeClass();
            SecurityTestHelper::createSuperAdmin();
        }

        public function testCreateStageValues()
        {
            $stageValues = array(
                'Prospecting',
                'Negotiating',
                'Closed Won',
            );
            $stageFieldData = CustomFieldData::getByName('SalesStages');
            $stageFieldData->serializedData = serialize($stageValues);
            $this->assertTrue($stageFieldData->save());
        }

        /**
         * @depends testCreateStageValues
         */
        public function testGetStageToProbabilityMappingData()
        {
            $this->assertEquals(6, count(ContractsModule::getStageToProbabilityMappingData()));
        }

        /**
         * @depends testGetStageToProbabilityMappingData
         */
        public function testGetProbabilityByStageValue()
        {
            $this->assertEquals(10,  ContractsModule::getProbabilityByStageValue ('Prospecting'));
            $this->assertEquals(50,  ContractsModule::getProbabilityByStageValue ('Negotiating'));
            $this->assertEquals(100, ContractsModule::getProbabilityByStageValue ('Closed Won'));
        }

        /**
         * @depends testCreateStageValues
         */
        public function testVariousCurrencyValues()
        {
            $super                      = User::getByUsername('super');
            Yii::app()->user->userModel = $super;
            $currencies                 = Currency::getAll();
            $currencyValue              = new CurrencyValue();
            $currencyValue->value       = 100;
            $currencyValue->currency    = $currencies[0];
            $this->assertEquals('USD', $currencyValue->currency->code);
            $contract = new Contract();
            $contract->owner          = $super;
            $contract->name           = 'test';
            $contract->amount         = $currencyValue;
            $contract->closeDate      = '2011-01-01';
            $contract->stage->value   = 'Verbal';
            $this->assertEquals(0, $contract->probability);
            $saved                       = $contract->save();
            $this->assertTrue($saved);
            $this->assertEquals(75, $contract->probability);
            $contract1Id              = $contract->id;
            $contract->forget();

            $currencyValue              = new CurrencyValue();
            $currencyValue->value       = 800;
            $currencyValue->currency    = $currencies[0];
            $this->assertEquals('USD', $currencyValue->currency->code);
            $contract = new Contract();
            $contract->owner          = $super;
            $contract->name           = 'test';
            $contract->amount         = $currencyValue;
            $contract->closeDate      = '2011-01-01';
            $contract->stage->value   = 'Verbal';
            $saved                       = $contract->save();
            $this->assertTrue($saved);
            $contract2Id              = $contract->id;
            $contract->forget();
            $currencyValue->forget(); //need to forget this to pull the accurate value from the database

            $contract1 = Contract::getById($contract1Id);
            $this->assertEquals(100, $contract1->amount->value);

            $contract2 = Contract::getById($contract2Id);
            $this->assertEquals(800, $contract2->amount->value);

            $contract1->delete();
            $contract2->delete();
        }

        /**
         * @depends testVariousCurrencyValues
         */
        public function testCreateAndGetContractById()
        {
            Yii::app()->user->userModel = User::getByUsername('super');

            $user = UserTestHelper::createBasicUser('Billy');
            $currencies    = Currency::getAll();
            $currencyValue = new CurrencyValue();
            $currencyValue->value = 500.54;
            $currencyValue->currency = $currencies[0];
            $contract = new Contract();
            $contract->owner        = $user;
            $contract->name         = 'Test Contract';
            $contract->amount       = $currencyValue;
            $contract->closeDate    = '2011-01-01'; //eventually fix to make correct format
            $contract->stage->value = 'Negotiating';
            $this->assertTrue($contract->save());
            $id = $contract->id;
            unset($contract);
            $contract = Contract::getById($id);
            $this->assertEquals('Test Contract', $contract->name);
            $this->assertEquals('500.54',      $contract->amount->value);
            $this->assertEquals('Negotiating', $contract->stage->value);
            $this->assertEquals('2011-01-01',    $contract->closeDate);
            $this->assertEquals(1, $currencies[0]->rateToBase);
        }

        /**
         * @depends testCreateAndGetcontractById
         */
        public function testGetContractsByName()
        {
            Yii::app()->user->userModel = User::getByUsername('super');

            $contracts = Contract::getByName('Test Contract');
            $this->assertEquals(1, count($contracts));
            $this->assertEquals('Test Contract', $contracts[0]->name);
        }

        /**
         * @depends testCreateAndGetcontractById
         */
        public function testGetLabel()
        {
            Yii::app()->user->userModel = User::getByUsername('super');
            $contracts = Contract::getByName('Test Contract');
            $this->assertEquals(1, count($contracts));
            $this->assertEquals('Contract',   $contracts[0]::getModelLabelByTypeAndLanguage('Singular'));
            $this->assertEquals('Contracts', $contracts[0]::getModelLabelByTypeAndLanguage('Plural'));
        }

        /**
         * @depends testGetcontractsByName
         */
        public function testGetContractsByNameForNonExistentName()
        {
            Yii::app()->user->userModel = User::getByUsername('super');
            $contracts = Contract::getByName('Test Contract 69');
            $this->assertEquals(0, count($contracts));
        }

        /**
         * @depends testCreateAndGetContractById
         */
        public function testGetAll()
        {
            Yii::app()->user->userModel = User::getByUsername('super');

            $user = User::getByUsername('billy');
            $currencies    = Currency::getAll();
            $currencyValue = new CurrencyValue();
            $currencyValue->value = 500.54;
            $currencyValue->currency = $currencies[0];
            $contract = new Contract();
            $contract->owner        = $user;
            $contract->name         = 'Test Contract 2';
            $contract->amount       = $currencyValue;
            $contract->closeDate    = '2011-01-01'; //eventually fix to make correct format
            $contract->stage->value = 'Negotiating';
            $this->assertTrue($contract->save());
            $contracts = Contract::getAll();
            $this->assertEquals(2, count($contracts));
            $this->assertTrue('Test Contract'   == $contracts[0]->name &&
                              'Test Contract 2' == $contracts[1]->name ||
                              'Test Contract 2' == $contracts[0]->name &&
                              'Test Contract'   == $contracts[1]->name);
            $this->assertEquals(1, $currencies[0]->rateToBase);
        }

        /**
         * @depends testCreateAndGetcontractById
         */
        public function testSetAndGetOwner()
        {
            Yii::app()->user->userModel = User::getByUsername('super');

            $user = UserTestHelper::createBasicUser('Dicky');

            $contracts = Contract::getByName('Test Contract');
            $this->assertEquals(1, count($contracts));
            $contract = $contracts[0];
            $contract->owner = $user;
            $this->assertTrue($contract->save());
            unset($user);
            $this->assertTrue($contract->owner !== null);
            $contract->owner = null;
            $this->assertFalse($contract->validate());
            $contract->forget();
            unset($contract);
        }

        /**
         * @depends testSetAndGetOwner
         */
        public function testReplaceOwner()
        {
            Yii::app()->user->userModel = User::getByUsername('super');

            $contracts = Contract::getByName('Test Contract');
            $this->assertEquals(1, count($contracts));
            $contract = $contracts[0];
            $user = User::getByUsername('dicky');
            $this->assertEquals($user->id, $contract->owner->id);
            unset($user);
            $user2 = UserTestHelper::createBasicUser('Benny');
            $contract->owner = $user2;
            unset($user2);
            $this->assertTrue($contract->owner !== null);
            $user = $contract->owner;
            $this->assertEquals('benny', $user->username);
            unset($user);
        }

        /**
         * @depends testCreateAndGetcontractById
         */
        public function testUpdateContractFromForm()
        {
            Yii::app()->user->userModel = User::getByUsername('super');

            $user = User::getByUsername('billy');
            $contracts = Contract::getByName('Test contract');
            $contract = $contracts[0];
            $this->assertEquals($contract->name, 'Test Contract');
            $currencies    = Currency::getAll();
            $postData = array(
                'owner' => array(
                    'id' => $user->id,
                ),
                'name' => 'New Name',
                'amount' => array('value' => '500.54', 'currency' => array('id' => $currencies[0]->id)),
                'closeDate' => '2011-01-01',
                'stage' => array(
                    'value' => 'Negotiating'
                ),
            );
            $contract->setAttributes($postData);
            $this->assertTrue($contract->save());

            $id = $contract->id;
            unset($contract);
            $contract = Contract::getById($id);
            $this->assertEquals('New Name', $contract->name);
            $this->assertEquals(500.54,     $contract->amount->value);
            $this->assertEquals(50,         $contract->probability);
            $this->assertEquals(1, $currencies[0]->rateToBase);

            //Updating probability mapping should make changes on saving contract
            $metadata = ContractsModule::getMetadata();
            $metadata['global']['stageToProbabilityMapping']['Negotiating'] = 60;
            ContractsModule::setMetadata($metadata);
            $postData = array();
            $contract->setAttributes($postData);
            $this->assertTrue($contract->save());
            unset($contract);
            $contract = Contract::getById($id);
            $this->assertEquals('New Name', $contract->name);
            $this->assertEquals(500.54,     $contract->amount->value);
            $this->assertEquals(60,         $contract->probability);
            $this->assertEquals(1, $currencies[0]->rateToBase);
        }

        public function testDeleteContract()
        {
            Yii::app()->user->userModel = User::getByUsername('super');

            $contracts = Contract::getAll();
            $this->assertEquals(2, count($contracts));
            $contracts[0]->delete();
            $contracts = Contract::getAll();
            $this->assertEquals(1, count($contracts));
            $contracts[0]->delete();
            $contracts = Contract::getAll();
            $this->assertEquals(0, count($contracts));
            $currencies    = Currency::getAll();
            $this->assertEquals(1, $currencies[0]->rateToBase);
        }

        public function testGetAllWhenThereAreNone()
        {
            Yii::app()->user->userModel = User::getByUsername('super');
            $contracts = Contract::getAll();
            $this->assertEquals(0, count($contracts));
        }

        /**
         * @depends testCreateAndGetContractById
         */
        public function testSetStageAndSourceAndRetrieveDisplayName()
        {
            Yii::app()->user->userModel = User::getByUsername('super');

            $user = User::getByUsername('billy');

            $stageValues = array(
                'Prospecting',
                'Negotiating',
                'Closed Won',
            );
            $stageFieldData = CustomFieldData::getByName('SalesStages');
            $stageFieldData->serializedData = serialize($stageValues);
            $this->assertTrue($stageFieldData->save());

            $sourceValues = array(
                'Word of Mouth',
                'Outbound',
                'Trade Show',
            );
            $sourceFieldData = CustomFieldData::getByName('LeadSources');
            $sourceFieldData->serializedData = serialize($sourceValues);
            $this->assertTrue($sourceFieldData->save());

            $currencies    = Currency::getAll();
            $currencyValue = new CurrencyValue();
            $currencyValue->value = 500.54;
            $currencyValue->currency = $currencies[0];
            $contract = new Contract();
            $contract->owner        = $user;
            $contract->name         = '1000 Widgets';
            $contract->amount       = $currencyValue;
            $contract->closeDate    = '2011-01-01'; //eventually fix to make correct format
            $contract->stage->value = $stageValues[1];
            $contract->source->value = $sourceValues[1];
            $saved = $contract->save();
            $this->assertTrue($saved);
            $this->assertTrue($contract->id !== null);
            $id = $contract->id;
            unset($contract);
            $contract = Contract::getById($id);
            $this->assertEquals('Negotiating', $contract->stage->value);
            $this->assertEquals('Outbound', $contract->source->value);
            $this->assertEquals(1, $currencies[0]->rateToBase);
        }

        public function testGetModelClassNames()
        {
            $modelClassNames = ContractsModule::getModelClassNames();
            $this->assertEquals(2, count($modelClassNames));
            $this->assertEquals('Contract', $modelClassNames[0]);
            $this->assertEquals('ContractStarred', $modelClassNames[1]);
        }
    }
?>
