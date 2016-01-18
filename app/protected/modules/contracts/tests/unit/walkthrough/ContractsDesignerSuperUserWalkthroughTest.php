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
    * Designer Module Walkthrough of Contracts.
    * Walkthrough for the super user of all possible controller actions.
    * Since this is a super user, he should have access to all controller actions
    * without any exceptions being thrown.
    * This also test the creation of the customfileds, addition of custom fields to all the layouts including the search
    * views.
    * This also test creation search, edit and delete of the Contract based on the custom fields.
    */
    class ContractsDesignerSuperUserWalkthroughTest extends ZurmoWalkthroughBaseTest
    {
        public static $activateDefaultLanguages = true;

        public static function setUpBeforeClass()
        {
            parent::setUpBeforeClass();
            SecurityTestHelper::createSuperAdmin();
            $super = User::getByUsername('super');
            Yii::app()->user->userModel = $super;
            Currency::makeBaseCurrency();

            //Create a account for testing.
            $account = AccountTestHelper::createAccountByNameForOwner('superAccount', $super);

            //Create a Contract for testing.
            ContractTestHelper::createContractWithAccountByNameForOwner('superOpp', $super, $account);
        }

         public function testSuperUserContractDefaultControllerActions()
        {
            $super = $this->logoutCurrentUserLoginNewUserAndGetByUsername('super');

            //Default Controller actions requiring some sort of parameter via POST or GET
            //Load Contract Modules Menu.
            $this->setGetArray(array('moduleClassName' => 'ContractsModule'));
            $this->runControllerWithNoExceptionsAndGetContent('designer/default/modulesMenu');

            //Load AttributesList for Contract module.
            $this->setGetArray(array('moduleClassName' => 'ContractsModule'));
            $this->runControllerWithNoExceptionsAndGetContent('designer/default/attributesList');

            //Load ModuleLayoutsList for Contract module.
            $this->setGetArray(array('moduleClassName' => 'ContractsModule'));
            $this->runControllerWithNoExceptionsAndGetContent('designer/default/moduleLayoutsList');

            //Load ModuleEdit view for each applicable module.
            $this->setGetArray(array('moduleClassName' => 'ContractsModule'));
            $this->runControllerWithNoExceptionsAndGetContent('designer/default/moduleEdit');

            //Now validate save with failed validation.
            $this->setGetArray(array('moduleClassName' => 'ContractsModule'));
            $this->setPostArray(array('ajax' => 'edit-form',
                'ContractsModuleForm' => $this->createModuleEditBadValidationPostData()));
            $content = $this->runControllerWithExitExceptionAndGetContent('designer/default/moduleEdit');
            $this->assertTrue(strlen($content) > 50); //approximate, but should definetely be larger than 50.

            //Now validate save with successful validation.
            $this->setGetArray(array('moduleClassName' => 'ContractsModule'));
            $this->setPostArray(array('ajax' => 'edit-form',
                'ContractsModuleForm' => $this->createModuleEditGoodValidationPostData('opp new name')));
            $content = $this->runControllerWithExitExceptionAndGetContent('designer/default/moduleEdit');
            $this->assertEquals('[]', $content);

            //Now save successfully.
            $this->setGetArray(array('moduleClassName' => 'ContractsModule'));
            $this->setPostArray(array('save' => 'Save',
                'ContractsModuleForm' => $this->createModuleEditGoodValidationPostData('opp new name')));
            $this->runControllerWithRedirectExceptionAndGetContent('designer/default/moduleEdit');

            //Now confirm everything did in fact save correctly.
            $this->assertEquals('Opp New Name',  ContractsModule::getModuleLabelByTypeAndLanguage('Singular'));
            $this->assertEquals('Opp New Names', ContractsModule::getModuleLabelByTypeAndLanguage('Plural'));
            $this->assertEquals('opp new name',  ContractsModule::getModuleLabelByTypeAndLanguage('SingularLowerCase'));
            $this->assertEquals('opp new names', ContractsModule::getModuleLabelByTypeAndLanguage('PluralLowerCase'));

            //Load LayoutEdit for each applicable module and applicable layout
            $this->resetPostArray();
            $this->setGetArray(array('moduleClassName' => 'ContractsModule',
                                     'viewClassName'   => 'ContractsListView'));
            $this->runControllerWithNoExceptionsAndGetContent('designer/default/LayoutEdit');
            $this->setGetArray(array('moduleClassName' => 'ContractsModule',
                                     'viewClassName'   => 'ContractsModalListView'));
            $this->runControllerWithNoExceptionsAndGetContent('designer/default/LayoutEdit');
            $this->setGetArray(array('moduleClassName' => 'ContractsModule',
                                     'viewClassName'   => 'ContractsModalSearchView'));
            $this->runControllerWithNoExceptionsAndGetContent('designer/default/LayoutEdit');
            $this->setGetArray(array('moduleClassName' => 'ContractsModule',
                                     'viewClassName'   => 'ContractsMassEditView'));
            $this->runControllerWithNoExceptionsAndGetContent('designer/default/LayoutEdit');
            $this->setGetArray(array('moduleClassName' => 'ContractsModule',
                                     'viewClassName'   => 'ContractsRelatedListView'));
            $this->runControllerWithNoExceptionsAndGetContent('designer/default/LayoutEdit');
            $this->setGetArray(array('moduleClassName' => 'ContractsModule',
                                     'viewClassName'   => 'ContractsSearchView'));
            $this->runControllerWithNoExceptionsAndGetContent('designer/default/LayoutEdit');
            $this->setGetArray(array('moduleClassName' => 'ContractsModule',
                                     'viewClassName'   => 'ContractEditAndDetailsView'));
            $this->runControllerWithNoExceptionsAndGetContent('designer/default/LayoutEdit');
        }

        /**
         * @depends testSuperUserContractDefaultControllerActions
         */
        public function testSuperUserCustomFieldsWalkthroughForContractsModule()
        {
            $super = $this->logoutCurrentUserLoginNewUserAndGetByUsername('super');

            //Test create field list.
            $this->setGetArray(array('moduleClassName' => 'ContractsModule'));

            //View creation screen, then create custom field for each custom field type.
            $this->createCheckBoxCustomFieldByModule            ('ContractsModule', 'checkbox');
            $this->createCurrencyValueCustomFieldByModule       ('ContractsModule', 'currency');
            $this->createDateCustomFieldByModule                ('ContractsModule', 'date');
            $this->createDateTimeCustomFieldByModule            ('ContractsModule', 'datetime');
            $this->createDecimalCustomFieldByModule             ('ContractsModule', 'decimal');
            $this->createDropDownCustomFieldByModule            ('ContractsModule', 'picklist');
            $this->createDependentDropDownCustomFieldByModule   ('ContractsModule', 'countrylist');
            $this->createDependentDropDownCustomFieldByModule   ('ContractsModule', 'statelist');
            $this->createDependentDropDownCustomFieldByModule   ('ContractsModule', 'citylist');
            $this->createIntegerCustomFieldByModule             ('ContractsModule', 'integer');
            $this->createMultiSelectDropDownCustomFieldByModule ('ContractsModule', 'multiselect');
            $this->createTagCloudCustomFieldByModule            ('ContractsModule', 'tagcloud');
            $this->createCalculatedNumberCustomFieldByModule    ('ContractsModule', 'calcnumber');
            $this->createDropDownDependencyCustomFieldByModule  ('ContractsModule', 'dropdowndep');
            $this->createPhoneCustomFieldByModule               ('ContractsModule', 'phone');
            $this->createRadioDropDownCustomFieldByModule       ('ContractsModule', 'radio');
            $this->createTextCustomFieldByModule                ('ContractsModule', 'text');
            $this->createTextAreaCustomFieldByModule            ('ContractsModule', 'textarea');
            $this->createUrlCustomFieldByModule                 ('ContractsModule', 'url');
        }

        /**
         * @depends testSuperUserCustomFieldsWalkthroughForContractsModule
         */
        public function testSuperUserAddCustomFieldsToLayoutsForContractsModule()
        {
            $super = $this->logoutCurrentUserLoginNewUserAndGetByUsername('super');

            //Add custom fields to ContractEditAndDetailsView.
            $this->setGetArray(array('moduleClassName' => 'ContractsModule',
                                     'viewClassName'   => 'ContractEditAndDetailsView'));
            $layout = ContractsDesignerWalkthroughHelperUtil::getContractEditAndDetailsViewLayoutWithAllCustomFieldsPlaced();
            $this->setPostArray(array('save'  => 'Save', 'layout' => $layout,
                                      'LayoutPanelsTypeForm' => array('type' => FormLayout::PANELS_DISPLAY_TYPE_ALL)));
            $content = $this->runControllerWithExitExceptionAndGetContent('designer/default/LayoutEdit');
            $this->assertContains('Layout saved successfully', $content);

            //Add all fields to ContractsSearchView.
            $this->setGetArray(array('moduleClassName' => 'ContractsModule',
                                     'viewClassName'   => 'ContractsSearchView'));
            $layout = ContractsDesignerWalkthroughHelperUtil::getContractsSearchViewLayoutWithAllCustomFieldsPlaced();
            $this->setPostArray(array('save'  => 'Save', 'layout' => $layout));
            $content = $this->runControllerWithExitExceptionAndGetContent('designer/default/LayoutEdit');
            $this->assertContains('Layout saved successfully', $content);

            //Add all fields to ContractsListView.
            $this->setGetArray(array('moduleClassName' => 'ContractsModule',
                                     'viewClassName'   => 'ContractsListView'));
            $layout = ContractsDesignerWalkthroughHelperUtil::getContractsListViewLayoutWithAllStandardAndCustomFieldsPlaced();
            $this->setPostArray(array('save'  => 'Save', 'layout' => $layout));
            $content = $this->runControllerWithExitExceptionAndGetContent('designer/default/LayoutEdit');
            $this->assertContains('Layout saved successfully', $content);

            //Add all fields to ContractsRelatedListView.
            $this->setGetArray(array('moduleClassName' => 'ContractsModule',
                                     'viewClassName'   => 'ContractsRelatedListView'));
            $layout = ContractsDesignerWalkthroughHelperUtil::getContractsListViewLayoutWithAllStandardAndCustomFieldsPlaced();
            $this->setPostArray(array('save'  => 'Save', 'layout' => $layout));
            $content = $this->runControllerWithExitExceptionAndGetContent('designer/default/LayoutEdit');
            $this->assertContains('Layout saved successfully', $content);

            //Add all fields to ContractsMassEditView.
            $this->setGetArray(array('moduleClassName' => 'ContractsModule',
                                     'viewClassName'   => 'ContractsMassEditView'));
            $layout = ContractsDesignerWalkthroughHelperUtil::getContractsMassEditViewLayoutWithAllStandardAndCustomFieldsPlaced();
            $this->setPostArray(array('save'  => 'Save', 'layout' => $layout));
            $content = $this->runControllerWithExitExceptionAndGetContent('designer/default/LayoutEdit');
            $this->assertContains('Layout saved successfully', $content);
        }

        /**
         * @depends testSuperUserAddCustomFieldsToLayoutsForContractsModule
         */
        public function testLayoutsLoadOkAfterCustomFieldsPlacedForContractsModule()
        {
            $super = $this->logoutCurrentUserLoginNewUserAndGetByUsername('super');
            $superAccountId = self::getModelIdByModelNameAndName ('Account', 'superAccount');
            $superContractId = self::getModelIdByModelNameAndName ('Contract', 'superOpp');
            //Load create, edit, and details views.
            $this->runControllerWithNoExceptionsAndGetContent('contracts/default/create');
            $this->setGetArray(array('id' => $superContractId));
            $this->runControllerWithNoExceptionsAndGetContent('contracts/default/edit');
            $this->runControllerWithNoExceptionsAndGetContent('contracts/default/details');
            $this->runControllerWithNoExceptionsAndGetContent('contracts/default/list');
            $this->setGetArray(array(
                'modalTransferInformation' => array('sourceIdFieldId' => 'x', 'sourceNameFieldId' => 'y', 'modalId' => 'z')
            ));
            $this->resetPostArray();
            $this->runControllerWithNoExceptionsAndGetContent('contracts/default/modalList');
            $this->setGetArray(array('id' => $superAccountId));
            $this->resetPostArray();
            $this->runControllerWithNoExceptionsAndGetContent('accounts/default/details');
            $this->setGetArray(array('selectAll' => '1'));
            $this->resetPostArray();
            $this->runControllerWithNoExceptionsAndGetContent('contracts/default/massEdit');
        }

        /**
         * @depends testLayoutsLoadOkAfterCustomFieldsPlacedForContractsModule
         */
        public function testCreateAnContractAfterTheCustomFieldsArePlacedForContractsModule()
        {
            $super = $this->logoutCurrentUserLoginNewUserAndGetByUsername('super');

            //Set the date and datetime variable values here.
            $date           = Yii::app()->dateFormatter->format(DateTimeUtil::getLocaleDateFormatForInput(), time());
            $dateAssert     = date('Y-m-d');
            $datetime       = Yii::app()->dateFormatter->format(DateTimeUtil::getLocaleDateTimeFormatForInput(), time());
            $datetimeAssert = date('Y-m-d H:i:')."00";
            $baseCurrency   = Currency::getByCode(Yii::app()->currencyHelper->getBaseCode());

            //Retrieve the account id and the super account id.
            $accountId   = self::getModelIdByModelNameAndName ('Account', 'superAccount');
            $superUserId = $super->id;

            //Create a new Contract based on the custom fields.
            $this->resetGetArray();
            $this->setPostArray(array('Contract' => array(
                            'name'                              => 'myNewContract',
                            'amount'                            => array('value' => 298000,
                                                                         'currency' => array('id' => $baseCurrency->id)),
                            'account'                           => array('id' => $accountId),
                            'closeDate'                         => $date,
                            'stage'                             => array('value' => 'Prospecting'),
                            'source'                            => array('value' => 'Self-Generated'),
                            'description'                       => 'This is the Description',
                            'owner'                             => array('id' => $superUserId),
                            'explicitReadWriteModelPermissions' => array('type' => null),
                            'checkboxCstm'                      => '1',
                            'currencyCstm'                      => array('value'    => 45,
                                                                         'currency' => array('id' => $baseCurrency->id)),
                            'dateCstm'                          => $date,
                            'datetimeCstm'                      => $datetime,
                            'decimalCstm'                       => '123',
                            'picklistCstm'                      => array('value' => 'a'),
                            'multiselectCstm'                   => array('values' => array('ff', 'rr')),
                            'tagcloudCstm'                      => array('values' => array('writing', 'gardening')),
                            'countrylistCstm'                   => array('value'  => 'bbbb'),
                            'statelistCstm'                     => array('value'  => 'bbb1'),
                            'citylistCstm'                      => array('value'  => 'bb1'),
                            'integerCstm'                       => '12',
                            'phoneCstm'                         => '259-784-2169',
                            'radioCstm'                         => array('value' => 'd'),
                            'textCstm'                          => 'This is a test Text',
                            'textareaCstm'                      => 'This is a test TextArea',
                            'urlCstm'                           => 'http://wwww.abc.com')));
            $this->runControllerWithRedirectExceptionAndGetUrl('contracts/default/create');

            //Check the details if they are saved properly for the custom fields.
            $contractId = self::getModelIdByModelNameAndName('Contract', 'myNewContract');
            $contract   = Contract::getById($contractId);

            //Retrieve the permission of the Contract.
            $explicitReadWriteModelPermissions = ExplicitReadWriteModelPermissionsUtil::
                                                 makeBySecurableItem($contract);
            $readWritePermitables              = $explicitReadWriteModelPermissions->getReadWritePermitables();
            $readOnlyPermitables               = $explicitReadWriteModelPermissions->getReadOnlyPermitables();

            $this->assertEquals($contract->name                       , 'myNewContract');
            $this->assertEquals($contract->amount->value              , '298000');
            $this->assertEquals($contract->amount->currency->id       , $baseCurrency->id);
            $this->assertEquals($contract->account->id                , $accountId);
            $this->assertEquals($contract->probability                , '10');
            $this->assertEquals($contract->stage->value               , 'Prospecting');
            $this->assertEquals($contract->source->value              , 'Self-Generated');
            $this->assertEquals($contract->description                , 'This is the Description');
            $this->assertEquals($contract->owner->id                  , $superUserId);
            $this->assertEquals(0                                        , count($readWritePermitables));
            $this->assertEquals(0                                        , count($readOnlyPermitables));
            $this->assertEquals($contract->checkboxCstm               , '1');
            $this->assertEquals($contract->currencyCstm->value        , 45);
            $this->assertEquals($contract->currencyCstm->currency->id , $baseCurrency->id);
            $this->assertEquals($contract->dateCstm                   , $dateAssert);
            $this->assertEquals($contract->datetimeCstm               , $datetimeAssert);
            $this->assertEquals($contract->decimalCstm                , '123');
            $this->assertEquals($contract->picklistCstm->value        , 'a');
            $this->assertEquals($contract->integerCstm                , 12);
            $this->assertEquals($contract->phoneCstm                  , '259-784-2169');
            $this->assertEquals($contract->radioCstm->value           , 'd');
            $this->assertEquals($contract->textCstm                   , 'This is a test Text');
            $this->assertEquals($contract->textareaCstm               , 'This is a test TextArea');
            $this->assertEquals($contract->urlCstm                    , 'http://wwww.abc.com');
            $this->assertEquals($contract->countrylistCstm->value     , 'bbbb');
            $this->assertEquals($contract->statelistCstm->value       , 'bbb1');
            $this->assertEquals($contract->citylistCstm->value        , 'bb1');
            $this->assertContains('ff'                                   , $contract->multiselectCstm->values);
            $this->assertContains('rr'                                   , $contract->multiselectCstm->values);
            $this->assertContains('writing'                              , $contract->tagcloudCstm->values);
            $this->assertContains('gardening'                            , $contract->tagcloudCstm->values);
            $metadata            = CalculatedDerivedAttributeMetadata::
                                   getByNameAndModelClassName('calcnumber', 'Contract');
            $testCalculatedValue = CalculatedNumberUtil::calculateByFormulaAndModelAndResolveFormat($metadata->getFormula(), $contract);
            $this->assertEquals('1,476'                                    , $testCalculatedValue); // Not Coding Standard
        }

        /**
         * @depends testCreateAnContractAfterTheCustomFieldsArePlacedForcontractsModule
         */
        public function testWhetherSearchWorksForTheCustomFieldsPlacedForContractsModuleAfterCreatingTheContract()
        {
            $super = $this->logoutCurrentUserLoginNewUserAndGetByUsername('super');

            //Retrieve the account id and the super user id.
            $accountId      = self::getModelIdByModelNameAndName ('Account', 'superAccount');
            $superUserId    = $super->id;
            $baseCurrency   = Currency::getByCode(Yii::app()->currencyHelper->getBaseCode());

            //Search a created Contract using the customfield.
            $this->resetPostArray();
            $this->setGetArray(array('ContractsSearchForm' => array(
                                                'name'               => 'myNewContract',
                                                'owner'              => array('id' => $superUserId),
                                                'ownedItemsOnly'     => '1',
                                                'account'            => array('id' => $accountId),
                                                'amount'             => array('value'       => '298000',
                                                                              'relatedData' => true,
                                                                              'currency'    => array(
                                                                              'id' => $baseCurrency->id)),
                                                'closeDate__Date'    => array('value' => 'Today'),
                                                'stage'              => array('value' => 'Prospecting'),
                                                'source'             => array('value' => 'Self-Generated'),
                                                'decimalCstm'        => '123',
                                                'integerCstm'        => '12',
                                                'phoneCstm'          => '259-784-2169',
                                                'textCstm'           => 'This is a test Text',
                                                'textareaCstm'       => 'This is a test TextArea',
                                                'urlCstm'            => 'http://wwww.abc.com',
                                                'checkboxCstm'       => array('value'  =>  '1'),
                                                'currencyCstm'       => array('value'  =>  45),
                                                'picklistCstm'       => array('value'  =>  'a'),
                                                'multiselectCstm'    => array('values' => array('ff', 'rr')),
                                                'tagcloudCstm'       => array('values' => array('writing', 'gardening')),
                                                'countrylistCstm'    => array('value'  => 'bbbb'),
                                                'statelistCstm'      => array('value'  => 'bbb1'),
                                                'citylistCstm'       => array('value'  => 'bb1'),
                                                'radioCstm'          => array('value'  =>  'd'),
                                                'dateCstm__Date'     => array('type'   =>  'Today'),
                                                'datetimeCstm__DateTime' => array('type'   =>  'Today')),
                                     'ajax' =>  'list-view'));
            $content = $this->runControllerWithNoExceptionsAndGetContent('contracts/default');

            //Check if the Contract name exits after the search is performed on the basis of the
            //custom fields added to the Contracts module.
            //$this->assertContains("Displaying 1-1 of 1 result(s).", $content); //removed until we show the count again in the listview.
            $this->assertContains("myNewContract", $content);
        }

        /**
         * @depends testWhetherSearchWorksForTheCustomFieldsPlacedForContractsModuleAfterCreatingTheContract
         */
        public function testEditOfTheContractForTheTagCloudFieldAfterRemovingAllTagsPlacedForContractsModule()
        {
            $super = $this->logoutCurrentUserLoginNewUserAndGetByUsername('super');

            //Set the date and datetime variable values here.
            $date           = Yii::app()->dateFormatter->format(DateTimeUtil::getLocaleDateFormatForInput(), time());
            $dateAssert     = date('Y-m-d');
            $datetime       = Yii::app()->dateFormatter->format(DateTimeUtil::getLocaleDateTimeFormatForInput(), time());
            $datetimeAssert = date('Y-m-d H:i:')."00";
            $baseCurrency   = Currency::getByCode(Yii::app()->currencyHelper->getBaseCode());

            //Retrieve the account id, the super user id and Contract Id.
            $accountId                        = self::getModelIdByModelNameAndName ('Account', 'superAccount');
            $superUserId                      = $super->id;
            $explicitReadWriteModelPermission = ExplicitReadWriteModelPermissionsUtil::MIXED_TYPE_EVERYONE_GROUP;
            $contract   = Contract::getByName('myNewContract');
            $contractId = $contract[0]->id;
            $this->assertEquals(2, $contract[0]->tagcloudCstm->values->count());

            //Edit a new contract based on the custom fields.
            $this->setGetArray(array('id' => $contractId));
            $this->setPostArray(array('Contract' => array(
                            'name'                              => 'myEditContract',
                            'amount'                            => array('value'       => 288000,
                                                                         'currency'    => array(
                                                                             'id'      => $baseCurrency->id)),
                            'account'                           => array('id' => $accountId),
                            'closeDate'                         => $date,
                            'stage'                             => array('value' => 'Qualification'),
                            'source'                            => array('value' => 'Inbound Call'),
                            'description'                       => 'This is the Edit Description',
                            'owner'                             => array('id' => $superUserId),
                            'explicitReadWriteModelPermissions' => array('type' => $explicitReadWriteModelPermission),
                            'checkboxCstm'                      => '0',
                            'currencyCstm'                      => array('value'       => 40,
                                                                         'currency'    => array(
                                                                             'id' => $baseCurrency->id)),
                            'decimalCstm'                       => '12',
                            'dateCstm'                          => $date,
                            'datetimeCstm'                      => $datetime,
                            'picklistCstm'                      => array('value'  => 'b'),
                            'multiselectCstm'                   => array('values' =>  array('gg', 'hh')),
                            'tagcloudCstm'                      => array('values' =>  array()),
                            'countrylistCstm'                   => array('value'  => 'aaaa'),
                            'statelistCstm'                     => array('value'  => 'aaa1'),
                            'citylistCstm'                      => array('value'  => 'ab1'),
                            'integerCstm'                       => '11',
                            'phoneCstm'                         => '259-784-2069',
                            'radioCstm'                         => array('value' => 'e'),
                            'textCstm'                          => 'This is a test Edit Text',
                            'textareaCstm'                      => 'This is a test Edit TextArea',
                            'urlCstm'                           => 'http://wwww.abc-edit.com')));
            $this->runControllerWithRedirectExceptionAndGetUrl('contracts/default/edit');

            //Check the details if they are saved properly for the custom fields.
            $contractId = self::getModelIdByModelNameAndName('Contract', 'myEditContract');
            $contract   = Contract::getById($contractId);

            //Retrieve the permission of the Contract.
            $explicitReadWriteModelPermissions = ExplicitReadWriteModelPermissionsUtil::
                                                 makeBySecurableItem($contract);
            $readWritePermitables              = $explicitReadWriteModelPermissions->getReadWritePermitables();
            $readOnlyPermitables               = $explicitReadWriteModelPermissions->getReadOnlyPermitables();

            $this->assertEquals($contract->name                       , 'myEditContract');
            $this->assertEquals($contract->amount->value              , '288000');
            $this->assertEquals($contract->amount->currency->id       , $baseCurrency->id);
            $this->assertEquals($contract->account->id                , $accountId);
            $this->assertEquals($contract->probability                , '25');
            $this->assertEquals($contract->stage->value               , 'Qualification');
            $this->assertEquals($contract->source->value              , 'Inbound Call');
            $this->assertEquals($contract->description                , 'This is the Edit Description');
            $this->assertEquals($contract->owner->id                  , $superUserId);
            $this->assertEquals(1                                        , count($readWritePermitables));
            $this->assertEquals(0                                        , count($readOnlyPermitables));
            $this->assertEquals($contract->checkboxCstm               , '0');
            $this->assertEquals($contract->currencyCstm->value        , 40);
            $this->assertEquals($contract->currencyCstm->currency->id , $baseCurrency->id);
            $this->assertEquals($contract->dateCstm                   , $dateAssert);
            $this->assertEquals($contract->datetimeCstm               , $datetimeAssert);
            $this->assertEquals($contract->decimalCstm                , '12');
            $this->assertEquals($contract->picklistCstm->value        , 'b');
            $this->assertEquals($contract->integerCstm                , 11);
            $this->assertEquals($contract->phoneCstm                  , '259-784-2069');
            $this->assertEquals($contract->radioCstm->value           , 'e');
            $this->assertEquals($contract->textCstm                   , 'This is a test Edit Text');
            $this->assertEquals($contract->textareaCstm               , 'This is a test Edit TextArea');
            $this->assertEquals($contract->urlCstm                    , 'http://wwww.abc-edit.com');
            $this->assertEquals($contract->dateCstm                   , $dateAssert);
            $this->assertEquals($contract->datetimeCstm               , $datetimeAssert);
            $this->assertEquals($contract->countrylistCstm->value     , 'aaaa');
            $this->assertEquals($contract->statelistCstm->value       , 'aaa1');
            $this->assertEquals($contract->citylistCstm->value        , 'ab1');
            $this->assertContains('gg'                                   , $contract->multiselectCstm->values);
            $this->assertContains('hh'                                   , $contract->multiselectCstm->values);
            $this->assertEquals(0                                        , $contract->tagcloudCstm->values->count());
            $metadata            = CalculatedDerivedAttributeMetadata::
                                   getByNameAndModelClassName('calcnumber', 'Contract');
            $testCalculatedValue = CalculatedNumberUtil::calculateByFormulaAndModelAndResolveFormat($metadata->getFormula(), $contract);
            $this->assertEquals(132                                      , $testCalculatedValue);
        }

        /**
         * @depends testEditOfTheContractForTheTagCloudFieldAfterRemovingAllTagsPlacedForContractsModule
         */
        public function testEditOfTheContractForTheCustomFieldsPlacedForContractsModule()
        {
            $super = $this->logoutCurrentUserLoginNewUserAndGetByUsername('super');

            //Set the date and datetime variable values here.
            $date           = Yii::app()->dateFormatter->format(DateTimeUtil::getLocaleDateFormatForInput(), time());
            $dateAssert     = date('Y-m-d');
            $datetime       = Yii::app()->dateFormatter->format(DateTimeUtil::getLocaleDateTimeFormatForInput(), time());
            $datetimeAssert = date('Y-m-d H:i:')."00";
            $baseCurrency   = Currency::getByCode(Yii::app()->currencyHelper->getBaseCode());

            //Retrieve the account id, the super user id and Contract Id.
            $accountId                        = self::getModelIdByModelNameAndName ('Account', 'superAccount');
            $superUserId                      = $super->id;
            $explicitReadWriteModelPermission = ExplicitReadWriteModelPermissionsUtil::MIXED_TYPE_EVERYONE_GROUP;
            $contract                      = Contract::getByName('myEditContract');
            $contractId                    = $contract[0]->id;

            //Edit a new contract based on the custom fields.
            $this->setGetArray(array('id' => $contractId));
            $this->setPostArray(array('Contract' => array(
                            'name'                              => 'myEditContract',
                            'amount'                            => array('value' => 288000,
                                                                         'currency' => array(
                                                                         'id' => $baseCurrency->id)),
                            'account'                           => array('id' => $accountId),
                            'closeDate'                         => $date,
                            'stage'                             => array('value' => 'Qualification'),
                            'source'                            => array('value' => 'Inbound Call'),
                            'description'                       => 'This is the Edit Description',
                            'owner'                             => array('id' => $superUserId),
                            'explicitReadWriteModelPermissions' => array('type' => $explicitReadWriteModelPermission),
                            'checkboxCstm'                      => '0',
                            'currencyCstm'                      => array('value'   => 40,
                                                                         'currency' => array(
                                                                         'id' => $baseCurrency->id)),
                            'decimalCstm'                       => '12',
                            'dateCstm'                          => $date,
                            'datetimeCstm'                      => $datetime,
                            'picklistCstm'                      => array('value'  => 'b'),
                            'multiselectCstm'                   => array('values' =>  array('gg', 'hh')),
                            'tagcloudCstm'                      => array('values' =>  array('reading', 'surfing')),
                            'countrylistCstm'                   => array('value'  => 'aaaa'),
                            'statelistCstm'                     => array('value'  => 'aaa1'),
                            'citylistCstm'                      => array('value'  => 'ab1'),
                            'integerCstm'                       => '11',
                            'phoneCstm'                         => '259-784-2069',
                            'radioCstm'                         => array('value' => 'e'),
                            'textCstm'                          => 'This is a test Edit Text',
                            'textareaCstm'                      => 'This is a test Edit TextArea',
                            'urlCstm'                           => 'http://wwww.abc-edit.com')));
            $this->runControllerWithRedirectExceptionAndGetUrl('contracts/default/edit');

            //Check the details if they are saved properly for the custom fields.
            $contractId = self::getModelIdByModelNameAndName('Contract', 'myEditContract');
            $contract   = Contract::getById($contractId);

            //Retrieve the permission of the Contract.
            $explicitReadWriteModelPermissions = ExplicitReadWriteModelPermissionsUtil::
                                                 makeBySecurableItem($contract);
            $readWritePermitables              = $explicitReadWriteModelPermissions->getReadWritePermitables();
            $readOnlyPermitables               = $explicitReadWriteModelPermissions->getReadOnlyPermitables();

            $this->assertEquals($contract->name                       , 'myEditContract');
            $this->assertEquals($contract->amount->value              , '288000');
            $this->assertEquals($contract->amount->currency->id       , $baseCurrency->id);
            $this->assertEquals($contract->account->id                , $accountId);
            $this->assertEquals($contract->probability                , '25');
            $this->assertEquals($contract->stage->value               , 'Qualification');
            $this->assertEquals($contract->source->value              , 'Inbound Call');
            $this->assertEquals($contract->description                , 'This is the Edit Description');
            $this->assertEquals($contract->owner->id                  , $superUserId);
            $this->assertEquals(1                                        , count($readWritePermitables));
            $this->assertEquals(0                                        , count($readOnlyPermitables));
            $this->assertEquals($contract->checkboxCstm               , '0');
            $this->assertEquals($contract->currencyCstm->value        , 40);
            $this->assertEquals($contract->currencyCstm->currency->id , $baseCurrency->id);
            $this->assertEquals($contract->dateCstm                   , $dateAssert);
            $this->assertEquals($contract->datetimeCstm               , $datetimeAssert);
            $this->assertEquals($contract->decimalCstm                , '12');
            $this->assertEquals($contract->picklistCstm->value        , 'b');
            $this->assertEquals($contract->integerCstm                , 11);
            $this->assertEquals($contract->phoneCstm                  , '259-784-2069');
            $this->assertEquals($contract->radioCstm->value           , 'e');
            $this->assertEquals($contract->textCstm                   , 'This is a test Edit Text');
            $this->assertEquals($contract->textareaCstm               , 'This is a test Edit TextArea');
            $this->assertEquals($contract->urlCstm                    , 'http://wwww.abc-edit.com');
            $this->assertEquals($contract->dateCstm                   , $dateAssert);
            $this->assertEquals($contract->datetimeCstm               , $datetimeAssert);
            $this->assertEquals($contract->countrylistCstm->value     , 'aaaa');
            $this->assertEquals($contract->statelistCstm->value       , 'aaa1');
            $this->assertEquals($contract->citylistCstm->value        , 'ab1');
            $this->assertContains('gg'                                   , $contract->multiselectCstm->values);
            $this->assertContains('hh'                                   , $contract->multiselectCstm->values);
            $this->assertContains('reading'                              , $contract->tagcloudCstm->values);
            $this->assertContains('surfing'                              , $contract->tagcloudCstm->values);
            $metadata            = CalculatedDerivedAttributeMetadata::
                                   getByNameAndModelClassName('calcnumber', 'Contract');
            $testCalculatedValue = CalculatedNumberUtil::calculateByFormulaAndModelAndResolveFormat($metadata->getFormula(), $contract);
            $this->assertEquals(132                                      , $testCalculatedValue);
        }

        /**
         * @depends testEditOfTheContractForTheCustomFieldsPlacedForcontractsModule
         */
        public function testWhetherSearchWorksForTheCustomFieldsPlacedForContractsModuleAfterEditingTheContract()
        {
            $super = $this->logoutCurrentUserLoginNewUserAndGetByUsername('super');

            //Retrieve the account id, the super user id and Contract Id.
            $accountId      = self::getModelIdByModelNameAndName ('Account', 'superAccount');
            $superUserId    = $super->id;
            $baseCurrency   = Currency::getByCode(Yii::app()->currencyHelper->getBaseCode());

            //Search a created Contract using the customfields.
            $this->resetPostArray();
            $this->setGetArray(array(
                        'ContractsSearchForm' =>
                            ContractsDesignerWalkthroughHelperUtil::fetchContractsSearchFormGetData($accountId,
                                                                                      $superUserId, $baseCurrency->id),
                        'ajax'                    =>  'list-view')
            );
            $content = $this->runControllerWithNoExceptionsAndGetContent('contracts/default');

            //Assert that the edit Contract exits after the edit and is diaplayed on the search page.
            //$this->assertContains("Displaying 1-1 of 1 result(s).", $content); //removed until we show the count again in the listview.
            $this->assertContains("myEditContract", $content);
        }

        /**
         * @depends testWhetherSearchWorksForTheCustomFieldsPlacedForContractsModuleAfterEditingTheContract
         */
        public function testDeleteOfTheContractUserForTheCustomFieldsPlacedForContractsModule()
        {
            $super = $this->logoutCurrentUserLoginNewUserAndGetByUsername('super');

            //Get the Contract id from the recently edited Contract.
            $contractId = self::getModelIdByModelNameAndName('Contract', 'myEditContract');

            //Set the Contract id so as to delete the Contract.
            $this->setGetArray(array('id' => $contractId));
            $this->runControllerWithRedirectExceptionAndGetUrl('contracts/default/delete');

            //Check wether the Contract is deleted.
            $contract = Contract::getByName('myEditContract');
            $this->assertEquals(0, count($contract));
        }

        /**
         * @depends testDeleteOfTheContractUserForTheCustomFieldsPlacedForContractsModule
         */
        public function testWhetherSearchWorksForTheCustomFieldsPlacedForContractsModuleAfterDeletingTheContract()
        {
            $super = $this->logoutCurrentUserLoginNewUserAndGetByUsername('super');

            //Retrieve the account id, the super user id and Contract Id.
            $accountId      = self::getModelIdByModelNameAndName ('Account', 'superAccount');
            $superUserId    = $super->id;
            $baseCurrency   = Currency::getByCode(Yii::app()->currencyHelper->getBaseCode());

            //Search a created Contract using the customfields.
            $this->resetPostArray();
            $this->setGetArray(array(
                        'ContractsSearchForm' =>
                            ContractsDesignerWalkthroughHelperUtil::fetchContractsSearchFormGetData($accountId,
                                                                                      $superUserId, $baseCurrency->id),
                        'ajax'                    =>  'list-view')
            );
            $content = $this->runControllerWithNoExceptionsAndGetContent('contracts/default');

            //Assert that the edit Contract does not exits after the search.
            $this->assertContains("No results found", $content);
        }

        /**
         * @depends testWhetherSearchWorksForTheCustomFieldsPlacedForContractsModuleAfterDeletingTheContract
         */
        public function testTypeAheadWorksForTheTagCloudFieldPlacedForContractsModule()
        {
            $super = $this->logoutCurrentUserLoginNewUserAndGetByUsername('super');

            //Search a list item by typing in tag cloud attribute.
            $this->resetPostArray();
            $this->setGetArray(array('name' => 'tagcloud',
                                     'term' => 'rea'));
            $content = $this->runControllerWithNoExceptionsAndGetContent('zurmo/default/autoCompleteCustomFieldData');

            //Check if the returned content contains the expected vlaue
            $this->assertContains("reading", $content);
        }

        /**
         * @depends testTypeAheadWorksForTheTagCloudFieldPlacedForContractsModule
         */
        public function testLabelLocalizationForTheTagCloudFieldPlacedForContractsModule()
        {
            Yii::app()->user->userModel =  User::getByUsername('super');
            $languageHelper = new ZurmoLanguageHelper();
            $languageHelper->load();
            $this->assertEquals('en', $languageHelper->getForCurrentUser());
            Yii::app()->user->userModel->language = 'fr';
            $this->assertTrue(Yii::app()->user->userModel->save());
            $languageHelper->setActive('fr');
            $this->assertEquals('fr', Yii::app()->user->getState('language'));

            $super = $this->logoutCurrentUserLoginNewUserAndGetByUsername('super');

            //Search a list item by typing in tag cloud attribute.
            $this->resetPostArray();
            $this->setGetArray(array('name' => 'tagcloud',
                                     'term' => 'surf'));
            $content = $this->runControllerWithNoExceptionsAndGetContent('zurmo/default/autoCompleteCustomFieldData');

            //Check if the returned content contains the expected vlaue
            $this->assertContains("surfing fr", $content);
        }
    }
?>