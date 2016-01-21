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

    class ContractsDefaultController extends ZurmoModuleController
    {
        public function filters()
        {
            $modelClassName   = $this->getModule()->getPrimaryModelName();
            $viewClassName    = $modelClassName . 'EditAndDetailsView';
            return array_merge(parent::filters(),
                array(
                    array(
                        ZurmoBaseController::REQUIRED_ATTRIBUTES_FILTER_PATH . ' + create, createFromRelation, edit',
                        'moduleClassName' => get_class($this->getModule()),
                        'viewClassName'   => $viewClassName,
                   ),
                    array(
                        ZurmoModuleController::ZERO_MODELS_CHECK_FILTER_PATH . ' + list, index',
                        'controller' => $this,
                   ),
               )
            );
        }

        public function actionList()
        {
            $pageSize    = Yii::app()->pagination->resolveActiveForCurrentUserByType(
                           'listPageSize', get_class($this->getModule()));
            $contract = new Contract(false);
            $searchForm  = new ContractsSearchForm($contract);
            $listAttributesSelector = new ListAttributesSelector('ContractsListView', get_class($this->getModule()));
            $searchForm->setListAttributesSelector($listAttributesSelector);
            $dataProvider = $this->resolveSearchDataProvider(
                $searchForm,
                $pageSize,
                null,
                'ContractsSearchView'
            );
            if (isset($_GET['ajax']) && $_GET['ajax'] == 'list-view')
            {
                $mixedView = $this->makeListView(
                    $searchForm,
                    $dataProvider
                );
                $view = new ContractsPageView($mixedView);
            }
            else
            {
                $activeActionElementType = $this->resolveActiveElementTypeForKanbanBoard($searchForm);
                $mixedView = $this->makeActionBarSearchAndListView($searchForm, $dataProvider,
                             'ContractsSecuredActionBarForSearchAndListView', null, $activeActionElementType);
                $view      = new ContractsPageView(ZurmoDefaultViewUtil::
                             makeStandardViewForCurrentUser($this, $mixedView));
            }
            echo $view->render();
        }

        public function actionDetails($id, $kanbanBoard = false)
        {
            $contract = static::getModelAndCatchNotFoundAndDisplayError('Contract', intval($id));
            ControllerSecurityUtil::resolveAccessCanCurrentUserReadModel($contract);
            AuditEvent::logAuditEvent('ZurmoModule', ZurmoModule::AUDIT_EVENT_ITEM_VIEWED, array(strval($contract), 'ContractsModule'), $contract);
            if (KanbanUtil::isKanbanRequest() === false)
            {
                $breadCrumbView          = StickySearchUtil::resolveBreadCrumbViewForDetailsControllerAction($this, 'ContractsSearchView', $contract);
                $detailsAndRelationsView = $this->makeDetailsAndRelationsView($contract, 'ContractsModule',
                                                                          'ContractDetailsAndRelationsView',
                                                                          Yii::app()->request->getRequestUri(), $breadCrumbView);
                $view = new ContractsPageView(ZurmoDefaultViewUtil::
                                             makeStandardViewForCurrentUser($this, $detailsAndRelationsView));
            }
            else
            {
                $view = TasksUtil::resolveTaskKanbanViewForRelation($contract, $this->getModule()->getId(), $this,
                                                                        'TasksForContractKanbanView', 'ContractsPageView');
            }
            echo $view->render();
        }

        public function actionCreate()
        {
            $this->actionCreateByModel(new Contract());
        }

        public function actionCreateFromRelation($relationAttributeName, $relationModelId, $relationModuleId, $redirectUrl)
        {
            $this->getsessionvalues($_GET['relationModelId']);
            $contract = $this->resolveNewModelByRelationInformation( new Contract(),
                                                                                $relationAttributeName,
                                                                                (int)$relationModelId,
                                                                                $relationModuleId);
            $this->actionCreateByModel($contract, $redirectUrl);
        }

        protected function actionCreateByModel(Contract $contract, $redirectUrl = null)
        {
            $titleBarAndEditView = $this->makeEditAndDetailsView(
                                            $this->attemptToSaveModelFromPost($contract, $redirectUrl), 'Edit');
            $view = new ContractsPageView(ZurmoDefaultViewUtil::
                                         makeStandardViewForCurrentUser($this, $titleBarAndEditView));
            echo $view->render();
        }

        public function getsessionvalues($relationid)
        {
            $sql = "select * from opportunity where id=".$relationid;
            $rec = Yii::app()->db->createCommand($sql)->queryRow();
            
            $rec_t['value'] = $rec_c['value'] = $rec_v['value'] = $rec_a['value'] = $rec_i['value'] = $rec_p['value'] = $bulkval = '';
            if(isset($rec['totalbulkpricstm_currencyvalue_id']) && !empty($rec['totalbulkpricstm_currencyvalue_id'])) {
                //get totalbuilprice
                $sql_t = "select * from currencyvalue where id=".$rec['totalbulkpricstm_currencyvalue_id'];
                $rec_t = Yii::app()->db->createCommand($sql_t)->queryRow();
            }
            if(isset($rec['constructcoscstm_currencyvalue_id']) && !empty($rec['constructcoscstm_currencyvalue_id'])) {
                $sql_c = "select * from currencyvalue where id=".$rec['constructcoscstm_currencyvalue_id'];
                $rec_c = Yii::app()->db->createCommand($sql_c)->queryRow();
            }
            if(isset($rec['vidpricingcscstm_currencyvalue_id']) && !empty($rec['vidpricingcscstm_currencyvalue_id'])) {
                $sql_v = "select * from currencyvalue where id=".$rec['vidpricingcscstm_currencyvalue_id'];
                $rec_v = Yii::app()->db->createCommand($sql_v)->queryRow();
            }
            if(isset($rec['alarmbulkcstcstm_currencyvalue_id']) && !empty($rec['alarmbulkcstcstm_currencyvalue_id'])) {
                $sql_a = "select * from currencyvalue where id=".$rec['alarmbulkcstcstm_currencyvalue_id'];
                $rec_a = Yii::app()->db->createCommand($sql_a)->queryRow();
            }
            if(isset($rec['internetbulkcstm_currencyvalue_id']) && !empty($rec['internetbulkcstm_currencyvalue_id'])) {
                $sql_i = "select * from currencyvalue where id=".$rec['internetbulkcstm_currencyvalue_id'];
                $rec_i = Yii::app()->db->createCommand($sql_i)->queryRow();
            }
            if(isset($rec['phonebulkcstcstm_currencyvalue_id']) && !empty($rec['phonebulkcstcstm_currencyvalue_id'])) {
                $sql_p = "select * from currencyvalue where id=".$rec['phonebulkcstcstm_currencyvalue_id'];
                $rec_p = Yii::app()->db->createCommand($sql_p)->queryRow();
            }
            
            if(isset($rec['bulkservprcscstm_multiplevaluescustomfield_id']) && !empty($rec['bulkservprcscstm_multiplevaluescustomfield_id'])) {
                $sql_va = "select * from customfieldvalue where multiplevaluescustomfield_id=".$rec['bulkservprcscstm_multiplevaluescustomfield_id'];
                $rec_va = Yii::app()->db->createCommand($sql_va)->queryAll();
                foreach($rec_va as $key=>$value)
                {
                    $bulkval .= $value['value'].",";
                }
                $bulkval = rtrim($bulkval, ",");
            }
            $getopportunity = Opportunity::getById(intval($relationid));
            $getaccount = Account::getById(intval($getopportunity->account->id));
            $_SESSION['unitsCstmCstm'] = !empty($getaccount->unitsCstmCstm) ? $getaccount->unitsCstmCstm : $_SESSION['unitsCstmCstm'] * 1;
            $_SESSION['totalbulkpricstm'] = !empty($rec_t['value']) ? $rec_t['value'] : 1;
            $_SESSION['totalcostprccstm'] = !empty($rec_c ['value']) ?  $_SESSION['unitsCstmCstm'] * $rec_c ['value'] : 1;
            $_SESSION['videopricstm'] = !empty($rec_v['value']) ? $rec_v['value'] : 0;
            $_SESSION['alarampricstm'] = !empty($rec_a['value']) ? $rec_a['value'] : 0;
            $_SESSION['phonepricstm'] = !empty($rec_p['value']) ? $rec_p['value'] : 0;
            $_SESSION['internetpricstm'] = !empty($rec_i['value']) ? $rec_i['value'] : 0;
            $_SESSION['bulkval'] = $bulkval;
            if($rec['closedate']!='')
            {
                $opportunity_closedate = explode("-", $rec['closedate']);
                if(!empty($opportunity_closedate))
                    $_SESSION['opportunity_closedate'] = $opportunity_closedate[1]."/".$opportunity_closedate[2]."/".$opportunity_closedate[0];
            }
        }

        public function actionEdit($id, $redirectUrl = null)
        {
            $contract = Contract::getById(intval($id));
            $sql = "select * from contract_opportunity where contract_id=".$id;
            $rec = Yii::app()->db->createCommand($sql)->queryRow();
            if(!empty($rec) && !empty($rec['opportunity_id']))
                $this->getsessionvalues($rec['opportunity_id']);
            ControllerSecurityUtil::resolveAccessCanCurrentUserWriteModel($contract);
            $this->processEdit($contract, $redirectUrl);
        }

        public function actionCopy($id)
        {
            $copyToContract  = new Contract();
            $postVariableName   = get_class($copyToContract);
            if (!isset($_POST[$postVariableName]))
            {
                $contract    = Contract::getById((int)$id);
                ControllerSecurityUtil::resolveAccessCanCurrentUserReadModel($contract);
                ZurmoCopyModelUtil::copy($contract, $copyToContract);
            }
            $this->processEdit($copyToContract);
        }

        protected function processEdit(Contract $contract, $redirectUrl = null)
        {
            $view = new ContractsPageView(ZurmoDefaultViewUtil::
                                         makeStandardViewForCurrentUser($this,
                                             $this->makeEditAndDetailsView(
                                                        $this->attemptToSaveModelFromPost($contract, $redirectUrl),
                                                        'Edit')));
            echo $view->render();
        }

        /**
         * Action for displaying a mass edit form and also action when that form is first submitted.
         * When the form is submitted, in the event that the quantity of models to update is greater
         * than the pageSize, then once the pageSize quantity has been reached, the user will be
         * redirected to the makeMassEditProgressView.
         * In the mass edit progress view, a javascript refresh will take place that will call a refresh
         * action, usually massEditProgressSave.
         * If there is no need for a progress view, then a flash message will be added and the user will
         * be redirected to the list view for the model.  A flash message will appear providing information
         * on the updated records.
         * @see Controler->makeMassEditProgressView
         * @see Controller->processMassEdit
         * @see
         */
        public function actionMassEdit()
        {
            $pageSize = Yii::app()->pagination->resolveActiveForCurrentUserByType(
                            'massEditProgressPageSize');
            $contract = new Contract(false);
            $activeAttributes = $this->resolveActiveAttributesFromMassEditPost();
            $dataProvider = $this->getDataProviderByResolvingSelectAllFromGet(
                new ContractsSearchForm($contract),
                $pageSize,
                Yii::app()->user->userModel->id,
                null,
                'ContractsSearchView');
            $selectedRecordCount = static::getSelectedRecordCountByResolvingSelectAllFromGet($dataProvider);
            $contract = $this->processMassEdit(
                $pageSize,
                $activeAttributes,
                $selectedRecordCount,
                'ContractsPageView',
                $contract,
                ContractsModule::getModuleLabelByTypeAndLanguage('Plural'),
                $dataProvider
            );
            $massEditView = $this->makeMassEditView(
                $contract,
                $activeAttributes,
                $selectedRecordCount,
                ContractsModule::getModuleLabelByTypeAndLanguage('Plural')
            );
            $view = new ContractsPageView(ZurmoDefaultViewUtil::
                                         makeStandardViewForCurrentUser($this, $massEditView));
            echo $view->render();
        }

        /**
         * Action called in the event that the mass edit quantity is larger than the pageSize.
         * This action is called after the pageSize quantity has been updated and continues to be
         * called until the mass edit action is complete.  For example, if there are 20 records to update
         * and the pageSize is 5, then this action will be called 3 times.  The first 5 are updated when
         * the actionMassEdit is called upon the initial form submission.
         */
        public function actionMassEditProgressSave()
        {
            $pageSize = Yii::app()->pagination->resolveActiveForCurrentUserByType(
                            'massEditProgressPageSize');
            $contract = new Contract(false);
            $dataProvider = $this->getDataProviderByResolvingSelectAllFromGet(
                new ContractsSearchForm($contract),
                $pageSize,
                Yii::app()->user->userModel->id,
                null,
                'ContractsSearchView'
            );
            $this->processMassEditProgressSave(
                'Contract',
                $pageSize,
                ContractsModule::getModuleLabelByTypeAndLanguage('Plural'),
                $dataProvider
            );
        }

        /**
         * Action for displaying a mass delete form and also action when that form is first submitted.
         * When the form is submitted, in the event that the quantity of models to delete is greater
         * than the pageSize, then once the pageSize quantity has been reached, the user will be
         * redirected to the makeMassDeleteProgressView.
         * In the mass delete progress view, a javascript refresh will take place that will call a refresh
         * action, usually makeMassDeleteProgressView.
         * If there is no need for a progress view, then a flash message will be added and the user will
         * be redirected to the list view for the model.  A flash message will appear providing information
         * on the delete records.
         * @see Controler->makeMassDeleteProgressView
         * @see Controller->processMassDelete
         * @see
         */
        public function actionMassDelete()
        {
            $pageSize = Yii::app()->pagination->resolveActiveForCurrentUserByType(
                            'massDeleteProgressPageSize');
            $contract = new Contract(false);

            $activeAttributes = $this->resolveActiveAttributesFromMassDeletePost();
            $dataProvider = $this->getDataProviderByResolvingSelectAllFromGet(
                new ContractsSearchForm($contract),
                $pageSize,
                Yii::app()->user->userModel->id,
                null,
                'ContractsSearchView'
            );
            $selectedRecordCount = static::getSelectedRecordCountByResolvingSelectAllFromGet($dataProvider);
            $contract = $this->processMassDelete(
                $pageSize,
                $activeAttributes,
                $selectedRecordCount,
                'ContractsPageView',
                $contract,
                ContractsModule::getModuleLabelByTypeAndLanguage('Plural'),
                $dataProvider
            );
            $massDeleteView = $this->makeMassDeleteView(
                $contract,
                $activeAttributes,
                $selectedRecordCount,
                ContractsModule::getModuleLabelByTypeAndLanguage('Plural')
            );
            $view = new ContractsPageView(ZurmoDefaultViewUtil::
                                         makeStandardViewForCurrentUser($this, $massDeleteView));
            echo $view->render();
        }

        /**
         * Action called in the event that the mass delete quantity is larger than the pageSize.
         * This action is called after the pageSize quantity has been delted and continues to be
         * called until the mass delete action is complete.  For example, if there are 20 records to delete
         * and the pageSize is 5, then this action will be called 3 times.  The first 5 are updated when
         * the actionMassDelete is called upon the initial form submission.
         */
        public function actionMassDeleteProgress()
        {
            $pageSize = Yii::app()->pagination->resolveActiveForCurrentUserByType(
                            'massDeleteProgressPageSize');
            $contract = new Contract(false);
            $dataProvider = $this->getDataProviderByResolvingSelectAllFromGet(
                new ContractsSearchForm($contract),
                $pageSize,
                Yii::app()->user->userModel->id,
                null,
                'ContractsSearchView'
            );
            $this->processMassDeleteProgress(
                'Contract',
                $pageSize,
                ContractsModule::getModuleLabelByTypeAndLanguage('Plural'),
                $dataProvider
            );
        }

        public function actionModalList()
        {
            $modalListLinkProvider = new SelectFromRelatedEditModalListLinkProvider(
                                            $_GET['modalTransferInformation']['sourceIdFieldId'],
                                            $_GET['modalTransferInformation']['sourceNameFieldId'],
                                            $_GET['modalTransferInformation']['modalId']
            );
            echo ModalSearchListControllerUtil::setAjaxModeAndRenderModalSearchList($this, $modalListLinkProvider);
        }

        public function actionDelete($id)
        {
            $contract = Contract::GetById(intval($id));
            $contract->delete();
            $this->redirect(array($this->getId() . '/index'));
        }

        /**
         * Override to provide an Contract specific label for the modal page title.
         * @see ZurmoModuleController::actionSelectFromRelatedList()
         */
        public function actionSelectFromRelatedList($portletId,
                                                    $uniqueLayoutId,
                                                    $relationAttributeName,
                                                    $relationModelId,
                                                    $relationModuleId,
                                                    $stateMetadataAdapterClassName = null)
        {
            parent::actionSelectFromRelatedList($portletId,
                                                    $uniqueLayoutId,
                                                    $relationAttributeName,
                                                    $relationModelId,
                                                    $relationModuleId);
        }

        protected static function getSearchFormClassName()
        {
            return 'ContractsSearchForm';
        }

        public function actionExport()
        {
            $this->export('ContractsSearchView');
        }
    }
?>