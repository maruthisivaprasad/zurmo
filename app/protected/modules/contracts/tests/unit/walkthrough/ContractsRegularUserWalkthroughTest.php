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
     * Walkthrough for a peon user.  The peon user at first will have no granted
     * rights or permissions.  Most attempted actions will result in an ExitException
     * and a access failure view.  After this, we elevate the user with added tab rights
     * so that some of the actions will result in success and no exceptions being thrown.
     * There will still be some actions they cannot get too though because of the lack of
     * elevated permissions.  Then we will elevate permissions to allow the user to access
     * other owner's records.
     */
    class contractsRegularUserWalkthroughTest extends ZurmoRegularUserWalkthroughBaseTest
    {
        public static function setUpBeforeClass()
        {
            parent::setUpBeforeClass();
            $super = Yii::app()->user->userModel;

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
            //Setup default dashboard.
            Dashboard::getByLayoutIdAndUser                                  (Dashboard::DEFAULT_USER_LAYOUT_ID, $super);
            AllPermissionsOptimizationUtil::rebuild();
        }

        public function testRegularUserAllControllerActions()
        {
            //Now test all portlet controller actions

            //Now test peon with elevated rights to tabs /other available rights
            //such as convert lead

            //Now test peon with elevated permissions to models.

            //Test peon create/select from sublist actions with none and elevated permissions
        }

        public function testRegularUserAllControllerActionsNoElevation()
        {
            //Create Contract owned by user super.
            $super = $this->logoutCurrentUserLoginNewUserAndGetByUsername('super');
            $contract = ContractTestHelper::createContractByNameForOwner('Contract', $super);
            Yii::app()->user->userModel = User::getByUsername('nobody');

            //Now test all portlet controller actions
            $this->runControllerShouldResultInAccessFailureAndGetContent('contracts/default');
            $this->runControllerShouldResultInAccessFailureAndGetContent('contracts/default/index');
            $this->runControllerShouldResultInAccessFailureAndGetContent('contracts/default/list');
            $this->runControllerShouldResultInAccessFailureAndGetContent('contracts/default/create');
            $this->runControllerShouldResultInAccessFailureAndGetContent('contracts/default/edit');
            $this->setGetArray(array('id' => $contract->id));
            $this->resetPostArray();
            $this->runControllerShouldResultInAccessFailureAndGetContent('contracts/default/details');
            $this->setGetArray(array('selectedIds' => '4,5,6,7,8', 'selectAll' => ''));  // Not Coding Standard
            $this->resetPostArray();
            $this->runControllerShouldResultInAccessFailureAndGetContent('contracts/default/massEdit');
            $this->setGetArray(array('selectAll' => '1', 'Contract_page' => 2));
            $this->runControllerShouldResultInAccessFailureAndGetContent('contracts/default/massEditProgressSave');

            //Autocomplete for Contract should fail
            $this->setGetArray(array('term' => 'super'));
            $this->runControllerShouldResultInAccessFailureAndGetContent('contracts/default/autoComplete');

            //actionModalList should fail
            $this->setGetArray(array(
                'modalTransferInformation' => array('sourceIdFieldId' => 'x', 'sourceNameFieldId' => 'y')
            ));
            $this->runControllerShouldResultInAccessFailureAndGetContent('contracts/default/modalList');

            //actionAuditEventsModalList should fail
            $this->setGetArray(array('id' => $contract->id));
            $this->resetPostArray();
            $this->runControllerShouldResultInAccessFailureAndGetContent('contracts/default/auditEventsModalList');

            //actionDelete should fail.
            $this->setGetArray(array('id' => $contract->id));
            $this->resetPostArray();
            $this->runControllerShouldResultInAccessFailureAndGetContent('contracts/default/delete');
        }

        /**
         * @depends testRegularUserAllControllerActionsNoElevation
         */
        public function testRegularUserControllerActionsWithElevationToAccessAndCreate()
        {
            //Now test peon with elevated rights to tabs /other available rights
            $nobody = $this->logoutCurrentUserLoginNewUserAndGetByUsername('nobody');

            //Now test peon with elevated rights to contracts
            $nobody->setRight('ContractsModule', ContractsModule::RIGHT_ACCESS_CONTRACTS);
            $nobody->setRight('ContractsModule', ContractsModule::RIGHT_CREATE_CONTRACTS);
            $nobody->setRight('ContractsModule', ContractsModule::RIGHT_DELETE_CONTRACTS);
            $this->assertTrue($nobody->save());

            //Test nobody with elevated rights.
            Yii::app()->user->userModel = User::getByUsername('nobody');
            $content = $this->runControllerWithNoExceptionsAndGetContent('contracts/default/list');
            $this->assertContains('Albert Einstein', $content);
            $this->runControllerWithNoExceptionsAndGetContent('contracts/default/create');

            //Test nobody can view an existing Contract he owns.
            $contract = ContractTestHelper::createContractByNameForOwner('ContractOwnedByNobody', $nobody);

            //At this point the listview for leads should show the search/list and not the helper screen.
            $content = $this->runControllerWithNoExceptionsAndGetContent('contracts/default/list');
            $this->assertNotContains('Albert Einstein', $content);

            $this->setGetArray(array('id' => $contract->id));
            $this->runControllerWithNoExceptionsAndGetContent('contracts/default/edit');

            //Test nobody can delete an existing Contract he owns and it redirects to index.
            $this->setGetArray(array('id' => $contract->id));
            $this->resetPostArray();
            $this->runControllerWithRedirectExceptionAndGetContent('contracts/default/delete',
                                                                   Yii::app()->createUrl('contracts/default/index'));

            //Autocomplete for Contract should not fail.
            $this->setGetArray(array('term' => 'super'));
            $this->runControllerWithNoExceptionsAndGetContent('contracts/default/autoComplete');

            //actionModalList for Contract should not fail.
            $this->setGetArray(array(
                'modalTransferInformation' => array('sourceIdFieldId' => 'x', 'sourceNameFieldId' => 'y', 'modalId' => 'z')
            ));
            $this->runControllerWithNoExceptionsAndGetContent('contracts/default/modalList');
        }

        /**
         * @depends testRegularUserControllerActionsWithElevationToAccessAndCreate
         */
        public function testRegularUserControllerActionsWithElevationToModels()
        {
            //Create Contract owned by user super.
            $super = $this->logoutCurrentUserLoginNewUserAndGetByUsername('super');
            $contract = ContractTestHelper::createContractByNameForOwner('contractForElevationToModelTest', $super);

            //Test nobody, access to edit and details should fail.
            $nobody = $this->logoutCurrentUserLoginNewUserAndGetByUsername('nobody');
            $this->setGetArray(array('id' => $contract->id));
            $this->runControllerShouldResultInAccessFailureAndGetContent('contracts/default/edit');
            $this->setGetArray(array('id' => $contract->id));
            $this->runControllerShouldResultInAccessFailureAndGetContent('contracts/default/details');

            //give nobody access to read
            Yii::app()->user->userModel = $super;
            $contract->addPermissions($nobody, Permission::READ);
            $this->assertTrue($contract->save());
            AllPermissionsOptimizationUtil::securableItemGivenReadPermissionsForUser($contract, $nobody);

            //Now the nobody user can access the details view.
            Yii::app()->user->userModel = $nobody;
            $this->setGetArray(array('id' => $contract->id));
            $this->runControllerWithNoExceptionsAndGetContent('contracts/default/details');

            //Test nobody, access to edit should fail.
            $this->setGetArray(array('id' => $contract->id));
            $this->runControllerShouldResultInAccessFailureAndGetContent('contracts/default/edit');

            //give nobody access to read and write
            Yii::app()->user->userModel = $super;
            $contract->addPermissions($nobody, Permission::READ_WRITE_CHANGE_PERMISSIONS);
            $this->assertTrue($contract->save());
            AllPermissionsOptimizationUtil::securableItemLostReadPermissionsForUser($contract, $nobody);
            AllPermissionsOptimizationUtil::securableItemGivenPermissionsForUser($contract, $nobody);

            //Now the nobody user should be able to access the edit view and still the details view.
            Yii::app()->user->userModel = $nobody;
            $this->setGetArray(array('id' => $contract->id));
            $this->runControllerWithNoExceptionsAndGetContent('contracts/default/details');
            $this->setGetArray(array('id' => $contract->id));
            $this->runControllerWithNoExceptionsAndGetContent('contracts/default/edit');

            //revoke nobody access to read
            Yii::app()->user->userModel = $super;
            $contract->removePermissions($nobody, Permission::READ_WRITE_CHANGE_PERMISSIONS);
            $this->assertTrue($contract->save());
            AllPermissionsOptimizationUtil::securableItemLostPermissionsForUser($contract, $nobody);

            //Test nobody, access to detail should fail.
            Yii::app()->user->userModel = $nobody;
            $this->setGetArray(array('id' => $contract->id));
            $this->runControllerShouldResultInAccessFailureAndGetContent('contracts/default/details');
            $this->setGetArray(array('id' => $contract->id));
            $this->runControllerShouldResultInAccessFailureAndGetContent('contracts/default/edit');

            //create some roles
            Yii::app()->user->userModel = $super;
            $parentRole = new Role();
            $parentRole->name = 'AAA';
            $this->assertTrue($parentRole->save());

            $childRole = new Role();
            $childRole->name = 'BBB';
            $this->assertTrue($childRole->save());

            $userInParentRole = User::getByUsername('confused');
            $userInChildRole = User::getByUsername('nobody');

            $childRole->users->add($userInChildRole);
            $this->assertTrue($childRole->save());
            $parentRole->users->add($userInParentRole);
            $parentRole->roles->add($childRole);
            $this->assertTrue($parentRole->save());
            $userInChildRole->forget();
            $userInChildRole = User::getByUsername('nobody');
            $userInParentRole->forget();
            $userInParentRole = User::getByUsername('confused');
            $parentRoleId = $parentRole->id;
            $parentRole->forget();
            $parentRole = Role::getById($parentRoleId);
            $childRoleId = $childRole->id;
            $childRole->forget();
            $childRole = Role::getById($childRoleId);
            //create contract owned by super

            $contract2 = ContractTestHelper::createContractByNameForOwner('testingParentRolePermission', $super);

            //Test userInParentRole, access to details and edit should fail.
            Yii::app()->user->userModel = $userInParentRole;
            $this->setGetArray(array('id' => $contract2->id));
            $this->runControllerShouldResultInAccessFailureAndGetContent('contracts/default/details');
            $this->setGetArray(array('id' => $contract2->id));
            $this->runControllerShouldResultInAccessFailureAndGetContent('contracts/default/edit');

            //give userInChildRole access to READ
            Yii::app()->user->userModel = $super;
            $contract2->addPermissions($userInChildRole, Permission::READ);
            $this->assertTrue($contract2->save());
            AllPermissionsOptimizationUtil::securableItemGivenReadPermissionsForUser($contract2, $userInChildRole);

            //Test userInChildRole, access to details should not fail.
            Yii::app()->user->userModel = $userInChildRole;
            $this->setGetArray(array('id' => $contract2->id));
            $this->runControllerWithNoExceptionsAndGetContent('contracts/default/details');

            //Test userInParentRole, access to details should not fail.
            Yii::app()->user->userModel = $userInParentRole;
            $this->setGetArray(array('id' => $contract2->id));
            $this->runControllerWithNoExceptionsAndGetContent('contracts/default/details');

            //give userInChildRole access to read and write
            Yii::app()->user->userModel = $super;
            $contract2->addPermissions($userInChildRole, Permission::READ_WRITE_CHANGE_PERMISSIONS);
            $this->assertTrue($contract2->save());
            AllPermissionsOptimizationUtil::securableItemLostReadPermissionsForUser($contract2, $userInChildRole);
            AllPermissionsOptimizationUtil::securableItemGivenPermissionsForUser($contract2, $userInChildRole);

            //Test userInChildRole, access to edit should not fail.
            Yii::app()->user->userModel = $userInChildRole;
            $this->setGetArray(array('id' => $contract2->id));
            $this->runControllerWithNoExceptionsAndGetContent('contracts/default/edit');

            //Test userInParentRole, access to edit should not fail.
            $this->logoutCurrentUserLoginNewUserAndGetByUsername($userInParentRole->username);
            $this->setGetArray(array('id' => $contract2->id));
            $this->runControllerWithNoExceptionsAndGetContent('contracts/default/edit');

            //revoke userInChildRole access to read and write
            Yii::app()->user->userModel = $super;
            $contract2->addPermissions($userInChildRole, Permission::READ_WRITE_CHANGE_PERMISSIONS, Permission::DENY);
            $this->assertTrue($contract2->save());
            AllPermissionsOptimizationUtil::securableItemLostPermissionsForUser($contract2, $userInChildRole);

            //Test userInChildRole, access to detail should fail.
            Yii::app()->user->userModel = $userInChildRole;
            $this->setGetArray(array('id' => $contract2->id));
            $this->runControllerShouldResultInAccessFailureAndGetContent('contracts/default/details');
            $this->setGetArray(array('id' => $contract2->id));
            $this->runControllerShouldResultInAccessFailureAndGetContent('contracts/default/edit');

            //Test userInParentRole, access to detail should fail.
            Yii::app()->user->userModel = $userInParentRole;
            $this->setGetArray(array('id' => $contract2->id));
            $this->runControllerShouldResultInAccessFailureAndGetContent('contracts/default/details');
            $this->setGetArray(array('id' => $contract2->id));
            $this->runControllerShouldResultInAccessFailureAndGetContent('contracts/default/edit');

            //clear up the role relationships between users so not to effect next assertions
            $parentRole->users->remove($userInParentRole);
            $parentRole->roles->remove($childRole);
            $this->assertTrue($parentRole->save());
            $childRole->users->remove($userInChildRole);
            $this->assertTrue($childRole->save());

            //create some groups and assign users to groups
            Yii::app()->user->userModel = $super;
            $parentGroup = new Group();
            $parentGroup->name = 'AAA';
            $this->assertTrue($parentGroup->save());

            $childGroup = new Group();
            $childGroup->name = 'BBB';
            $this->assertTrue($childGroup->save());

            $userInChildGroup = User::getByUsername('confused');
            $userInParentGroup = User::getByUsername('nobody');

            $childGroup->users->add($userInChildGroup);
            $this->assertTrue($childGroup->save());
            $parentGroup->users->add($userInParentGroup);
            $parentGroup->groups->add($childGroup);
            $this->assertTrue($parentGroup->save());
            $parentGroup->forget();
            $childGroup->forget();
            $parentGroup = Group::getByName('AAA');
            $childGroup = Group::getByName('BBB');

            //Add access for the confused user to Contracts and creation of Contracts.
            $userInChildGroup->setRight('ContractsModule', ContractsModule::RIGHT_ACCESS_CONTRACTS);
            $userInChildGroup->setRight('ContractsModule', ContractsModule::RIGHT_CREATE_CONTRACTS);
            $this->assertTrue($userInChildGroup->save());

            //create Contract owned by super
            $contract3 = ContractTestHelper::createContractByNameForOwner('testingParentGroupPermission', $super);

            //Test userInParentGroup, access to details and edit should fail.
            Yii::app()->user->userModel = $userInParentGroup;
            $this->setGetArray(array('id' => $contract3->id));
            $this->runControllerShouldResultInAccessFailureAndGetContent('contracts/default/details');
            $this->setGetArray(array('id' => $contract3->id));
            $this->runControllerShouldResultInAccessFailureAndGetContent('contracts/default/edit');

            //Test userInChildGroup, access to details and edit should fail.
            Yii::app()->user->userModel = $userInChildGroup;
            $this->setGetArray(array('id' => $contract3->id));
            $this->runControllerShouldResultInAccessFailureAndGetContent('contracts/default/details');
            $this->setGetArray(array('id' => $contract3->id));
            $this->runControllerShouldResultInAccessFailureAndGetContent('contracts/default/edit');

            //give parentGroup access to READ
            Yii::app()->user->userModel = $super;
            $contract3->addPermissions($parentGroup, Permission::READ);
            $this->assertTrue($contract3->save());
            AllPermissionsOptimizationUtil::securableItemGivenReadPermissionsForGroup($contract3, $parentGroup);

            //Test userInParentGroup, access to details should not fail.
            Yii::app()->user->userModel = $userInParentGroup;
            $this->setGetArray(array('id' => $contract3->id));
            $this->runControllerWithNoExceptionsAndGetContent('contracts/default/details');

            //Test userInChildGroup, access to details should not fail.
            Yii::app()->user->userModel = $userInChildGroup;
            $this->setGetArray(array('id' => $contract3->id));
            $this->runControllerWithNoExceptionsAndGetContent('contracts/default/details');

            //give parentGroup access to read and write
            Yii::app()->user->userModel = $super;
            $contract3->addPermissions($parentGroup, Permission::READ_WRITE_CHANGE_PERMISSIONS);
            $this->assertTrue($contract3->save());
            AllPermissionsOptimizationUtil::securableItemLostReadPermissionsForGroup($contract3, $parentGroup);
            AllPermissionsOptimizationUtil::securableItemGivenPermissionsForGroup($contract3, $parentGroup);

            //Test userInParentGroup, access to edit should not fail.
            Yii::app()->user->userModel = $userInParentGroup;
            $this->setGetArray(array('id' => $contract3->id));
            $this->runControllerWithNoExceptionsAndGetContent('contracts/default/edit');

            //Test userInChildGroup, access to edit should not fail.
            Yii::app()->user->userModel = $userInChildGroup;
            $this->logoutCurrentUserLoginNewUserAndGetByUsername($userInChildGroup->username);
            $this->setGetArray(array('id' => $contract3->id));
            $this->runControllerWithNoExceptionsAndGetContent('contracts/default/edit');

            //revoke parentGroup access to read and write
            Yii::app()->user->userModel = $super;
            $contract3->addPermissions($parentGroup, Permission::READ_WRITE_CHANGE_PERMISSIONS, Permission::DENY);
            $this->assertTrue($contract3->save());
            AllPermissionsOptimizationUtil::securableItemLostPermissionsForGroup($contract3, $parentGroup);

            //Test userInChildGroup, access to detail should fail.
            Yii::app()->user->userModel = $userInChildGroup;
            $this->setGetArray(array('id' => $contract3->id));
            $this->runControllerShouldResultInAccessFailureAndGetContent('contracts/default/details');
            $this->setGetArray(array('id' => $contract3->id));
            $this->runControllerShouldResultInAccessFailureAndGetContent('contracts/default/edit');

            //Test userInParentGroup, access to detail should fail.
            Yii::app()->user->userModel = $userInParentGroup;
            $this->setGetArray(array('id' => $contract3->id));
            $this->runControllerShouldResultInAccessFailureAndGetContent('contracts/default/details');
            $this->setGetArray(array('id' => $contract3->id));
            $this->runControllerShouldResultInAccessFailureAndGetContent('contracts/default/edit');

            //clear up the role relationships between users so not to effect next assertions
            $super = $this->logoutCurrentUserLoginNewUserAndGetByUsername('super');
            $userInParentGroup->forget();
            $userInChildGroup->forget();
            $childGroup->forget();
            $parentGroup->forget();
            $userInParentGroup          = User::getByUsername('nobody');
            $userInChildGroup           = User::getByUsername('confused');
            $childGroup                 = Group::getByName('BBB');
            $parentGroup                = Group::getByName('AAA');

            //clear up the role relationships between users so not to effect next assertions
            $parentGroup->users->remove($userInParentGroup);
            $parentGroup->groups->remove($childGroup);
            $this->assertTrue($parentGroup->save());
            $childGroup->users->remove($userInChildGroup);
            $this->assertTrue($childGroup->save());
        }

        /**
         * @depends testRegularUserControllerActionsWithElevationToModels
         */
        public function testRegularUserViewingContractWithoutAccessToAccount()
        {
            $super       = $this->logoutCurrentUserLoginNewUserAndGetByUsername('super');
            $aUser       = UserTestHelper::createBasicUser('aUser');
            $aUser->setRight('ContractsModule', ContractsModule::RIGHT_ACCESS_CONTRACTS);
            $aUser->setRight('AccountsModule',      AccountsModule::RIGHT_ACCESS_ACCOUNTS);
            $this->assertTrue($aUser->save());
            $aUser       = User::getByUsername('aUser');
            $account     = AccountTestHelper::createAccountByNameForOwner('superTestAccount', $super);
            $contract = ContractTestHelper::createContractWithAccountByNameForOwner('contractOwnedByaUser', $aUser, $account);
            $account->forget();
            $id          = $contract->id;
            $contract->forget();
            unset($contract);
            $this->logoutCurrentUserLoginNewUserAndGetByUsername('aUser');
            $content = $this->runControllerWithNoExceptionsAndGetContent('contracts/default');
            $this->assertNotContains('Fatal error: Method Account::__toString() must not throw an exception', $content);
        }

         /**
         * @deletes selected leads.
         */
        public function testRegularMassDeleteActionsForSelectedIds()
        {
            $super = $this->logoutCurrentUserLoginNewUserAndGetByUsername('super');
            $confused = User::getByUsername('confused');
            $nobody = User::getByUsername('nobody');
            $this->assertEquals(Right::DENY, $confused->getEffectiveRight('ZurmoModule', ZurmoModule::RIGHT_BULK_DELETE));
            $confused->setRight('ZurmoModule', ZurmoModule::RIGHT_BULK_DELETE);
            //Load MassDelete view for the 3 contracts.
            $contracts = Contract::getAll();
            $this->assertEquals(9, count($contracts));
            $contract1 = ContractTestHelper::createContractByNameForOwner('contractDelete1', $confused);
            $contract2 = ContractTestHelper::createContractByNameForOwner('contractDelete2', $confused);
            $contract3 = ContractTestHelper::createContractByNameForOwner('contractDelete3', $nobody);
            $contract4 = ContractTestHelper::createContractByNameForOwner('contractDelete4', $confused);
            $contract5 = ContractTestHelper::createContractByNameForOwner('contractDelete5', $confused);
            $contract6 = ContractTestHelper::createContractByNameForOwner('contractDelete6', $nobody);
            $selectedIds = $contract1->id . ',' . $contract2->id . ',' . $contract3->id ;    // Not Coding Standard
            $this->setGetArray(array('selectedIds' => $selectedIds, 'selectAll' => ''));  // Not Coding Standard
            $this->resetPostArray();
            $content = $this->runControllerWithNoExceptionsAndGetContent('contracts/default/massDelete');
            $this->assertContains('<strong>3</strong>&#160;Contracts selected for removal', $content);
            $pageSize = Yii::app()->pagination->getForCurrentUserByType('massDeleteProgressPageSize');
            $this->assertEquals(5, $pageSize);
            //calculating leads after adding 6 new records
            $contracts = Contract::getAll();
            $this->assertEquals(15, count($contracts));
            //Deleting 6 contracts for pagination scenario
            //Run Mass Delete using progress save for page1
            $selectedIds = $contract1->id . ',' . $contract2->id . ',' . // Not Coding Standard
                           $contract3->id . ',' . $contract4->id . ',' . // Not Coding Standard
                           $contract5->id . ',' . $contract6->id;        // Not Coding Standard
            $this->setGetArray(array(
                'selectedIds' => $selectedIds, // Not Coding Standard
                'selectAll' => '',
                'Contract_page' => 1));
            $this->setPostArray(array('selectedRecordCount' => 6));
            $content = $this->runControllerWithExitExceptionAndGetContent('contracts/default/massDelete');
            $contracts = Contract::getAll();
            $this->assertEquals(10, count($contracts));

            //Run Mass Delete using progress save for page2
            $selectedIds = $contract1->id . ',' . $contract2->id . ',' . // Not Coding Standard
                           $contract3->id . ',' . $contract4->id . ',' . // Not Coding Standard
                           $contract5->id . ',' . $contract6->id;        // Not Coding Standard
            $this->setGetArray(array(
                'selectedIds' => $selectedIds, // Not Coding Standard
                'selectAll' => '',
                'Contract_page' => 2));
            $this->setPostArray(array('selectedRecordCount' => 6));
            $content = $this->runControllerWithNoExceptionsAndGetContent('contracts/default/massDeleteProgress');
            $contracts = Contract::getAll();
            $this->assertEquals(9, count($contracts));
        }

         /**
         *Test Bug with mass delete and multiple pages when using select all
         */
        public function testRegularMassDeletePagesProperlyAndRemovesAllSelected()
        {
            $super = $this->logoutCurrentUserLoginNewUserAndGetByUsername('super');
            $confused = User::getByUsername('confused');
            $nobody = User::getByUsername('nobody');

            //Load MassDelete view for the 8 contracts.
            $contracts = Contract::getAll();
            $this->assertEquals(9, count($contracts));
             //Deleting all contracts

            //mass Delete pagination scenario
            //Run Mass Delete using progress save for page1
            $this->setGetArray(array(
                'selectAll' => '1',
                'Contract_page' => 1));
            $this->setPostArray(array('selectedRecordCount' => 9));
            $pageSize = Yii::app()->pagination->getForCurrentUserByType('massDeleteProgressPageSize');
            $this->assertEquals(5, $pageSize);
            $content = $this->runControllerWithExitExceptionAndGetContent('contracts/default/massDelete');
            $contracts = Contract::getAll();
            $this->assertEquals(4, count($contracts));

           //Run Mass Delete using progress save for page2
            $this->setGetArray(array(
                'selectAll' => '1',
                'Contract_page' => 2));
            $this->setPostArray(array('selectedRecordCount' => 9));
            $pageSize = Yii::app()->pagination->getForCurrentUserByType('massDeleteProgressPageSize');
            $this->assertEquals(5, $pageSize);
            $content = $this->runControllerWithNoExceptionsAndGetContent('contracts/default/massDeleteProgress');

            $contracts = Contract::getAll();
            $this->assertEquals(0, count($contracts));
        }
    }
?>