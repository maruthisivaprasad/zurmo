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

    class ContractsModule extends SecurableModule
    {
        const RIGHT_CREATE_CONTRACTS = 'Create Contracts';
        const RIGHT_DELETE_CONTRACTS = 'Delete Contracts';
        const RIGHT_ACCESS_CONTRACTS = 'Access Contracts Tab';

        public function getDependencies()
        {
            return array(
                'configuration',
                'zurmo',
            );
        }

        public function getRootModelNames()
        {
            return array('Contract');
        }

        public static function getTranslatedRightsLabels()
        {
            $params                                   = LabelUtil::getTranslationParamsForAllModules();
            $labels                                   = array();
            $labels[self::RIGHT_CREATE_CONTRACTS] = Zurmo::t('ContractsModule', 'Create ContractsModulePluralLabel',     $params);
            $labels[self::RIGHT_DELETE_CONTRACTS] = Zurmo::t('ContractsModule', 'Delete ContractsModulePluralLabel',     $params);
            $labels[self::RIGHT_ACCESS_CONTRACTS] = Zurmo::t('ContractsModule', 'Access ContractsModulePluralLabel Tab', $params);
            return $labels;
        }

        public static function getDefaultMetadata()
        {
            $metadata = array();
            $metadata['global'] = array(
                'designerMenuItems' => array(
                    'showFieldsLink' => true,
                    'showGeneralLink' => true,
                    'showLayoutsLink' => true,
                    'showMenusLink' => true,
                ),
                'globalSearchAttributeNames' => array(
                    'name'
                ),
                'stageToProbabilityMapping' => array(
                    'Prospecting'   => 10,
                    'Qualification' => 25,
                    'Negotiating'   => 50,
                    'Verbal'        => 75,
                    'Closed Won'    => 100,
                    'Closed Lost'   => 0,
                ),
                'automaticProbabilityMappingDisabled' => false,
                'tabMenuItems' => array(
                    array(
                        'label'  => "eval:Zurmo::t('ContractsModule', 'ContractsModulePluralLabel', \$translationParams)",
                        'url'    => array('/contracts/default'),
                        'right'  => self::RIGHT_ACCESS_CONTRACTS,
                        'mobile' => true,
                    ),
                ),
                'shortcutsCreateMenuItems' => array(
                    array(
                        'label'  => "eval:Zurmo::t('ContractsModule', 'ContractsModuleSingularLabel', \$translationParams)",
                        'url'    => array('/contracts/default/create'),
                        'right'  => self::RIGHT_CREATE_CONTRACTS,
                        'mobile' => true,
                    ),
                ),
            );
            return $metadata;
        }

        public static function getPrimaryModelName()
        {
            return 'Contract';
        }

        public static function getSingularCamelCasedName()
        {
            return 'Contract';
        }

        protected static function getSingularModuleLabel($language)
        {
            return Zurmo::t('ContractsModule', 'Contract', array(), null, $language);
        }

        protected static function getPluralModuleLabel($language)
        {
            return Zurmo::t('ContractsModule', 'Contracts', array(), null, $language);
        }

        public static function getAccessRight()
        {
            return self::RIGHT_ACCESS_CONTRACTS;
        }

        public static function getCreateRight()
        {
            return self::RIGHT_CREATE_CONTRACTS;
        }

        public static function getDeleteRight()
        {
            return self::RIGHT_DELETE_CONTRACTS;
        }

        public static function getDefaultDataMakerClassName()
        {
            return 'ContractsDefaultDataMaker';
        }

        public static function getDemoDataMakerClassNames()
        {
            return array('ContractsDemoDataMaker');
        }

        public static function getGlobalSearchFormClassName()
        {
            return 'ContractsSearchForm';
        }

        public static function hasPermissions()
        {
            return true;
        }

        public static function isReportable()
        {
            return true;
        }

        public static function canHaveWorkflow()
        {
            return true;
        }

        public static function canHaveContentTemplates()
        {
            return true;
        }

        public static function getStageToProbabilityMappingData()
        {
            $metadata = static::getMetadata();
            if (isset($metadata['global']['stageToProbabilityMapping']))
            {
                return $metadata['global']['stageToProbabilityMapping'];
            }
            return array();
        }

        /**
         * @param string $value
         * @return int
         */
        public static function getProbabilityByStageValue($value)
        {
            assert('is_string($value) || $value == null');
            $stageToProbabilityMapping = self::getStageToProbabilityMappingData();
            if (isset($stageToProbabilityMapping[$value]))
            {
                return $stageToProbabilityMapping[$value];
            }
            return 0;
        }

        public static function isAutomaticProbabilityMappingDisabled()
        {
            $metadata = static::getMetadata();
            if (isset($metadata['global']['automaticProbabilityMappingDisabled']))
            {
                return (bool) $metadata['global']['automaticProbabilityMappingDisabled'];
            }
            return false;
        }
    }
?>
