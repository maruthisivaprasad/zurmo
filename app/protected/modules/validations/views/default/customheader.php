<!DOCTYPE html>
<html class="zurmo" lang="en"><!--<![endif]-->
    <head><meta charset="utf-8"><meta http-equiv="X-UA-Compatible" content="IE=edge" />
        <meta name="viewport"  content="width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no">
        <meta name="apple-mobile-web-app-capable" content="yes" />
        <link rel="apple-touch-icon" sizes="144x144" href="<?php echo Yii::app()->request->baseUrl;?>/themes/default/images/touch-icon-iphone4.png" />
        <style>@font-face{font-family: 'zurmo_gamification_symbly_rRg';
        src: url('<?php echo Yii::app()->request->baseUrl;?>/themes/default/fonts/zurmogamificationsymblyregular-regular-webfont.eot');
        src: url('<?php echo Yii::app()->request->baseUrl;?>/themes/default/fonts/zurmogamificationsymblyregular-regular-webfont.eot?#iefix') format('embedded-opentype'), url('<?php echo Yii::app()->request->baseUrl;?>/themes/default/fonts/zurmogamificationsymblyregular-regular-webfont.woff') format('woff'), url('<?php echo Yii::app()->request->baseUrl;?>/themes/default/fonts/zurmogamificationsymblyregular-regular-webfont.ttf') format('truetype'), url('<?php echo Yii::app()->request->baseUrl;?>/themes/default/fonts/zurmogamificationsymblyregular-regular-webfont.svg#zurmo_gamification_symbly_rRg') format('svg');font-weight: normal;font-style: normal;unicode-range: U+00-FFFF;}</style>
        <link rel="stylesheet/less" type="text/css" id="default-theme" href="<?php echo Yii::app()->request->baseUrl;?>/themes/default/less/default-theme.less"/>
        <link rel="shortcut icon" href="<?php echo Yii::app()->request->baseUrl;?>/themes/default/ico/favicon.ico" />
<script type="text/javascript" src="<?php echo Yii::app()->request->baseUrl;?>/themes/default/js/jquery.min.js"></script>
<script type="text/javascript" src="<?php echo Yii::app()->request->baseUrl;?>/themes/default/js/jui/js/jquery-ui.min.js"></script>
<script type="text/javascript" src="<?php echo Yii::app()->request->baseUrl;?>/themes/default/js/jquery.cookie.js"></script>
<script type="text/javascript" src="<?php echo Yii::app()->request->baseUrl;?>/themes/default/js/jquery.ba-bbq.min.js"></script>
<script type="text/javascript" src="<?php echo Yii::app()->request->baseUrl;?>/themes/default/js/jquery.yii.js"></script>
<script type="text/javascript" src="<?php echo Yii::app()->request->baseUrl;?>/themes/default/js/less-1.2.0.min.js"></script>
<script type="text/javascript" src="<?php echo Yii::app()->request->baseUrl;?>/themes/default/js/ZurmoDialog.js"></script>
<script type="text/javascript" src="<?php echo Yii::app()->request->baseUrl;?>/themes/default/js/interactions.js"></script>
<script type="text/javascript" src="<?php echo Yii::app()->request->baseUrl;?>/themes/default/js/mobile-interactions.js"></script>
<script type="text/javascript" src="<?php echo Yii::app()->request->baseUrl;?>/themes/default/js/jquery.truncateText.js"></script>
<script type="text/javascript" src="<?php echo Yii::app()->request->baseUrl;?>/themes/default/js/myscript.js"></script>
<script type="text/javascript" src="<?php echo Yii::app()->request->baseUrl;?>/themes/default/js/juiMultiSelect/jquery.multiselect.js"></script>
<script type="text/javascript" src="<?php echo Yii::app()->request->baseUrl;?>/themes/default/js/dropDownInteractions.js"></script>
<script type="text/javascript" src="<?php echo Yii::app()->request->baseUrl;?>/themes/default/js/jnotify/jquery.jnotify.js"></script>
<script type="text/javascript">
/*<![CDATA[*/

            var desktopNotifications =
            {
                notify:function(image, title, body)
                {
                    
                    return false;
                },
                isSupported:function()
                {
                    if (typeof window.webkitNotifications != 'undefined')
                    {
                        return true
                    }
                    else
                    {
                        return false
                    }
                },
                requestAutorization:function()
                {
                    if (typeof window.webkitNotifications != 'undefined')
                    {
                        if (window.webkitNotifications.checkPermission() == 1)
                        {
                            window.webkitNotifications.requestPermission();
                        }
                        else if (window.webkitNotifications.checkPermission() == 2)
                        {
                            alert('You have blocked desktop notifications for this browser.');
                        }
                        else
                        {
                            alert('You have already activated desktop notifications for Chrome');
                        }
                    }
                    else
                    {
                        alert('This is only available in Chrome.');
                    }
                }
            };
            
$(document).ready(function()
{
    $('#FlashMessageBar').jnotifyInizialize(
    {
        oneAtTime: false,
        appendType: 'append'
    }
    );
}
);
/*]]>*/
</script>
<title>ZurmoCRM - Opportunities</title></head><body class="blue"><header id="HeaderView" class="HeaderView"><div class="container clearfix"><div class="logo-and-search"><a class="clearfix" id="corp-logo" href="<?php echo Yii::app()->request->baseUrl;?>/index.php/home/default"><img src="<?php echo Yii::app()->request->baseUrl;?>/themes/default/images/Zurmo_logo.png" alt="Zurmo Logo" height="32" width="107" /><span>Demo Company Inc.</span></a><div id="app-search" class="clearfix"><select class="ignore-style" id="globalSearchScope" multiple="multiple" style="display:none;" size="4" name="globalSearchScope[]">
<option value="All" selected="selected">All</option>
<option value="accounts">Accounts</option>
<option value="contacts">Contacts</option>
<option value="leads">Leads</option>
<option value="opportunities">Opportunities</option>
<option value="contracts">Contracts</option>
<option value="projects">Projects</option>
</select><input class="global-search global-search-hint" onfocus="$(this).removeClass(&quot;global-search-hint&quot;); $(this).val(&quot;&quot;);" onblur="$(this).val(&quot;&quot;)" id="globalSearchInput" type="text" value="Search by name, phone, or e-mail" name="globalSearchInput" /><span class="z-spinner"></span></div></div><div class="user-actions clearfix"><ul id="settings-header-menu" class="user-menu-item nav">
<li class="parent last"><a href="javascript:void(0);"><span>Administration</span></a>
<ul>
<li><a href="<?php echo Yii::app()->request->baseUrl;?>/index.php/configuration"><span>Administration</span></a></li>
<li><a href="<?php echo Yii::app()->request->baseUrl;?>/index.php/designer/default"><span>Designer</span></a></li>
<li><a href="<?php echo Yii::app()->request->baseUrl;?>/index.php/import/default"><span>Import</span></a></li>
<li><a href="<?php echo Yii::app()->request->baseUrl;?>/index.php/users/default"><span>Users</span></a></li>
<li><a href="http://www.zurmo.com/needSupport.php"><span>Need Support?</span></a></li>
<li class="last"><a href="<?php echo Yii::app()->request->baseUrl;?>/index.php/zurmo/default/about"><span>About Zurmo</span></a></li>
</ul>
</li>
</ul><div id="header-game-dashboard-link-wrapper" class="user-menu-item"><a id="header-game-dashboard-link" href="#">∂</a></div><div id="header-calendar-link-wrapper" class="user-menu-item"><a id="header-calendar-link" href="<?php echo Yii::app()->request->baseUrl;?>/index.php/calendars/default/details">U</a></div><ul id="user-header-menu" class="user-menu-item nav">
<li class="parent last"><a href="javascript:void(0);"><span class="avatar-holder">super</span><span class="avatar-holder"><img class="gravatar" width="25" height="25" src="<?php echo Yii::app()->request->baseUrl;?>/themes/default/images/offline_user.png" alt="Super User" /></span></a>
<ul>
<li><a href="<?php echo Yii::app()->request->baseUrl;?>/index.php/users/default/profile"><span>My Profile</span></a></li>
<li><a href="<?php echo Yii::app()->request->baseUrl;?>/index.php/gamification/default/leaderboard"><span>Leaderboard</span></a></li>
<li><a href="<?php echo Yii::app()->request->baseUrl;?>/index.php/emailMessages/default/matchingList"><span>Data Cleanup</span></a></li>
<li class="last"><a href="<?php echo Yii::app()->request->baseUrl;?>/index.php/zurmo/default/logout"><span>Sign out</span></a></li>
</ul>
</li>
</ul><ul id="ShortcutsMenu" class="nav">
<li class="parent last active"><a href="javascript:void(0);"><span>Create</span></a>
<ul>
<li><a href="<?php echo Yii::app()->request->baseUrl;?>/index.php/accounts/default/create"><span>Account</span></a></li>
<li><a href="<?php echo Yii::app()->request->baseUrl;?>/index.php/contacts/default/create"><span>Contact</span></a></li>
<li><a href="<?php echo Yii::app()->request->baseUrl;?>/index.php/conversations/default/create"><span>Conversation</span></a></li>
<li><a href="<?php echo Yii::app()->request->baseUrl;?>/index.php/leads/default/create"><span>Leads</span></a></li>
<li><a href="<?php echo Yii::app()->request->baseUrl;?>/index.php/missions/default/create"><span>Mission</span></a></li>
<li><a href="<?php echo Yii::app()->request->baseUrl;?>/index.php/opportunities/default/create"><span>Opportunity</span></a></li>
<li><a href="<?php echo Yii::app()->request->baseUrl;?>/index.php/reports/default/selectType"><span>Report</span></a></li>
<li><a href="#" id="yt0"><span>Task</span></a></li>
<li class="last"><a href="<?php echo Yii::app()->request->baseUrl;?>/index.php/contracts/default/create"><span>Contract</span></a></li>
</ul>
</li>
</ul></div></div></header><section class="AppContainer container clearfix"><nav class="AppNavigation"><div id="MenuView"><ul class="nav">
<li id="home" class="type-home"><a href="<?php echo Yii::app()->request->baseUrl;?>/index.php/home/default"><i></i><span>Home</span></a></li>
<li id="mashableInbox" class="type-mashableInbox"><a href="<?php echo Yii::app()->request->baseUrl;?>/index.php/mashableInbox/default"><i></i><span>Inbox</span><span class="unread-inbox-count">9</span></a></li>
<li id="accounts" class="type-accounts"><a href="<?php echo Yii::app()->request->baseUrl;?>/index.php/accounts/default"><i></i><span>Accounts</span></a></li>
<li id="leads" class="type-leads"><a href="<?php echo Yii::app()->request->baseUrl;?>/index.php/leads/default"><i></i><span>Leads</span></a></li>
<li id="contacts" class="type-contacts"><a href="<?php echo Yii::app()->request->baseUrl;?>/index.php/contacts/default"><i></i><span>Contacts</span></a></li>
<li id="opportunities" class="type-opportunities"><a href="<?php echo Yii::app()->request->baseUrl;?>/index.php/opportunities/default"><i></i><span>Opportunities</span></a></li>
<li id="marketing" class="hidden-nav-item type-marketing"><a href="<?php echo Yii::app()->request->baseUrl;?>/index.php/marketing/default/dashboardDetails"><i></i><span>Marketing</span></a></li>
<li id="projects" class="hidden-nav-item type-projects"><a href="<?php echo Yii::app()->request->baseUrl;?>/index.php/projects/default/dashboardDetails"><i></i><span>Projects</span></a></li>
<li id="products" class="hidden-nav-item type-products"><a href="<?php echo Yii::app()->request->baseUrl;?>/index.php/products/default"><i></i><span>Products</span></a></li>
<li id="reports" class="hidden-nav-item type-reports"><a href="<?php echo Yii::app()->request->baseUrl;?>/index.php/reports/default"><i></i><span>Reports</span></a></li>
<li id="contracts" class="hidden-nav-item type-contracts last"><a href="<?php echo Yii::app()->request->baseUrl;?>/index.php/contracts/default"><i></i><span>Contracts</span></a></li>
</ul><a class="toggle-hidden-nav-items"></a></div><div id="RecentlyViewedView"><h3>Recently Viewed</h3><ul class="nav">
<li class="type-OpportunitiesModule"><a href="<?php echo Yii::app()->request->baseUrl;?>/index.php/opportunities/default/details?id=16"><i></i><span>Test New opportunity</span></a></li>
<li class="type-ContractsModule"><a href="<?php echo Yii::app()->request->baseUrl;?>/index.php/contracts/default/details?id=10"><i></i><span>Test New contract</span></a></li>
<li class="type-OpportunitiesModule"><a href="<?php echo Yii::app()->request->baseUrl;?>/index.php/opportunities/default/details?id=15"><i></i><span>test opp</span></a></li>
<li class="type-AccountsModule"><a href="<?php echo Yii::app()->request->baseUrl;?>/index.php/accounts/default/details?id=9"><i></i><span>Test New Account</span></a></li>
<li class="type-ContractsModule"><a href="<?php echo Yii::app()->request->baseUrl;?>/index.php/contracts/default/details?id=9"><i></i><span>asdf</span></a></li>
<li class="type-OpportunitiesModule"><a href="<?php echo Yii::app()->request->baseUrl;?>/index.php/opportunities/default/details?id=3"><i></i><span>Consulting Services</span></a></li>
<li class="type-AccountsModule"><a href="<?php echo Yii::app()->request->baseUrl;?>/index.php/accounts/default/details?id=5"><i></i><span>Allied Biscuit</span></a></li>
<li class="type-ContractsModule"><a href="<?php echo Yii::app()->request->baseUrl;?>/index.php/contracts/default/details?id=5"><i></i><span>dgaf</span></a></li>
<li class="type-AccountsModule"><a href="<?php echo Yii::app()->request->baseUrl;?>/index.php/accounts/default/details?id=3"><i></i><span>Big T Burgers and Fries</span></a></li>
<li class="type-ContractsModule last"><a href="<?php echo Yii::app()->request->baseUrl;?>/index.php/contracts/default/details?id=7"><i></i><span>dssssssss</span></a></li>
</ul></div><div class="ui-chooser"><a title="Collapse or Expand" href="<?php echo Yii::app()->request->baseUrl;?>/index.php/zurmo/default/toggleCollapse?returnUrl=<?php echo Yii::app()->request->baseUrl;?>/index.php/opportunities/default/create"><i class="icon-collapse"></i></a><div class="device"><a title="Show Mobile" href="<?php echo Yii::app()->request->baseUrl;?>/index.php/zurmo/default/userInterface?userInterface=Mobile"><i class="icon-mobile"></i></a><a title="Show Full" href="<?php echo Yii::app()->request->baseUrl;?>/index.php/zurmo/default/userInterface?userInterface=Desktop"><i class="icon-desktop active"></i></a></div></div></nav><div id="OpportunityEditAndDetailsView" class="AppContent SecuredEditAndDetailsView EditAndDetailsView DetailsView ModelView ConfigurableMetadataView MetadataView">
