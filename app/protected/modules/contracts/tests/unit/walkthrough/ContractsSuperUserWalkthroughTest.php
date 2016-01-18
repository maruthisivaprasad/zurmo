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

    /**
     * contracts Module Walkthrough.
     * Walkthrough for the super user of all possible controller actions.
     * Since this is a super user, he should have access to all controller actions
     * without any exceptions being thrown.
     */
    class contractsSuperUserWalkthroughTest extends ZurmoWalkthroughBaseTest
    {
        public static function setUpBeforeClass()
        {
            parent::setUpBeforeClass();
            SecurityTestHelper::createSuperAdmin();
            $super = User::getByUsername('super');
            Yii::app()->user->userModel = $super;

            //Setup test data owned by the super user.
            $account = AccountTestHelper::createAccountByNameForOwner        ('superAccount',  $super);
            AccountTestHelper::createAccountByNameForOwner                   ('superAccount2', $super);
            ContactTestHelper::createContactWithAccountByNameForOwner        ('superContact',  $super, $account);
            ContactTestHelper::createContactWithAccountByNameForOwner        ('superContact2', $super, $account);
            ContractTestHelper::createContractStagesIfDoesNotExist     ();
            ContractTestHelper::createContractWithAccountByNameForOwner('superOpp',      $super, $account);
            ContractTestHelper::createContractWithAccountByNameForOwner('superOpp2',     $super, $account);
            ContractTestHelper::createContractWithAccountByNameForOwner('superOpp3',     $super, $account);
            ContractTestHelper::createContractWithAccountByNameForOwner('superOpp4',     $super, $account);
            ContractTestHelper::createContractWithAccountByNameForOwner('superOpp5',     $super, $account);
            ContractTestHelper::createContractWithAccountByNameForOwner('superOpp6',     $super, $account);
            ContractTestHelper::createContractWithAccountByNameForOwner('superOpp7',     $super, $account);
            ContractTestHelper::createContractWithAccountByNameForOwner('superOpp8',     $super, $account);
            ContractTestHelper::createContractWithAccountByNameForOwner('superOpp9',     $super, $account);
            ContractTestHelper::createContractWithAccountByNameForOwner('superOpp10',    $super, $account);
            ContractTestHelper::createContractWithAccountByNameForOwner('superOpp11',    $super, $account);
            ContractTestHelper::createContractWithAccountByNameForOwner('superOpp12',    $super, $account);
            //Setup default dashboard.
            Dashboard::getByLayoutIdAndUser                                  (Dashboard::DEFAULT_USER_LAYOUT_ID, $super);
        }

        public function testSuperUserAllDefaultControllerActions()
        {
            $super = $this->logoutCurrentUserLoginNewUserAndGetByUsername('super');

            //Test all default controller actions that do not require any POST/GET variables to be passed.
            //This does not include portlet controller actions.
            $this->runControllerWithNoExceptionsAndGetContent('contracts/default');
            $this->runControllerWithNoExceptionsAndGetContent('contracts/default/index');
            $this->runControllerWithNoExceptionsAndGetContent('contracts/default/create');

            $content = $this->runControllerWithNoExceptionsAndGetContent('contracts/default/list');
            $this->assertContains('anyMixedAttributes', $content);
            //Test the search or paging of the listview.
            Yii::app()->clientScript->reset(); //to make sure old js doesn't make it to the UI
            $this->setGetArray(array('ajax' => 'list-view'));
            $content = $this->runControllerWithNoExceptionsAndGetContent('contracts/default/list');
            $this->assertNotContains('anyMixedAttributes', $content);
            $this->resetGetArray();

            //Default Controller actions requiring some sort of parameter via POST or GET
            //Load Model Edit Views
            $contracts = Contract::getAll();
            $this->assertEquals(12, count($contracts));
            $superContractId   = self::getModelIdByModelNameAndName('Contract', 'superOpp');
            $superContractId2  = self::getModelIdByModelNameAndName('Contract', 'superOpp2');
            $superContractId3  = self::getModelIdByModelNameAndName('Contract', 'superOpp3');
            $superContractId4  = self::getModelIdByModelNameAndName('Contract', 'superOpp4');
            $superContractId5  = self::getModelIdByModelNameAndName('Contract', 'superOpp5');
            $superContractId6  = self::getModelIdByModelNameAndName('Contract', 'superOpp6');
            $superContractId7  = self::getModelIdByModelNameAndName('Contract', 'superOpp7');
            $superContractId8  = self::getModelIdByModelNameAndName('Contract', 'superOpp8');
            $superContractId9  = self::getModelIdByModelNameAndName('Contract', 'superOpp9');
            $superContractId10 = self::getModelIdByModelNameAndName('Contract', 'superOpp10');
            $superContractId11 = self::getModelIdByModelNameAndName('Contract', 'superOpp11');
            $superContractId12 = self::getModelIdByModelNameAndName('Contract', 'superOpp12');
            $this->setGetArray(array('id' => $superContractId));
            $this->runControllerWithNoExceptionsAndGetContent('contracts/default/edit');
            //Save Contract.
            $superContract = Contract::getById($superContractId);
            $this->assertEquals(null, $superContract->description);
            $this->setPostArray(array('Contract' => array('description' => '456765421')));
            $this->runControllerWithRedirectExceptionAndGetContent('contracts/default/edit');
            $superContract = Contract::getById($superContractId);
            $this->assertEquals('456765421', $superContract->description);
            //Test having a failed validation on the Contract during save.
            $this->setGetArray (array('id'      => $superContractId));
            $this->setPostArray(array('Contract' => array('name' => '')));
            $content = $this->runControllerWithNoExceptionsAndGetContent('contracts/default/edit');
            $this->assertContains('Name cannot be blank', $content);

            //Load Model Detail Views
            $this->setGetArray(array('id' => $superContractId));
            $this->resetPostArray();
            $this->runControllerWithNoExceptionsAndGetContent('contracts/default/details');

            //Load Model MassEdit Views.
            //MassEdit view for single selected ids
            $this->setGetArray(array('selectedIds' => '4,5,6,7,8,9', 'selectAll' => '')); // Not Coding Standard
            $this->resetPostArray();
            $content = $this->runControllerWithNoExceptionsAndGetContent('contracts/default/massEdit');
            $this->assertContains('<strong>6</strong>&#160;records selected for updating', $content);

            //MassEdit view for all result selected ids
            $this->setGetArray(array('selectAll' => '1'));
            $this->resetPostArray();
            $content = $this->runControllerWithNoExceptionsAndGetContent('contracts/default/massEdit');
            $this->assertContains('<strong>12</strong>&#160;records selected for updating', $content);

            //save Model MassEdit for selected Ids
            //Test that the 2 contacts do not have the office phone number we are populating them with.
            $contract1 = Contract::getById($superContractId);
            $contract2 = Contract::getById($superContractId2);
            $contract3 = Contract::getById($superContractId3);
            $contract4 = Contract::getById($superContractId4);
            $this->assertNotEquals('7788', $contract1->description);
            $this->assertNotEquals('7788', $contract2->description);
            $this->assertNotEquals('7788', $contract3->description);
            $this->assertNotEquals('7788', $contract4->description);
            $this->setGetArray(array(
                'selectedIds' => $superContractId . ',' . $superContractId2, // Not Coding Standard
                'selectAll' => '',
                'Contract_page' => 1));
            $this->setPostArray(array(
                'Contract'  => array('description' => '7788'),
                'MassEdit' => array('description' => 1)
            ));
            $pageSize = Yii::app()->pagination->getForCurrentUserByType('massEditProgressPageSize');
            $this->assertEquals(5, $pageSize);
            Yii::app()->pagination->setForCurrentUserByType('massEditProgressPageSize', 20);
            $this->runControllerWithRedirectExceptionAndGetContent('contracts/default/massEdit');
            Yii::app()->pagination->setForCurrentUserByType('massEditProgressPageSize', $pageSize);
            //Test that the 2 contract have the new office phone number and the other contacts do not.
            $contract1  = Contract::getById($superContractId);
            $contract2  = Contract::getById($superContractId2);
            $contract3  = Contract::getById($superContractId3);
            $contract4  = Contract::getById($superContractId4);
            $contract5  = Contract::getById($superContractId5);
            $contract6  = Contract::getById($superContractId6);
            $contract7  = Contract::getById($superContractId7);
            $contract8  = Contract::getById($superContractId8);
            $contract9  = Contract::getById($superContractId9);
            $contract10 = Contract::getById($superContractId10);
            $contract11 = Contract::getById($superContractId11);
            $contract12 = Contract::getById($superContractId12);
            $this->assertEquals('7788', $contract1->description);
            $this->assertEquals('7788', $contract2->description);
            $this->assertNotEquals('7788', $contract3->description);
            $this->assertNotEquals('7788', $contract4->description);
            $this->assertNotEquals('7788', $contract5->description);
            $this->assertNotEquals('7788', $contract6->description);
            $this->assertNotEquals('7788', $contract7->description);
            $this->assertNotEquals('7788', $contract8->description);
            $this->assertNotEquals('7788', $contract9->description);
            $this->assertNotEquals('7788', $contract10->description);
            $this->assertNotEquals('7788', $contract11->description);
            $this->assertNotEquals('7788', $contract12->description);

            //save Model MassEdit for entire search result
            $this->setGetArray(array(
                'selectAll' => '1',
                'Contract_page' => 1));
            $this->setPostArray(array(
                'Contract'  => array('description' => '6654'),
                'MassEdit' => array('description' => 1)
            ));
            $pageSize = Yii::app()->pagination->getForCurrentUserByType('massEditProgressPageSize');
            $this->assertEquals(5, $pageSize);
            Yii::app()->pagination->setForCurrentUserByType('massEditProgressPageSize', 20);
            $this->runControllerWithRedirectExceptionAndGetContent('contracts/default/massEdit');
            Yii::app()->pagination->setForCurrentUserByType('massEditProgressPageSize', $pageSize);
            //Test that all contracts have the new description.
            $contract1 = Contract::getById($superContractId);
            $contract2 = Contract::getById($superContractId2);
            $contract3 = Contract::getById($superContractId3);
            $contract4 = Contract::getById($superContractId4);
            $contract5 = Contract::getById($superContractId5);
            $contract6 = Contract::getById($superContractId6);
            $contract7 = Contract::getById($superContractId7);
            $contract8 = Contract::getById($superContractId8);
            $contract9 = Contract::getById($superContractId9);
            $contract10 = Contract::getById($superContractId10);
            $contract11 = Contract::getById($superContractId11);
            $contract12 = Contract::getById($superContractId12);
            $this->assertEquals('6654', $contract1->description);
            $this->assertEquals('6654', $contract2->description);
            $this->assertEquals('6654', $contract3->description);
            $this->assertEquals('6654', $contract4->description);
            $this->assertEquals('6654', $contract5->description);
            $this->assertEquals('6654', $contract6->description);
            $this->assertEquals('6654', $contract7->description);
            $this->assertEquals('6654', $contract8->description);
            $this->assertEquals('6654', $contract9->description);
            $this->assertEquals('6654', $contract10->description);
            $this->assertEquals('6654', $contract11->description);
            $this->assertEquals('6654', $contract12->description);

            //Run Mass Update using progress save.
            $pageSize = Yii::app()->pagination->getForCurrentUserByType('massEditProgressPageSize');
            $this->assertEquals(5, $pageSize);
            Yii::app()->pagination->setForCurrentUserByType('massEditProgressPageSize', 1);
            //The page size is smaller than the result set, so it should exit.
            $this->runControllerWithExitExceptionAndGetContent('contracts/default/massEdit');
            //save Modal MassEdit using progress load for page 2, 3 and 4.
            $this->setGetArray(array('selectAll' => '1', 'Contract_page' => 2));
            $content = $this->runControllerWithNoExceptionsAndGetContent('contracts/default/massEditProgressSave');
            $this->assertContains('"value":16', $content);
            $this->setGetArray(array('selectAll' => '1', 'Contract_page' => 3));
            $content = $this->runControllerWithNoExceptionsAndGetContent('contracts/default/massEditProgressSave');
            $this->assertContains('"value":25', $content);
            $this->setGetArray(array('selectAll' => '1', 'Contract_page' => 4));
            $content = $this->runControllerWithNoExceptionsAndGetContent('contracts/default/massEditProgressSave');
            $this->assertContains('"value":33', $content);
            //Set page size back to old value.
            Yii::app()->pagination->setForCurrentUserByType('massEditProgressPageSize', $pageSize);

            //save Model MassEdit for selected Ids
            //Test that the 2 contacts do not have the closed date populating them with.
            //Test that closed dates are properly updated
            $contract1 = Contract::getById($superContractId);
            $contract2 = Contract::getById($superContractId2);
            $contract3 = Contract::getById($superContractId3);
            $contract4 = Contract::getById($superContractId4);
            $this->assertNotEquals('2012-12-05', $contract1->closeDate);
            $this->assertNotEquals('2012-12-05', $contract2->closeDate);
            $this->assertNotEquals('2012-12-05', $contract3->closeDate);
            $this->assertNotEquals('2012-12-05', $contract4->closeDate);
            $this->setGetArray(array(
                'selectedIds' => $superContractId . ',' . $superContractId2, // Not Coding Standard
                'selectAll' => '',
                'Contract_page' => 1));
            $this->setPostArray(array(
                'Contract'  => array('closeDate' => '12/5/2012'),
                'MassEdit' => array('closeDate' => 1)
            ));
            $pageSize = Yii::app()->pagination->getForCurrentUserByType('massEditProgressPageSize');
            $this->assertEquals(5, $pageSize);
            Yii::app()->pagination->setForCurrentUserByType('massEditProgressPageSize', 20);
            $content = $this->runControllerWithRedirectExceptionAndGetContent('contracts/default/massEdit');

            $contract1 = Contract::getById($superContractId);
            $contract2 = Contract::getById($superContractId2);
            $contract3 = Contract::getById($superContractId3);
            $contract4 = Contract::getById($superContractId4);
            $this->assertEquals('2012-12-05', $contract1->closeDate);
            $this->assertEquals('2012-12-05', $contract2->closeDate);
            $this->assertNotEquals('2012-12-05', $contract3->closeDate);
            $this->assertNotEquals('2012-12-05', $contract4->closeDate);

            //Autocomplete for Contract
            $this->setGetArray(array('term' => 'super'));
            $this->runControllerWithNoExceptionsAndGetContent('contracts/default/autoComplete');

            //actionModalList
            $this->setGetArray(array(
                'modalTransferInformation' => array('sourceIdFieldId' => 'x', 'sourceNameFieldId' => 'y', 'modalId' => 'z')
            ));
            $this->runControllerWithNoExceptionsAndGetContent('contracts/default/modalList');

            //actionAuditEventsModalList
            $this->setGetArray(array('id' => $superContractId));
            $this->resetPostArray();
            $this->runControllerWithNoExceptionsAndGetContent('contracts/default/auditEventsModalList');

            //Select a related Contract for this contact. Go to the select screen.
            $superContactId     = self::getModelIdByModelNameAndName ('Contact', 'superContact superContactson');
            $contract1->forget();
            $contract= Contract::getById($superContractId);
            $portlets = Portlet::getByLayoutIdAndUserSortedByColumnIdAndPosition(
                                    'ContractDetailsAndRelationsView', $super->id, array());
            $this->assertEquals(2, count($portlets));
            $this->assertEquals(3, count($portlets[1]));
            $contact = Contact::getById($superContactId);
            $this->assertEquals(0, $contact->contracts->count());
            $this->assertEquals(0, $contract->contacts->count());
            $this->setGetArray(array('portletId'             => $portlets[1][1]->id, //Doesnt matter which portlet we are using
                                     'relationAttributeName' => 'contracts',
                                     'relationModuleId'      => 'contracts',
                                     'relationModelId'       => $superContractId,
                                     'uniqueLayoutId'        => 'ContractDetailsAndRelationsView_' .
                                                                $portlets[1][1]->id)
            );

            $this->resetPostArray();
            $this->runControllerWithNoExceptionsAndGetContent('contacts/default/SelectFromRelatedList');
            //Now add an Contract to a contact via the select from related list action.
            $this->setGetArray(array(   'portletId'             => $portlets[1][1]->id,
                                        'modelId'               => $superContactId,
                                        'relationAttributeName' => 'contracts',
                                        'relationModuleId'      => 'contracts',
                                        'relationModelId'       => $superContractId,
                                        'uniqueLayoutId'        => 'ContractDetailsAndRelationsView_' .
                                                                   $portlets[1][1]->id)
            );
            $this->resetPostArray();
            $this->runControllerWithRedirectExceptionAndGetContent('contacts/defaultPortlet/SelectFromRelatedListSave');
            //Run forget in order to refresh the contact and Contract showing the new relation
            $contact->forget();
            $contract->forget();
            $contact     = Contact::getById($superContactId);
            $contract = Contract::getById($superContractId);
            $this->assertEquals(1,                $contract->contacts->count());
            $this->assertEquals($contact,         $contract->contacts[0]);
            $this->assertEquals(1,                $contact->contracts->count());
            $this->assertEquals($contract->id, $contact->contracts[0]->id);
        }

        /**
         * @depends testSuperUserAllDefaultControllerActions
         */
        public function testSuperUserDefaultPortletControllerActions()
        {
            $super = $this->logoutCurrentUserLoginNewUserAndGetByUsername('super');
            $superContractId2 = self::getModelIdByModelNameAndName('Contract', 'superOpp2');
            //Save a layout change. Collapse all portlets in the Contract Details View.
            //At this point portlets for this view should be created because we have
            //already loaded the 'details' page in a request above.
            $portlets = Portlet::getByLayoutIdAndUserSortedByColumnIdAndPosition(
                                    'ContractDetailsAndRelationsView', $super->id, array());
            $this->assertEquals(3, count($portlets[1]));
            $this->assertFalse(array_key_exists(3, $portlets) );
            $portletPostData = array();
            $portletCount = 0;
            foreach ($portlets as $column => $columnPortlets)
            {
                foreach ($columnPortlets as $position => $portlet)
                {
                    $this->assertEquals('0', $portlet->collapsed);
                    $portletPostData['ContractDetailsAndRelationsView_' . $portlet->id] = array(
                        'collapsed' => 'true',
                        'column'    => 0,
                        'id'        => 'ContractDetailsAndRelationsView_' . $portlet->id,
                        'position'  => $portletCount,
                    );
                    $portletCount++;
                }
            }
            //There should have been a total of 3 portlets.
            $this->assertEquals(6, $portletCount);
            $this->resetGetArray();
            $this->setPostArray(array(
                'portletLayoutConfiguration' => array(
                    'portlets' => $portletPostData,
                    'uniqueLayoutId' => 'ContractDetailsAndRelationsView',
                )
            ));
            $this->runControllerWithNoExceptionsAndGetContent('home/defaultPortlet/saveLayout', true);
            //Now test that all the portlets are collapsed and moved to the first column.
            $portlets = Portlet::getByLayoutIdAndUserSortedByColumnIdAndPosition(
                            'ContractDetailsAndRelationsView', $super->id, array());
            $this->assertEquals (6, count($portlets[1]));
            $this->assertFalse  (array_key_exists(2, $portlets) );
            foreach ($portlets as $column => $columns)
            {
                foreach ($columns as $position => $positionPortlets)
                {
                    $this->assertEquals('1', $positionPortlets->collapsed);
                }
            }
            //Load Details View again to make sure everything is ok after the layout change.
            $this->setGetArray(array('id' => $superContractId2));
            $this->resetPostArray();
            $this->runControllerWithNoExceptionsAndGetContent('contracts/default/details');
        }

        /**
         * @depends testSuperUserDefaultPortletControllerActions
         */
        public function testSuperUserDeleteAction()
        {
            $super = $this->logoutCurrentUserLoginNewUserAndGetByUsername('super');
            $superContractId4 = self::getModelIdByModelNameAndName('Contract', 'superOpp4');
            //Delete an Contract.
            $this->setGetArray(array('id' => $superContractId4));
            $this->resetPostArray();
            $this->runControllerWithRedirectExceptionAndGetContent('contracts/default/delete');
            $contracts = Contract::getAll();
            $this->assertEquals(11, count($contracts));
            try
            {
                Contact::getById($superContractId4);
                $this->fail();
            }
            catch (NotFoundException $e)
            {
                //success
            }
        }

        /**
         * @depends testSuperUserDeleteAction
         */
        public function testSuperUserCreateAction()
        {
            $super = $this->logoutCurrentUserLoginNewUserAndGetByUsername('super');
            $currencies    = Currency::getAll();
            //Create a new Contract.
            $this->resetGetArray();
            $this->setPostArray(array('Contract' => array(
                                            'name'        => 'myNewContract',
                                            'description' => '456765421',
                                            'closeDate'   => '11/1/2011',
                                            'amount' => array(  'value' => '545',
                                                                'currency' => array('id' => $currencies[0]->id)),
                                            'stage'       => array('value' => 'Negotiating'))));
            $this->runControllerWithRedirectExceptionAndGetContent('contracts/default/create');
            $contracts = Contract::getByName('myNewContract');
            $this->assertEquals(1, count($contracts));
            $this->assertTrue  ($contracts[0]->id > 0);
            $this->assertTrue  ($ocontracts[0]->owner == $super);
            $this->assertEquals('456765421',   $contracts[0]->description);
            $this->assertEquals('545',         $contracts[0]->amount->value);
            $this->assertEquals('2011-11-01',  $contracts[0]->closeDate);
            $this->assertEquals('Negotiating', $contracts[0]->stage->value);
            $contracts = Contract::getAll();
            $this->assertEquals(12, count($contracts));

            //todo: test save with account.
        }

        /**
         * @depends testSuperUserCreateAction
         */
        public function testSuperUserCreateFromRelationAction()
        {
            $super         = $this->logoutCurrentUserLoginNewUserAndGetByUsername('super');
            $currencies    = Currency::getAll();
            $contracts      = Contract::getAll();
            $this->assertEquals(12, count($contracts));
            $account       = Account::getByName('superAccount2');
            $contact       = Contact::getByName('superContact2 superContact2son');
            $this->assertEquals(1, count($contact));

            //Create a new contact from a related account.
            $this->setGetArray(array(   'relationAttributeName' => 'account',
                                        'relationModelId'       => $account[0]->id,
                                        'relationModuleId'      => 'accounts',
                                        'redirectUrl'           => 'someRedirect'));
            $this->setPostArray(array('Contract' => array(
                                        'name'        => 'myUltraNewContract',
                                        'description' => '456765421',
                                        'closeDate'   => '11/1/2011',
                                        'amount' => array(  'value' => '545',
                                                            'currency' => array('id' => $currencies[0]->id)),
                                        'stage'       => array('value' => 'Negotiating'))));
            $this->runControllerWithRedirectExceptionAndGetContent('contracts/default/createFromRelation');
            $contracts = Contract::getByName('myUltraNewContract');
            $this->assertEquals(1, count($contracts));
            $this->assertTrue($contracts[0]->id > 0);
            $this->assertTrue($contracts[0]->owner   == $super);
            $this->assertTrue($contracts[0]->account == $account[0]);
            $this->assertEquals('456765421',   $contracts[0]->description);
            $this->assertEquals('545',         $contracts[0]->amount->value);
            $this->assertEquals('2011-11-01',  $contracts[0]->closeDate);
            $this->assertEquals('Negotiating', $contracts[0]->stage->value);
            $contracts      = Contract::getAll();
            $this->assertEquals(13, count($contracts));

            //Create a new contact from a related Contract
            $this->setGetArray(array(   'relationAttributeName' => 'contacts',
                                        'relationModelId'       => $contact[0]->id,
                                        'relationModuleId'      => 'contacts',
                                        'redirectUrl'           => 'someRedirect'));
            $this->setPostArray(array('Contract' => array(
                                        'name'        => 'mySuperNewContract',
                                        'description' => '456765421',
                                        'closeDate'   => '11/1/2011',
                                        'amount' => array(  'value' => '545',
                                                            'currency' => array('id' => $currencies[0]->id)),
                                        'stage'       => array('value' => 'Negotiating'))));
            $this->runControllerWithRedirectExceptionAndGetContent('contracts/default/createFromRelation');
            $contracts = Contract::getByName('mySuperNewContract');
            $this->assertEquals(1, count($contracts));
            $this->assertTrue(                 $contracts[0]->id > 0);
            $this->assertTrue(                 $contracts[0]->owner   == $super);
            $this->assertEquals(1,             $contracts[0]->contacts->count());
            $this->assertTrue(                 $contracts[0]->contacts[0] == $contact[0]);
            $this->assertEquals('456765421',   $contracts[0]->description);
            $this->assertEquals('545',         $contracts[0]->amount->value);
            $this->assertEquals('2011-11-01',  $contracts[0]->closeDate);
            $this->assertEquals('Negotiating', $contracts[0]->stage->value);
            $contracts      = Contract::getAll();
            $this->assertEquals(14, count($contracts));

            //todo: test save with account.
        }

        /**
         * @depends testSuperUserCreateFromRelationAction
         */
        public function testSuperUserCopyAction()
        {
            $super = $this->logoutCurrentUserLoginNewUserAndGetByUsername('super');
            $currencies = Currency::getAll();

            $contracts = Contract::getByName('myNewContract');
            $this->assertCount(1, $contracts);

            $postArray = array(
                'Contract' => array(
                    'name' => 'myNewContract',
                    'amount' => array(
                        'value' => '1000',
                        'currency' => array(
                            'id' => $currencies[0]->id,
                        ),
                    ),
                    'account' => array(
                        'name' => 'Linked account',
                    ),
                    'closeDate' => '2012-11-01',
                    'probability' => 50,
                    'stage' => array(
                        'value' => 'Negotiating',
                    ),
                   'description' => 'some description',
                )
            );

            $this->updateModelValuesFromPostArray($contracts[0], $postArray);
            $this->assertModelHasValuesFromPostArray($contracts[0], $postArray);

            $this->assertTrue($contracts[0]->save());

            unset($postArray['Contract']['closeDate']);
            $this->assertTrue(
                $this->checkCopyActionResponseAttributeValuesFromPostArray($contracts[0], $postArray, 'Contracts')
            );

            $postArray['Contract']['name']       = 'myNewClonedContract';
            $postArray['Contract']['closeDate']  = '11/1/2012';

            $this->setGetArray(array('id' => $contracts[0]->id));
            $this->setPostArray($postArray);
            $this->runControllerWithRedirectExceptionAndGetUrl('contracts/default/copy');

            $contracts = Contract::getByName('myNewClonedContract');
            $this->assertCount(1, $contracts);
            $this->assertTrue($contracts[0]->owner->isSame($super));

            $postArray['Contract']['closeDate'] = '2012-11-01';
            $this->assertModelHasValuesFromPostArray($contracts[0], $postArray);

            $contracts = Contract::getAll();
            $this->assertCount(15, $contracts);

            $contracts = Contract::getByName('myNewClonedContract');
            $this->assertCount(1, $contracts);
            $this->assertTrue($contracts[0]->delete());
        }

        /**
         * @deletes selected leads.
         */
        public function testMassDeleteActionsForSelectedIds()
        {
            $super = $this->logoutCurrentUserLoginNewUserAndGetByUsername('super');
            $contracts = Contract::getAll();
            $this->assertEquals(14, count($contracts));
            $superContractId   = self::getModelIdByModelNameAndName('Contract', 'mySuperNewContract');
            $superContractId2  = self::getModelIdByModelNameAndName('Contract', 'superOpp2');
            $superContractId3  = self::getModelIdByModelNameAndName('Contract', 'superOpp3');
            $superContractId4  = self::getModelIdByModelNameAndName('Contract', 'myNewContract');
            $superContractId5  = self::getModelIdByModelNameAndName('Contract', 'superOpp5');
            $superContractId6  = self::getModelIdByModelNameAndName('Contract', 'superOpp6');
            $superContractId7  = self::getModelIdByModelNameAndName('Contract', 'superOpp7');
            $superContractId8  = self::getModelIdByModelNameAndName('Contract', 'superOpp8');
            $superContractId9  = self::getModelIdByModelNameAndName('Contract', 'superOpp9');
            $superContractId10 = self::getModelIdByModelNameAndName('Contract', 'superOpp10');
            $superContractId11 = self::getModelIdByModelNameAndName('Contract', 'superOpp11');
            $superContractId12 = self::getModelIdByModelNameAndName('Contract', 'superOpp12');
            //Load Model MassDelete Views.
            //MassDelete view for single selected ids
            $this->setGetArray(array('selectedIds' => '5,6,7,8,9', 'selectAll' => '', ));  // Not Coding Standard
            $this->resetPostArray();
            $content = $this->runControllerWithNoExceptionsAndGetContent('contracts/default/massDelete');
            $this->assertContains('<strong>5</strong>&#160;Contracts selected for removal', $content);

            //MassDelete view for all result selected ids
            $this->setGetArray(array('selectAll' => '1'));
            $this->resetPostArray();
            $content = $this->runControllerWithNoExceptionsAndGetContent('contracts/default/massDelete');
            $this->assertContains('<strong>14</strong>&#160;Contracts selected for removal', $content);

            //MassDelete for selected ids for page 1
            $this->setGetArray(array(
                'selectedIds' => $superContractId  . ',' . $superContractId2 . ',' . // Not Coding Standard
                                 $superContractId3 . ',' . $superContractId4 . ',' . // Not Coding Standard
                                 $superContractId5 . ',' . $superContractId6,        // Not Coding Standard
                'selectAll'        => '',
                'massDelete'       => '',
                'Contract_page' => 1));
            $this->setPostArray(array('selectedRecordCount' => 6));
            $this->runControllerWithExitExceptionAndGetContent('contracts/default/massDelete');

            //MassDelete for selected Record Count
            $Contracts = Contract::getAll();
            $this->assertEquals(9, count($Contracts));

            //MassDelete for selected ids for page 2
            $this->setGetArray(array(
                'selectedIds' => $superContractId . ',' . $superContractId2 . ',' .  // Not Coding Standard
                                 $superContractId3 . ',' . $superContractId4 . ',' . // Not Coding Standard
                                 $superContractId5 . ',' . $superContractId6,        // Not Coding Standard
                'selectAll'        => '',
                'massDelete'       => '',
                'Contract_page' => 2));
            $this->setPostArray(array('selectedRecordCount' => 6));
            $this->runControllerWithNoExceptionsAndGetContent('contracts/default/massDeleteProgress');

           //MassDelete for selected Record Count
            $Contracts = Contract::getAll();
            $this->assertEquals(8, count($Contracts));
        }

         /**
         *Test Bug with mass delete and multiple pages when using select all
         */
        public function testMassDeletePagesProperlyAndRemovesAllSelected()
        {
            $super = $this->logoutCurrentUserLoginNewUserAndGetByUsername('super');

            //MassDelete for selected Record Count
            $Contracts = Contract::getAll();
            $this->assertEquals(8, count($Contracts));

            $pageSize = Yii::app()->pagination->getForCurrentUserByType('massDeleteProgressPageSize');
            $this->assertEquals(5, $pageSize);
            //save Model MassDelete for entire search result
            $this->setGetArray(array(
                'selectAll' => '1',           // Not Coding Standard
                'Contract_page' => 1));
            $this->setPostArray(array('selectedRecordCount' => 8));
            //Run Mass Delete using progress save for page1.
            $this->runControllerWithExitExceptionAndGetContent('contracts/default/massDelete');

            //check for previous mass delete progress
            $Contracts = Contract::getAll();
            $this->assertEquals(3, count($Contracts));

            $this->setGetArray(array(
                'selectAll' => '1',           // Not Coding Standard
                'Contract_page' => 2));
            $this->setPostArray(array('selectedRecordCount' => 8));
            //Run Mass Delete using progress save for page2.
            $pageSize = Yii::app()->pagination->getForCurrentUserByType('massDeleteProgressPageSize');
            $this->assertEquals(5, $pageSize);
            $this->runControllerWithNoExceptionsAndGetContent('contracts/default/massDeleteProgress');

            //calculating lead's count
            $Contracts = Contract::getAll();
            $this->assertEquals(0, count($Contracts));
        }
    }
?>