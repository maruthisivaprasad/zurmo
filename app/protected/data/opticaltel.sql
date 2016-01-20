-- phpMyAdmin SQL Dump
-- version 4.2.11
-- http://www.phpmyadmin.net
--
-- Host: 127.0.0.1
-- Generation Time: Jan 20, 2016 at 12:41 PM
-- Server version: 5.6.21
-- PHP Version: 5.6.3

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;

--
-- Database: `opticaltel`
--

DELIMITER $$
--
-- Procedures
--
CREATE DEFINER=`root`@`localhost` PROCEDURE `cache_securableitem_actual_permissions_for_permitable`(
                                in _securableitem_id  int(11),
                                in _permitable_id     int(11),
                                in _allow_permissions tinyint,
                                in _deny_permissions  tinyint
                              )
begin
                # Tables cannot be created inside stored routines
                # so this cannot automatically create the cache
                # table if it doesn't exist. So it is done when
                # the stored routines are created.
                insert into actual_permissions_cache
                values (_securableitem_id, _permitable_id, _allow_permissions, _deny_permissions);
            end$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `clear_cache_actual_rights`()
    READS SQL DATA
begin
                delete from actual_rights_cache;
            end$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `clear_cache_all_actual_permissions`()
    READS SQL DATA
begin
                delete from actual_permissions_cache;
            end$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `clear_cache_named_securable_all_actual_permissions`()
    READS SQL DATA
begin
                delete from named_securable_actual_permissions_cache;
            end$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `clear_cache_securableitem_actual_permissions`(
                                in _securableitem_id int(11)
                              )
begin
                delete from actual_permissions_cache
                where securableitem_id = _securableitem_id;
            end$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `create_campaign_items`(campaign_id int, marketing_list_id int, processed int)
begin
                insert into `campaignitem` (`id`, `processed`, `campaign_id`, `contact_id`)
                    select null as id, processed as `processed`, campaign_id as `campaign_id`, `marketinglistmember`.`contact_id`
                        from `marketinglistmember`
                            left join `campaignitem` on `campaignitem`.`contact_id` = `marketinglistmember`.`contact_id`
                                and `campaignitem`.`campaign_id` = campaign_id
                            left join `contact` on `contact`.`id` = `marketinglistmember`.`contact_id`
                        where (`marketinglistmember`.`marketinglist_id` = marketing_list_id
                                and `campaignitem`.`id` is null and `contact`.`id` is not null);
            end$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `decrement_count`(
                                in munge_table_name  varchar(255),
                                in _securableitem_id int(11),
                                in item_id           int(11),
                                in _type             char
                             )
begin

                update munge_table_name
                set count = count - 1
                where securableitem_id = _securableitem_id and
                      munge_id         = concat(_type, item_id);
            end$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `decrement_parent_roles_counts`(
                                in munge_table_name varchar(255),
                                in securableitem_id int(11),
                                in role_id          int(11)
                              )
begin
                declare parent_role_id int(11);

                select role_id
                into   parent_role_id
                from   role
                where  id = role_id;
                if parent_role_id is not null then
                    call decrement_count              (munge_table_name, securableitem_id, parent_role_id);
                    call decrement_parent_roles_counts(munge_table_name, securableitem_id, parent_role_id);
                end if;
            end$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `duplicate_filemodels`(related_model_type varchar(255), related_model_id int,
                                                new_model_type varchar(255), new_model_id int, user_id int,
                                                 now_timestamp datetime)
begin
                insert into `filemodel` (`id`, `name`, `size`, `type`, `item_id`,
                                                    `filecontent_id`, `relatedmodel_id`, `relatedmodel_type`)
                    select null as `id`, `name`, `size`, `type`, (select create_item(user_id, now_timestamp)) as `item_id`, `filecontent_id`,
                        new_model_id as `relatedmodel_id`, new_model_type as `relatedmodel_type`
                    from `filemodel`
                    where `relatedmodel_type` = related_model_type and `relatedmodel_id` = related_model_id;
            end$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `generate_campaign_items`(active_status int, processing_status int, now_timestamp datetime)
begin
                  declare loop0_eof boolean default false;
                  declare campaign_id int(11);
                  declare marketinglist_id int(11);

                  declare cursor0 cursor for select `campaign`.`id`, `campaign`.`marketinglist_id` from `campaign`
                        where ((`campaign`.`status` = active_status) and (`campaign`.`sendondatetime` < now_timestamp));
                  declare continue handler for not found set loop0_eof = TRUE;
                  open cursor0;
                        loop0: loop
                              fetch cursor0 into campaign_id, marketinglist_id;
                              if loop0_eof then
                                    leave loop0;
                              end if;
                              call create_campaign_items(campaign_id, marketinglist_id, 0);
                              update `campaign` set `status` = processing_status where id = campaign_id;
                        end loop loop0;
                  close cursor0;
            end$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `get_group_inherited_actual_right_ignoring_everyone`(
                                in  _group_id   int(11),
                                in  module_name varchar(255),
                                in  right_name  varchar(255),
                                out result      tinyint
                              )
begin
                declare parent_group_id int(11);

                set result = 0;
                select _group._group_id
                into   parent_group_id
                from   _group
                where  id = _group_id;
                if parent_group_id is not null then
                    call get_group_inherited_actual_right_ignoring_everyone(parent_group_id, module_name, right_name, result);
                    select result |
                           get_group_explicit_actual_right(parent_group_id, module_name, right_name)
                    into result;
                    if (result & 2) = 2 then
                        set result = 2;
                    end if;
                end if;
            end$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `get_securableitem_cached_actual_permissions_for_permitable`(
                                in  _securableitem_id  int(11),
                                in  _permitable_id     int(11),
                                out _allow_permissions tinyint,
                                out _deny_permissions  tinyint
                             )
begin
                select allow_permissions, deny_permissions
                into   _allow_permissions, _deny_permissions
                from   actual_permissions_cache
                where  securableitem_id = _securableitem_id and
                       permitable_id    = _permitable_id;
            end$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `get_securableitem_explicit_actual_permissions_for_permitable`(
                                in  _securableitem_id int(11),
                                in  _permitable_id    int(11),
                                out allow_permissions tinyint,
                                out deny_permissions  tinyint
                              )
begin
                select bit_or(permissions)
                into   allow_permissions
                from   permission
                where  type = 1                          and
                       permitable_id    = _permitable_id and
                       securableitem_id = _securableitem_id;

                select bit_or(permissions)
                into   deny_permissions
                from   permission
                where  type = 2                       and
                       permitable_id = _permitable_id and
                securableitem_id = _securableitem_id;
            end$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `get_securableitem_explicit_inherited_permissions_for_permitable`(
                                in  _securableitem_id int(11),
                                in  _permitable_id    int(11),
                                out allow_permissions tinyint,
                                out deny_permissions  tinyint
                              )
begin
                declare permissions_permitable_id int(11);
                declare _type, _permissions, permission_applies tinyint;
                declare no_more_records tinyint default 0;
                declare permitable_id_type_and_permissions cursor for
                    select permitable_id, type, bit_or(permissions)
                    from   permission
                    where  securableitem_id = _securableitem_id
                    group  by permitable_id, type;
                declare continue handler for not found
                    set no_more_records = 1;

                set allow_permissions = 0;
                set deny_permissions  = 0;
                open permitable_id_type_and_permissions;
                fetch permitable_id_type_and_permissions into
                            permissions_permitable_id, _type, _permissions;
                # The query will return at most one row with the allow bits and
                # one with the deny bits, so this loop will loop 0, 1, or 2 times.
                while no_more_records = 0 do
                    select permitable_contains_permitable(permissions_permitable_id, _permitable_id)
                    into   permission_applies;
                    if permission_applies then
                        if _type = 1 then
                            set allow_permissions = allow_permissions | _permissions;
                        else                                                    # Not Coding Standard
                            set deny_permissions  = deny_permissions  | _permissions;
                        end if;
                    end if;
                    fetch permitable_id_type_and_permissions into
                                permissions_permitable_id, _type, _permissions;
                end while;
                close permitable_id_type_and_permissions;
            end$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `get_securableitem_module_and_model_permissions_for_permitable`(
                                in  _securableitem_id int(11),
                                in  _permitable_id    int(11),
                                in  class_name        varchar(255),
                                in  module_name       varchar(255),
                                out allow_permissions tinyint,
                                out deny_permissions  tinyint
                               )
begin
                declare permissions_permitable_id int(11);
                declare _type, _permissions, permission_applies tinyint;
                declare no_more_records                         tinyint default 0;
                declare permitable_id_type_and_permissions_for_namedsecurableitem cursor for
                    select permitable_id, type, bit_or(permissions)
                    from   permission, namedsecurableitem
                    where  permission.securableitem_id = namedsecurableitem.securableitem_id and
                           (name = class_name or name = module_name)
                           group by permitable_id, type;
                declare continue handler for not found
                    set no_more_records = 1;

                set allow_permissions = 0;
                set deny_permissions  = 0;
                open permitable_id_type_and_permissions_for_namedsecurableitem;
                fetch permitable_id_type_and_permissions_for_namedsecurableitem into
                            permissions_permitable_id, _type, _permissions;
                # The query will return at most one row with the allow bits and
                # one with the deny bits, so this loop will loop 0, 1, or 2 times.
                while no_more_records = 0 do
                    select permitable_contains_permitable(permissions_permitable_id, _permitable_id)
                    into   permission_applies;
                    if permission_applies then
                        if _type = 1 then
                            set allow_permissions = allow_permissions | _permissions;
                        else                                                    # Not Coding Standard
                            set deny_permissions  = deny_permissions  | _permissions;
                        end if;
                    end if;
                    fetch permitable_id_type_and_permissions_for_namedsecurableitem into
                                permissions_permitable_id, _type, _permissions;
                end while;
                close permitable_id_type_and_permissions_for_namedsecurableitem;
            end$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `get_securableitem_propagated_allow_permissions_for_permitable`(
                                in  _securableitem_id int(11),
                                in  _permitable_id    int(11),
                                in  class_name        varchar(255),
                                in  module_name       varchar(255),
                                out allow_permissions tinyint
                              )
begin
                declare user_id int(11);
                declare user_role_id int(11);
                declare parent_role_id int(11);

                select role_id into user_role_id from _user where permitable_id = _permitable_id;
                set allow_permissions = 0;
                select get_permitable_user_id(_permitable_id)
                into   user_id;
                if user_id is not null then
                    call recursive_get_all_descendent_roles(_permitable_id, user_role_id);
                    call recursive_get_securableitem_propagated_allow_permissions_permit(_securableitem_id, _permitable_id, class_name, module_name, allow_permissions);
                end if;
            end$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `increment_count`(
                                in munge_table_name varchar(255),
                                in securableitem_id int(11),
                                in item_id          int(11),
                                in _type            char
                              )
begin
                # TODO: insert only if the row doesn't exist
                # in a way that doesn't ignore all errors.

                set @sql = concat("insert into ", munge_table_name,
                                  "(securableitem_id, munge_id, count) ",
                                  "values (", securableitem_id, ", '", concat(_type, item_id), "', 1) ",
                                  "on duplicate key ",
                                  "update count = count + 1");
                prepare statement from @sql;
                execute statement;
                deallocate prepare statement;
            end$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `increment_parent_roles_counts`(
                                in munge_table_name varchar(255),
                                in securableitem_id int(11),
                                in _role_id         int(11)
                              )
begin
                declare parent_role_id int(11);

                select role_id
                into   parent_role_id
                from   role
                where  id = _role_id;
                if parent_role_id is not null then
                    call increment_count              (munge_table_name, securableitem_id, parent_role_id, "R");
                    call increment_parent_roles_counts(munge_table_name, securableitem_id, parent_role_id);
                end if;
            end$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `rebuild`(
                                in model_table_name varchar(255),
                                in munge_table_name varchar(255)
                              )
begin
                call recreate_tables(munge_table_name);
                call rebuild_users  (model_table_name, munge_table_name);
                call rebuild_groups (model_table_name, munge_table_name);
                call rebuild_roles  (model_table_name, munge_table_name);
            end$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `rebuild_a_permitable`(
                                in munge_table_name varchar(255),
                                in securableitem_id int(11),
                                in actual_id        int(11),
                                in _permitable_id   int(11),
                                in _type            char
                              )
begin
                declare allow_permissions, deny_permissions, effective_explicit_permissions smallint default 0;

                call get_securableitem_explicit_actual_permissions_for_permitable(securableitem_id, _permitable_id, allow_permissions, deny_permissions);
                set effective_explicit_permissions = allow_permissions & ~deny_permissions;
                if (effective_explicit_permissions & 1) = 1 then # Permission::READ
                    call increment_count(munge_table_name, securableitem_id, actual_id, _type);
                    if _type = "G" then
                        call rebuild_roles_for_users_in_group(munge_table_name, securableitem_id, actual_id);
                        call rebuild_sub_groups              (munge_table_name, securableitem_id, actual_id);
                    end if;
                end if;
            end$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `rebuild_groups`(
                                in model_table_name varchar(255),
                                in munge_table_name varchar(255)
                              )
begin
                set @select_statement  = concat("select permission.securableitem_id, _group.id, permission.permitable_id
                                         from ", model_table_name , ", ownedsecurableitem, permission, _group
                                         where
                                         ", model_table_name, ".ownedsecurableitem_id = ownedsecurableitem.id AND
                                         ownedsecurableitem.securableitem_id = permission.securableitem_id AND
                                         permission.permitable_id = _group.permitable_id");
                set @rebuild_groups_temp_table = CONCAT("create temporary table rebuild_temp_table as ", @select_statement);
                prepare statement FROM @rebuild_groups_temp_table;
                execute statement;
                deallocate prepare statement;
                begin
                    declare _securableitem_id, __group_id, _permitable_id int(11);
                    declare no_more_records tinyint default 0;
                    declare securableitem_group_and_permitable_ids cursor for
                        select * from rebuild_temp_table;
                    declare continue handler for not found
                        set no_more_records = 1;
                    open securableitem_group_and_permitable_ids;
                    fetch securableitem_group_and_permitable_ids into _securableitem_id, __group_id, _permitable_id;
                    while no_more_records = 0 do
                        call rebuild_a_permitable(munge_table_name, _securableitem_id, __group_id, _permitable_id, "G");
                        fetch securableitem_group_and_permitable_ids into _securableitem_id, __group_id, _permitable_id;
                    end while;
                    close securableitem_group_and_permitable_ids;
                    drop temporary table if exists rebuild_temp_table;
                end;
            end$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `rebuild_roles`(
                                in model_table_name varchar(255),
                                in munge_table_name varchar(255)
                              )
begin
                call rebuild_roles_owned_securableitems                         (model_table_name, munge_table_name);
                call rebuild_roles_securableitem_with_explicit_user_permissions (model_table_name, munge_table_name);
                call rebuild_roles_securableitem_with_explicit_group_permissions(model_table_name, munge_table_name);
            end$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `rebuild_roles_for_users_in_group`(
                                in munge_table_name  varchar(255),
                                in _securableitem_id int(11),
                                in __group_id        int(11)
                              )
begin
                declare _role_id int(11);
                declare no_more_records tinyint default 0;
                declare role_ids cursor for
                    select role_id
                    from   _group__user, _user
                    where  _group__user._group_id = __group_id and
                           _user.id = _group__user._user_id;
                declare continue handler for not found
                    set no_more_records = 1;

                open role_ids;
                fetch role_ids into _role_id;
                while no_more_records = 0 do
                    call increment_parent_roles_counts(munge_table_name, _securableitem_id, _role_id);
                    fetch role_ids into _role_id;
                end while;
                close role_ids;
            end$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `rebuild_roles_owned_securableitems`(
                                in model_table_name varchar(255),
                                in munge_table_name varchar(255)
                              )
begin
                set @select_statement  = concat("select role_id, ownedsecurableitem.securableitem_id
                                         from ", model_table_name, ", _user, ownedsecurableitem
                                         where ", model_table_name, ".ownedsecurableitem_id = ownedsecurableitem.id AND
                                         _user.id = ownedsecurableitem.owner__user_id and _user.role_id is not null");
                set @rebuild_roles_temp_table = CONCAT("create temporary table rebuild_temp_table as ", @select_statement);
                prepare statement FROM @rebuild_roles_temp_table;
                execute statement;
                deallocate prepare statement;
                   begin
                declare _role_id, _securableitem_id int(11);
                declare no_more_records tinyint default 0;
                declare role_and_securableitem_ids cursor for
                    select * from rebuild_temp_table;
                declare continue handler for not found
                    set no_more_records = 1;
                open role_and_securableitem_ids;
                fetch role_and_securableitem_ids into _role_id, _securableitem_id;
                while no_more_records = 0 do
                    call increment_parent_roles_counts(munge_table_name, _securableitem_id, _role_id);
                    fetch role_and_securableitem_ids into _role_id, _securableitem_id;
                end while;
                close role_and_securableitem_ids;
                drop temporary table if exists rebuild_temp_table;
                end;
            end$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `rebuild_roles_securableitem_with_explicit_group_permissions`(
                                in model_table_name varchar(255),
                                in munge_table_name varchar(255)
                              )
begin
                set @select_statement  =  concat("select role.role_id, permission.securableitem_id
                                           from ", model_table_name, ", ownedsecurableitem, _user, _group, _group__user, permission, role
                                           where ", model_table_name, ".ownedsecurableitem_id = ownedsecurableitem.id and
                                           ownedsecurableitem.securableitem_id = permission.securableitem_id and
                                           _user.id = _group__user._user_id                and
                                           permission.permitable_id = _group.permitable_id and
                                           _group__user._group_id = _group.id              and
                                           _user.role_id = role.role_id                    and
                                           ((permission.permissions & 1) = 1)              and
                                           permission.type = 1");
                set @rebuild_roles_temp_table = CONCAT("create temporary table rebuild_temp_table as ", @select_statement);
                prepare statement FROM @rebuild_roles_temp_table;
                execute statement;
                deallocate prepare statement;
                begin
                    declare _role_id, _securableitem_id int(11);
                    declare no_more_records tinyint default 0;
                    declare role_and_securableitem_ids cursor for
                        select * from rebuild_temp_table;
                    declare continue handler for not found
                        set no_more_records = 1;
                    open role_and_securableitem_ids;
                    fetch role_and_securableitem_ids into _role_id, _securableitem_id;
                    while no_more_records = 0 do
                        call increment_count              (munge_table_name, _securableitem_id, _role_id, "R");
                        call increment_parent_roles_counts(munge_table_name, _securableitem_id, _role_id);
                        fetch role_and_securableitem_ids into _role_id, _securableitem_id;
                    end while;
                    close role_and_securableitem_ids;
                    drop temporary table if exists rebuild_temp_table;
                end;
            end$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `rebuild_roles_securableitem_with_explicit_user_permissions`(
                                in model_table_name varchar(255),
                                in munge_table_name varchar(255)
                              )
begin
                set @select_statement  = concat("select role_id, permission.securableitem_id
                                         from ", model_table_name, ", ownedsecurableitem, permission, _user
                                         where ", model_table_name, ".ownedsecurableitem_id = ownedsecurableitem.id AND
                                         ownedsecurableitem.securableitem_id = permission.securableitem_id AND
                                         permission.permitable_id = _user.permitable_id and
                                         ((permission.permissions & 1) = 1) and permission.type = 1");
                set @rebuild_roles_temp_table = CONCAT("create temporary table rebuild_temp_table as ", @select_statement);
                prepare statement FROM @rebuild_roles_temp_table;
                execute statement;
                deallocate prepare statement;
                begin
                    declare _role_id, _securableitem_id int(11);
                    declare no_more_records tinyint default 0;
                    declare role_and_securableitem_ids cursor for
                        select * from rebuild_temp_table;
                    declare continue handler for not found
                        set no_more_records = 1;
                    open role_and_securableitem_ids;
                    fetch role_and_securableitem_ids into _role_id, _securableitem_id;
                    while no_more_records = 0 do
                        call increment_parent_roles_counts(munge_table_name, _securableitem_id, _role_id);
                        fetch role_and_securableitem_ids into _role_id, _securableitem_id;
                    end while;
                    close role_and_securableitem_ids;
                    drop temporary table if exists rebuild_temp_table;
                end;
            end$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `rebuild_sub_groups`(
                                in munge_table_name  varchar(255),
                                in _securableitem_id int(11),
                                in __group_id        int(11)
                              )
begin
                declare sub_group_id int(11);
                declare no_more_records tinyint default 0;
                declare sub_group_ids cursor for
                    select id
                    from   _group
                    where  _group_id = __group_id;
                declare continue handler for not found
                    set no_more_records = 1;

                open sub_group_ids;
                fetch sub_group_ids into sub_group_id;
                while no_more_records = 0 do
                    call increment_count                 (munge_table_name, _securableitem_id, sub_group_id, "G");
                    call rebuild_roles_for_users_in_group(munge_table_name, _securableitem_id, sub_group_id);
                    call rebuild_sub_groups              (munge_table_name, _securableitem_id, sub_group_id);
                    fetch sub_group_ids into sub_group_id;
                end while;
                close sub_group_ids;
            end$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `rebuild_users`(
                                in model_table_name varchar(255),
                                in munge_table_name varchar(255)
                              )
begin
                set @select_statement  = concat("select permission.securableitem_id, _user.id, permission.permitable_id
                                         from ", model_table_name, ", ownedsecurableitem, permission, _user
                                         where ", model_table_name , ".ownedsecurableitem_id = ownedsecurableitem.id and
                                         ownedsecurableitem.securableitem_id = permission.securableitem_id and
                                         permission.permitable_id = _user.permitable_id");
                set @rebuild_users_temp_table = CONCAT("create temporary table rebuild_temp_table as ", @select_statement);
                prepare statement FROM @rebuild_users_temp_table;
                execute statement;
                deallocate prepare statement;
                begin
                    declare _securableitem_id, __user_id, _permitable_id int(11);
                    declare no_more_records tinyint default 0;
                    declare securableitem_user_and_permitable_ids cursor for
                        select * from rebuild_temp_table;
                    declare continue handler for not found
                        set no_more_records = 1;
                    open securableitem_user_and_permitable_ids;
                    fetch securableitem_user_and_permitable_ids into _securableitem_id, __user_id, _permitable_id;
                    while no_more_records = 0 do
                        call rebuild_a_permitable(munge_table_name, _securableitem_id, __user_id, _permitable_id, "U");
                        fetch securableitem_user_and_permitable_ids into _securableitem_id, __user_id, _permitable_id;
                    end while;
                    close securableitem_user_and_permitable_ids;
                    drop temporary table if exists rebuild_temp_table;
                end;
            end$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `recreate_tables`(
                                in munge_table_name varchar(255)
                              )
begin
                set @sql = concat("drop table if exists ", munge_table_name);
                prepare statement from @sql;
                execute statement;
                deallocate prepare statement;

                set @sql = concat("create table ", munge_table_name, " (",
                                        "securableitem_id      int(11)     unsigned not null, ",
                                        "munge_id              varchar(12)              null, ",
                                        "count                 int(8)      unsigned not null, ",
                                        "primary key (securableitem_id, munge_id))");
                prepare statement from @sql;
                execute statement;
                deallocate prepare statement;

                set @sql = concat("create index index_", munge_table_name, "_securableitem_id", " ",
                                        "on ", munge_table_name, " (securableitem_id)");
                prepare statement from @sql;
                execute statement;
                deallocate prepare statement;
            end$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `recursive_get_all_descendent_roles`(in _permitable_id int(11), in parent_role_id int(11))
begin
                declare child_role_id int(11);
                declare no_more_records tinyint default 0;
                declare child_role_ids cursor for
                    select id
                    from   role
                    where  role_id = parent_role_id;
                declare continue handler for not found
                    set no_more_records = 1;

                open child_role_ids;
                fetch child_role_ids into child_role_id;
                while no_more_records = 0 do
                    INSERT IGNORE INTO __role_children_cache VALUES (_permitable_id, child_role_id);
                    call recursive_get_all_descendent_roles(_permitable_id, child_role_id);
                    fetch child_role_ids into child_role_id;
                end while;
                close child_role_ids;
            end$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `recursive_get_securableitem_actual_permissions_for_permitable`(
                                in  _securableitem_id int(11),
                                in  _permitable_id    int(11),
                                in  class_name        varchar(255),
                                in  module_name       varchar(255),
                                out allow_permissions tinyint,
                                out deny_permissions  tinyint
                              )
begin
                declare propagated_allow_permissions                            tinyint default 0;
                declare nameditem_allow_permissions, nameditem_deny_permissions tinyint default 0;
                declare is_owner tinyint;
                begin
                    select _securableitem_id in
                        (select securableitem_id
                         from   _user, ownedsecurableitem
                         where  _user.id = ownedsecurableitem.owner__user_id and
                                permitable_id = _permitable_id)
                    into is_owner;
                end;
                if is_owner then
                    set allow_permissions = 31;
                    set deny_permissions  = 0;
                else                                                            # Not Coding Standard
                    set allow_permissions = 0;
                    set deny_permissions  = 0;
                    call get_securableitem_explicit_inherited_permissions_for_permitable(_securableitem_id, _permitable_id, allow_permissions, deny_permissions);
                    call get_securableitem_propagated_allow_permissions_for_permitable  (_securableitem_id, _permitable_id, class_name, module_name, propagated_allow_permissions);
                    call get_securableitem_module_and_model_permissions_for_permitable  (_securableitem_id, _permitable_id, class_name, module_name, nameditem_allow_permissions, nameditem_deny_permissions);
                    set allow_permissions = allow_permissions | propagated_allow_permissions | nameditem_allow_permissions;
                    set deny_permissions  = deny_permissions                                 | nameditem_deny_permissions;
                end if;
            end$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `recursive_get_securableitem_propagated_allow_permissions_permit`(
                                in  _securableitem_id int(11),
                                in  _permitable_id    int(11),
                                in  class_name        varchar(255),
                                in  module_name       varchar(255),
                                out allow_permissions tinyint
                              )
begin
                declare user_allow_permissions, user_deny_permissions, user_propagated_allow_permissions tinyint;

                set allow_permissions = 0;

                begin
                    declare sub_role_id int(11);
                    declare no_more_records tinyint default 0;
                    declare sub_role_ids cursor for
                        select role_id
                        from   __role_children_cache
                        where  permitable_id = _permitable_id;
                    declare continue handler for not found
                        begin
                            set no_more_records = 1;
                        end;

                    open sub_role_ids;
                    fetch sub_role_ids into sub_role_id;
                    while no_more_records = 0 do
                        begin
                            declare propagated_allow_permissions tinyint;
                            declare user_in_role_id, permitable_in_role_id int(11);
                            declare permitable_in_role_ids cursor for
                                select permitable_id
                                from   _user
                                where  role_id = sub_role_id;

                            open permitable_in_role_ids;
                            fetch permitable_in_role_ids into permitable_in_role_id;
                            while no_more_records = 0 do
                                call recursive_get_securableitem_actual_permissions_for_permitable  (_securableitem_id, permitable_in_role_id, class_name, module_name, user_allow_permissions, user_deny_permissions);
                                call recursive_get_securableitem_propagated_allow_permissions_permit(_securableitem_id, permitable_in_role_id, class_name, module_name, propagated_allow_permissions);
                                set allow_permissions =
                                        allow_permissions                                 |
                                        (user_allow_permissions & ~user_deny_permissions) |
                                        propagated_allow_permissions;
                                fetch permitable_in_role_ids into permitable_in_role_id;
                            end while;
                        end;
                        set no_more_records = 0;
                        fetch sub_role_ids into sub_role_id;
                    end while;
                    close sub_role_ids;
                end;
            end$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `recursive_get_user_actual_right`(
                                in  _user_id    int(11),
                                in  module_name varchar(255),
                                in  right_name  varchar(255),
                                out result      tinyint
                              )
begin
                declare _role_id int;

                set result = 0;
                begin

                    select role_id
                    into   _role_id
                    from   _user
                    where  _user.id = _user_id;
                    if _role_id is not null then
                        call recursive_get_user_role_propagated_actual_allow_right(_role_id, module_name, right_name, result);
                        set result = result & 1;
                    end if;
                end;
                select get_user_explicit_actual_right (_user_id, module_name, right_name) |
                       get_user_inherited_actual_right(_user_id, module_name, right_name) |
                       result
                into result;

                if (result & 2) = 2 then
                    set result = 2;
                end if;
            end$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `recursive_get_user_role_propagated_actual_allow_right`(
                                in  _role_id    int(11),
                                in  module_name varchar(255),
                                in  right_name  varchar(255),
                                out result      tinyint
                              )
begin
                declare sub_role_id int(11);
                declare no_more_records tinyint default 0;
                declare sub_role_ids cursor for
                    select id
                    from   role
                    where  role.role_id = _role_id;
                declare continue handler for not found
                    set no_more_records = 1;

                set result = 0;
                open sub_role_ids;
                fetch sub_role_ids into sub_role_id;
                while result = 0 and no_more_records = 0 do
                  begin
                      declare _user_id int(11);
                      declare _user_ids cursor for
                          select id
                          from   _user
                          where  _user.role_id = sub_role_id;

                      open _user_ids;
                      fetch _user_ids into _user_id;
                      while result = 0 and no_more_records = 0 do
                          call recursive_get_user_actual_right(_user_id, module_name, right_name, result);
                          fetch _user_ids into _user_id;
                      end while;
                      close _user_ids;
                      if result = 0 then
                          call recursive_get_user_role_propagated_actual_allow_right(sub_role_id, module_name, right_name, result);
                      end if;
                      set no_more_records = 0;
                      fetch sub_role_ids into sub_role_id;
                  end;
                end while;
                close sub_role_ids;
            end$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `recursive_group_contains_group`(
                                in  group_id_1 int(11),
                                in  group_id_2 int(11),
                                out result     tinyint
                              )
begin
                declare group_2_parent_group_id, child_group_id int(11);
                declare no_more_records tinyint default 0;
                declare child_group_ids cursor for
                    select id
                    from   _group
                    where  _group._group_id = group_id_1;
                declare continue handler for not found
                    set no_more_records = 1;

                set result = 0;
                if group_id_1 = group_id_2 then
                    set result = 1;
                else                                                            # Not Coding Standard
                    select _group_id
                    into   group_2_parent_group_id
                    from   _group
                    where  id = group_id_2;
                    if group_id_1 = group_2_parent_group_id then
                        set result = 1;
                    else                                                        # Not Coding Standard
                        open child_group_ids;
                        fetch child_group_ids into child_group_id;
                        while result = 0 and no_more_records = 0 do
                            call recursive_group_contains_user(child_group_id, group_id_2, result);
                            fetch child_group_ids into child_group_id;
                        end while;
                        close child_group_ids;
                    end if;
                end if;
            end$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `recursive_group_contains_user`(
                                in  _group_id int(11),
                                in  _user_id  int(11),
                                out result    tinyint
                              )
begin
                declare child_group_id, count tinyint;
                declare no_more_records tinyint default 0;
                declare child_group_ids cursor for
                    select id
                    from   _group
                    where  _group._group_id = _group_id;
                declare continue handler for not found
                    set no_more_records = 1;

                set result = 0;
                select count(*)
                into count
                from _group__user
                where _group__user._group_id = _group_id and
                      _group__user._user_id  = _user_id;

                if count > 0 then
                    set result = 1;
                else                                                            # Not Coding Standard
                    open child_group_ids;
                    fetch child_group_ids into child_group_id;
                    while result = 0 and no_more_records = 0 do
                        call recursive_group_contains_user(child_group_id, _user_id, result);
                        fetch child_group_ids into child_group_id;
                    end while;
                    close child_group_ids;
                end if;
            end$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `update_email_message_for_sending`(message_id int, send_attempts int, sent_datetime datetime,
                                                                folder_id int, error_serialized_data text, now_timestamp datetime)
begin
                set @emailMessageSendErrorId    = null;
                delete from `emailmessagesenderror`
                        where id = (select error_emailmessagesenderror_id
                                    from `emailmessage`
                                    where id = message_id);
                if (error_serialized_data is not null) then
                    insert into `emailmessagesenderror` ( id, `createddatetime`,`serializeddata` ) values
                            (null,  now_timestamp , error_serialized_data);
                    set @emailMessageSendErrorId = last_insert_id();
                end if;

                update `emailmessage` set
                        `sendattempts` = send_attempts,
                        `sentdatetime` = sent_datetime,
                        `folder_emailfolder_id` = folder_id,
                        `error_emailmessagesenderror_id` = @emailMessageSendErrorId
                        where id = message_id;
            end$$

--
-- Functions
--
CREATE DEFINER=`root`@`localhost` FUNCTION `any_user_in_a_sub_role_has_read_permission`(
                                securableitem_id int(11),
                                role_id          int(11),
                                class_name       varchar(255),
                                module_name      varchar(255)
                             ) RETURNS tinyint(4)
    READS SQL DATA
    DETERMINISTIC
begin
                declare has_read tinyint default 0;

                call any_user_in_a_sub_role_has_read_permission(securableitem_id, role_id, class_name, module_name, has_read);
                return has_read;
            end$$

CREATE DEFINER=`root`@`localhost` FUNCTION `create_email_message`(text_content text, html_content text, from_name varchar(128),
                                                    from_address varchar(255), user_id int, owner_id int,
                                                    subject varchar(255), headers text, folder_id int,
                                                    serialized_data text, to_address varchar(255), to_name varchar(128),
                                                    recipient_type int, contact_item_id int,
                                                    related_model_type varchar(255), related_model_id int,
                                                     now_timestamp datetime) RETURNS int(11)
    MODIFIES SQL DATA
begin
                insert into `emailmessagecontent` ( `textcontent`, `htmlcontent` )
                            values ( text_content, html_content );
                set @contentId = last_insert_id();
                insert into `emailmessagesender` ( `fromname`, `fromaddress` )
                            values ( from_name, from_address );
                set @senderId = last_insert_id();
                set @emailMessageItemId = create_item(1, now_timestamp);
                insert into `securableitem` ( `item_id` )
                            values ( @emailMessageItemId );
                insert into `ownedsecurableitem` ( `securableitem_id`, `owner__user_id` )
                            values ( last_insert_id(), owner_id );
                insert into `emailmessage` ( `subject`, `headers`, `ownedsecurableitem_id`,
                                                `content_emailmessagecontent_id`, `sender_emailmessagesender_id`,
                                                 `folder_emailfolder_id` )
                             values ( subject, headers, last_insert_id(), @contentId, @senderId, folder_id);
                set @emailMessageId = LAST_INSERT_ID();
                insert into `auditevent` ( `datetime`, `modulename`, `eventname`, `_user_id`,
                                            `modelclassname`, `modelid`, `serializeddata` )
                            values ( now_timestamp, "ZurmoModule", "Item Created", user_id,
                                    "EmailMessage", @emailMessageId, serialized_data );
                insert into `emailmessagerecipient` ( `toaddress`, `toname`, `type`, `emailmessage_id` )
                            values ( to_address, to_name, recipient_type, @emailMessageId );
                set @recipientId = last_insert_id();
                insert into `emailmessagerecipient_item` ( `emailmessagerecipient_id`, `item_id` )
                            values ( @recipientId, contact_item_id );
                call duplicate_filemodels(related_model_type, related_model_id, "emailmessage", @emailMessageId, user_id, now_timestamp);
                return @emailMessageId;
            end$$

CREATE DEFINER=`root`@`localhost` FUNCTION `create_item`(user_id int, now_timestamp datetime) RETURNS int(11)
begin
              insert into `item` ( `id`, `createddatetime`, `modifieddatetime`,
                    `createdbyuser__user_id`, `modifiedbyuser__user_id` )
                    VALUES ( NULL,  now_timestamp , now_timestamp, user_id, user_id  );
               return last_insert_id();
            end$$

CREATE DEFINER=`root`@`localhost` FUNCTION `get_group_actual_right`(
                                _group_id   int(11),
                                module_name varchar(255),
                                right_name  varchar(255)
                             ) RETURNS tinyint(4)
    READS SQL DATA
    DETERMINISTIC
begin
                declare result tinyint;

                select get_group_explicit_actual_right (_group_id, module_name, right_name) |
                       get_group_inherited_actual_right(_group_id, module_name, right_name)
                into result;
                if (result & 2) = 2 then
                    return 2;
                end if;
                return result;
            end$$

CREATE DEFINER=`root`@`localhost` FUNCTION `get_group_explicit_actual_policy`(
                                _group_id   int(11),
                                module_name varchar(255),
                                policy_name varchar(255)
                             ) RETURNS tinyint(4)
    READS SQL DATA
    DETERMINISTIC
begin
                declare result tinyint;
                declare _permitable_id int;

                select permitable_id
                into   _permitable_id
                from   _group
                where  id = _group_id;
                select get_permitable_explicit_actual_policy(_permitable_id, module_name, policy_name)
                into result;
                return result;
            end$$

CREATE DEFINER=`root`@`localhost` FUNCTION `get_group_explicit_actual_right`(
                                _group_id   int(11),
                                module_name varchar(255),
                                right_name  varchar(255)
                             ) RETURNS tinyint(4)
    READS SQL DATA
    DETERMINISTIC
begin
                declare result tinyint;
                declare _permitable_id int;

                select permitable_id
                into   _permitable_id
                from   _group
                where  id = _group_id;
                select get_permitable_explicit_actual_right(_permitable_id, module_name, right_name)
                into result;
                return result;
            end$$

CREATE DEFINER=`root`@`localhost` FUNCTION `get_group_inherited_actual_right`(
                                _group_id   int(11),
                                module_name varchar(255),
                                right_name  varchar(255)
                             ) RETURNS tinyint(4)
    READS SQL DATA
    DETERMINISTIC
begin
                declare combined_right tinyint;

                call get_group_inherited_actual_right_ignoring_everyone(_group_id, module_name, right_name, combined_right);
                select combined_right |
                       get_named_group_explicit_actual_right('Everyone', module_name, right_name)
                into combined_right;
                if (combined_right & 2) = 2 then
                    return 2;
                end if;
                return combined_right;
            end$$

CREATE DEFINER=`root`@`localhost` FUNCTION `get_named_group_explicit_actual_policy`(
                                group_name  varchar(255),
                                module_name varchar(255),
                                policy_name varchar(255)
                             ) RETURNS varchar(255) CHARSET utf8 COLLATE utf8_unicode_ci
    READS SQL DATA
    DETERMINISTIC
begin                # but since PDO returns it as a string I am too, until I know if that is a bad thing.
                declare result tinyint;
                declare _permitable_id int;

                select permitable_id
                into   _permitable_id
                from   _group
                where  name = group_name;
                select get_permitable_explicit_actual_policy(_permitable_id, module_name, policy_name)
                into result;
                return result;
            end$$

CREATE DEFINER=`root`@`localhost` FUNCTION `get_named_group_explicit_actual_right`(
                                group_name  varchar(255),
                                module_name varchar(255),
                                right_name  varchar(255)
                             ) RETURNS tinyint(4)
    READS SQL DATA
    DETERMINISTIC
begin
                declare result tinyint;
                declare _permitable_id int;

                select permitable_id
                into   _permitable_id
                from   _group
                where  name = group_name;
                select get_permitable_explicit_actual_right(_permitable_id, module_name, right_name)
                into result;
                return result;
            end$$

CREATE DEFINER=`root`@`localhost` FUNCTION `get_permitable_explicit_actual_policy`(
                                permitable_id int(11),
                                module_name   varchar(255),
                                policy_name   varchar(255)
                             ) RETURNS varchar(255) CHARSET utf8 COLLATE utf8_unicode_ci
    READS SQL DATA
    DETERMINISTIC
begin                # but since PDO returns it as a string I am too, until I know if that is a bad thing.
                declare result tinyint;

                select value
                into   result
                from   policy
                where  policy.modulename    = module_name and
                       name                 = policy_name and
                       policy.permitable_id = permitable_id
                limit  1;
                return result;
            end$$

CREATE DEFINER=`root`@`localhost` FUNCTION `get_permitable_explicit_actual_right`(
                                permitable_id int(11),
                                module_name   varchar(255),
                                right_name    varchar(255)
                             ) RETURNS tinyint(4)
    READS SQL DATA
    DETERMINISTIC
begin
                declare result tinyint;

                select max(type)
                into   result
                from   _right
                where  _right.modulename    = module_name and
                       name                 = right_name and
                       _right.permitable_id = permitable_id;
                if result is null then
                    return 0;
                end if;
                return result;
            end$$

CREATE DEFINER=`root`@`localhost` FUNCTION `get_permitable_group_id`(
                                _permitable_id int(11)
                            ) RETURNS int(11)
begin
                declare result int(11);

                select id
                into   result
                from   _group
                where  _group.permitable_id = _permitable_id;
                return result;
            end$$

CREATE DEFINER=`root`@`localhost` FUNCTION `get_permitable_user_id`(
                                _permitable_id int(11)
                            ) RETURNS int(11)
    READS SQL DATA
    DETERMINISTIC
begin
                declare result int(11);

                select id
                into   result
                from   _user
                where  _user.permitable_id = _permitable_id;
                return result;
            end$$

CREATE DEFINER=`root`@`localhost` FUNCTION `get_securableitem_actual_permissions_for_permitable`(
                                _securableitem_id int(11),
                                _permitable_id    int(11),
                                class_name        varchar(255),
                                module_name       varchar(255),
                                caching_on        tinyint
                             ) RETURNS smallint(6)
    READS SQL DATA
    DETERMINISTIC
begin
                declare allow_permissions, deny_permissions smallint default 0;
                declare is_super_administrator, is_owner tinyint;

                delete from __role_children_cache;

                select named_group_contains_permitable('Super Administrators', _permitable_id)
                into is_super_administrator;
                if is_super_administrator then
                    set allow_permissions = 31;
                    set deny_permissions  = 0;
                else                                                            # Not Coding Standard
                    begin
                        select _securableitem_id in
                            (select securableitem_id
                             from   _user, ownedsecurableitem
                             where  _user.id = ownedsecurableitem.owner__user_id and
                                    permitable_id = _permitable_id)
                        into is_owner;
                    end;
                    if is_owner then
                        set allow_permissions = 31;
                        set deny_permissions  = 0;
                    else                                                        # Not Coding Standard
                        if caching_on then
                            call get_securableitem_cached_actual_permissions_for_permitable(_securableitem_id, _permitable_id, allow_permissions, deny_permissions);
                            if allow_permissions is null then
                                call recursive_get_securableitem_actual_permissions_for_permitable(_securableitem_id, _permitable_id, class_name, module_name, allow_permissions, deny_permissions);
                                call cache_securableitem_actual_permissions_for_permitable(_securableitem_id, _permitable_id, allow_permissions, deny_permissions);
                            end if;
                        else                                                    # Not Coding Standard
                            call recursive_get_securableitem_actual_permissions_for_permitable(_securableitem_id, _permitable_id, class_name, module_name, allow_permissions, deny_permissions);
                        end if;
                    end if;
                end if;
                return (allow_permissions << 8) | deny_permissions;
            end$$

CREATE DEFINER=`root`@`localhost` FUNCTION `get_user_actual_right`(
                                _user_id    int(11),
                                module_name varchar(255),
                                right_name  varchar(255)
                            ) RETURNS tinyint(4)
    READS SQL DATA
    DETERMINISTIC
begin
                declare result tinyint;
                declare is_super_administrator tinyint;

                select named_group_contains_user('Super Administrators', _user_id)
                into   is_super_administrator;
                if is_super_administrator then
                    set result = 1;
                else                                                            # Not Coding Standard
                    call recursive_get_user_actual_right(_user_id, module_name, right_name, result);
                end if;
                return result;
            end$$

CREATE DEFINER=`root`@`localhost` FUNCTION `get_user_explicit_actual_policy`(
                                _user_id    int(11),
                                module_name varchar(255),
                                policy_name varchar(255)
                             ) RETURNS varchar(255) CHARSET utf8 COLLATE utf8_unicode_ci
    READS SQL DATA
    DETERMINISTIC
begin                # but since PDO returns it as a string I am too, until I know if that is a bad thing.
                declare result tinyint;
                declare _permitable_id int;

                select permitable_id
                into   _permitable_id
                from   _user
                where  id = _user_id;
                select get_permitable_explicit_actual_policy(_permitable_id, module_name, policy_name)
                into result;
                return result;
            end$$

CREATE DEFINER=`root`@`localhost` FUNCTION `get_user_explicit_actual_right`(
                                _user_id    int(11),
                                module_name varchar(255),
                                right_name  varchar(255)
                             ) RETURNS tinyint(4)
    READS SQL DATA
    DETERMINISTIC
begin
                declare result tinyint;
                declare _permitable_id int;

                select permitable_id
                into   _permitable_id
                from   _user
                where  id = _user_id;
                select get_permitable_explicit_actual_right(_permitable_id, module_name, right_name)
                into result;
                return result;
            end$$

CREATE DEFINER=`root`@`localhost` FUNCTION `get_user_inherited_actual_right`(
                                _user_id    int(11),
                                module_name varchar(255),
                                right_name  varchar(255)
                             ) RETURNS tinyint(4)
    READS SQL DATA
    DETERMINISTIC
begin
                declare combined_right tinyint default 0;
                declare __group_id int(11);
                declare no_more_records tinyint default 0;
                declare _group_ids cursor for
                    select _group_id
                    from   _group__user
                    where  _group__user._user_id = _user_id;
                declare continue handler for not found
                    set no_more_records = 1;

                open _group_ids;
                fetch _group_ids into __group_id;
                while no_more_records = 0 do
                    select combined_right |
                           get_group_explicit_actual_right (__group_id, module_name, right_name) |
                           get_group_inherited_actual_right(__group_id, module_name, right_name)
                    into combined_right;
                    fetch _group_ids into __group_id;
                end while;
                close _group_ids;

                select combined_right |
                       get_named_group_explicit_actual_right('Everyone', module_name, right_name)
                into combined_right;

                if (combined_right & 2) = 2 then
                    return 2;
                end if;
                return combined_right;
            end$$

CREATE DEFINER=`root`@`localhost` FUNCTION `group_contains_permitable`(
                                _group_id      int(11),
                                _permitable_id int(11)
                             ) RETURNS tinyint(4)
    READS SQL DATA
    DETERMINISTIC
begin
                declare result tinyint default 0;
                declare _group_name varchar(255);
                declare is_everyone tinyint;
                declare _user_id int(11);
                declare group_id_2 int(11);

                select name
                into   _group_name
                from   _group
                where  _group.id = _group_id;
                if _group_name = 'Everyone' then
                    set result = 1;
                else                                                            # Not Coding Standard
                    set _user_id = get_permitable_user_id(_permitable_id);
                    if _user_id is not null then
                        call recursive_group_contains_user(_group_id, _user_id, result);
                    else                                                        # Not Coding Standard
                        set group_id_2 = get_permitable_group_id(_permitable_id);
                        if group_id_2 is not null then
                            call recursive_group_contains_group(_group_id, group_id_2, result);
                        end if;
                    end if;
                end if;
                return result;
            end$$

CREATE DEFINER=`root`@`localhost` FUNCTION `group_contains_user`(
                                _group_id int(11),
                                _user_id  int(11)
                             ) RETURNS tinyint(4)
    READS SQL DATA
    DETERMINISTIC
begin
                declare result tinyint default 0;

                call recursive_group_contains_user(_group_id, _user_id, result);
                return result;
            end$$

CREATE DEFINER=`root`@`localhost` FUNCTION `named_group_contains_permitable`(
                                group_name     varchar(255),
                                _permitable_id int(11)
                             ) RETURNS tinyint(4)
    READS SQL DATA
    DETERMINISTIC
begin
                declare result tinyint default 0;
                declare group_id_1 int(11);
                declare _user_id   int(11);
                declare group_id_2 int(11);

                if group_name = 'Everyone' then
                    set result = 1;
                else                                                            # Not Coding Standard
                    select id
                    into   group_id_1
                    from   _group
                    where  _group.name = group_name;
                    set _user_id = get_permitable_user_id(_permitable_id);
                    if _user_id is not null then
                        call recursive_group_contains_user(group_id_1, _user_id, result);
                    else                                                        # Not Coding Standard
                        set group_id_2 = get_permitable_group_id(_permitable_id);
                        if group_id_2 is not null then
                            call recursive_group_contains_group(group_id_1, group_id_2, result);
                        end if;
                    end if;
                end if;
                return result;
            end$$

CREATE DEFINER=`root`@`localhost` FUNCTION `named_group_contains_user`(
                                _group_name varchar(255),
                                _user_id    int(11)
                             ) RETURNS tinyint(4)
    READS SQL DATA
    DETERMINISTIC
begin
                declare result tinyint default 0;
                declare _group_id int(11);

                if _group_name = 'Everyone' then
                    set result = 1;
                else                                                            # Not Coding Standard
                    select id
                    into   _group_id
                    from   _group
                    where  _group.name = _group_name;
                    call recursive_group_contains_user(_group_id, _user_id, result);
                end if;
                return result;
            end$$

CREATE DEFINER=`root`@`localhost` FUNCTION `permitable_contains_permitable`(
                                permitable_id_1 int(11),
                                permitable_id_2 int(11)
                             ) RETURNS tinyint(4)
    READS SQL DATA
    DETERMINISTIC
begin
                declare result tinyint;
                declare user_id_1, user_id_2, group_id_1, group_id_2 int(11);

                # If they are both users just compare if they are the same user.
                select get_permitable_user_id(permitable_id_1)
                into   user_id_1;
                select get_permitable_user_id(permitable_id_2)
                into   user_id_2;
                if user_id_1 is not null and user_id_2 is not null then
                    set result = permitable_id_1 = permitable_id_2;
                else                                                            # Not Coding Standard
                    # If the first is a user and the second is a group return false.
                    select get_permitable_group_id(permitable_id_2)
                    into   group_id_2;
                    if user_id_1 is not null and group_id_2 is not null then
                        set result = 0;
                    else                                                        # Not Coding Standard
                        # Otherwise the first is a group, just return if it contains
                        # the second.
                        select get_permitable_group_id(permitable_id_1)
                        into   group_id_1;
                        if group_id_1 is not null then
                            select group_contains_permitable(group_id_1, permitable_id_2)
                            into result;
                        end if;
                    end if;
                end if;
                return result;
            end$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `account`
--

CREATE TABLE IF NOT EXISTS `account` (
`id` int(11) unsigned NOT NULL,
  `ownedsecurableitem_id` int(11) unsigned DEFAULT NULL,
  `industry_customfield_id` int(11) unsigned DEFAULT NULL,
  `type_customfield_id` int(11) unsigned DEFAULT NULL,
  `account_id` int(11) unsigned DEFAULT NULL,
  `description` text COLLATE utf8_unicode_ci,
  `name` varchar(64) COLLATE utf8_unicode_ci DEFAULT NULL,
  `officephone` varchar(24) COLLATE utf8_unicode_ci DEFAULT NULL,
  `officefax` varchar(24) COLLATE utf8_unicode_ci DEFAULT NULL,
  `annualrevenue` double DEFAULT NULL,
  `employees` int(11) DEFAULT NULL,
  `website` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `billingaddress_address_id` int(11) unsigned DEFAULT NULL,
  `primaryemail_email_id` int(11) unsigned DEFAULT NULL,
  `secondaryemail_email_id` int(11) unsigned DEFAULT NULL,
  `shippingaddress_address_id` int(11) unsigned DEFAULT NULL,
  `latestactivitydatetime` datetime DEFAULT NULL,
  `unitscstmcstm` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `comtypecstmcstm_customfield_id` int(11) unsigned DEFAULT NULL,
  `customertypecstm_customfield_id` int(11) unsigned DEFAULT NULL
) ENGINE=InnoDB AUTO_INCREMENT=72 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

--
-- Dumping data for table `account`
--

INSERT INTO `account` (`id`, `ownedsecurableitem_id`, `industry_customfield_id`, `type_customfield_id`, `account_id`, `description`, `name`, `officephone`, `officefax`, `annualrevenue`, `employees`, `website`, `billingaddress_address_id`, `primaryemail_email_id`, `secondaryemail_email_id`, `shippingaddress_address_id`, `latestactivitydatetime`, `unitscstmcstm`, `comtypecstmcstm_customfield_id`, `customertypecstm_customfield_id`) VALUES
(13, 334, NULL, NULL, NULL, NULL, 'Strada 315', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '117', 276, NULL),
(15, 336, NULL, NULL, NULL, NULL, 'Sunset Bay', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '308', 278, NULL),
(17, 338, NULL, NULL, NULL, NULL, 'Cypress Trails', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '364', 280, NULL),
(18, 339, NULL, NULL, NULL, NULL, 'Isles at Grand Bay', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '2000', 281, NULL),
(19, 340, NULL, NULL, NULL, NULL, 'The Summit', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '567', 282, NULL),
(20, 341, NULL, NULL, NULL, NULL, 'Key Largo', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '285', 283, NULL),
(21, 342, NULL, NULL, NULL, NULL, 'Garden Estates ', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '445', 284, NULL),
(22, 343, NULL, NULL, NULL, NULL, 'Aventi', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '180', 285, NULL),
(23, 344, NULL, NULL, NULL, NULL, 'Kenilworth', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '158', 286, NULL),
(24, 345, NULL, NULL, NULL, NULL, '400 Association', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '64', 287, NULL),
(25, 346, NULL, NULL, NULL, NULL, 'Marina Village', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '349', 288, NULL),
(26, 347, NULL, NULL, NULL, NULL, 'Tropic Harbor', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '225', 289, NULL),
(27, 348, NULL, NULL, NULL, NULL, 'Midtown Doral', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '1700', 290, NULL),
(28, 349, NULL, NULL, NULL, NULL, 'Midtown Retail', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '150', 291, NULL),
(29, 350, NULL, NULL, NULL, NULL, 'Meadowbrook # 4', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '244', 292, NULL),
(30, 351, NULL, NULL, NULL, NULL, 'Parker Plaza', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '520', 293, NULL),
(31, 352, NULL, NULL, NULL, NULL, 'Topaz North', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '84', 294, NULL),
(32, 353, NULL, NULL, NULL, NULL, 'Northern Star ', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '22', 295, NULL),
(33, 354, NULL, NULL, NULL, NULL, 'Emerald', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '108', 296, NULL),
(34, 355, NULL, NULL, NULL, NULL, 'Cloisters', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '140', 297, NULL),
(35, 356, NULL, NULL, NULL, '', '3360 Condo', NULL, NULL, NULL, NULL, NULL, 49, NULL, NULL, NULL, NULL, '90', 298, NULL),
(36, 357, NULL, NULL, NULL, NULL, 'Lake Worth Towers', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '199', 299, NULL),
(37, 358, NULL, NULL, NULL, NULL, 'Point East Condo', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '1270', 300, NULL),
(38, 359, NULL, NULL, NULL, NULL, 'Pine Ridge Condo', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '462', 301, NULL),
(39, 360, NULL, NULL, NULL, NULL, 'Christopher House', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '96', 302, NULL),
(40, 361, NULL, NULL, NULL, NULL, 'The Residences on Hollywood Beach Proposal ', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '534', 303, NULL),
(41, 362, NULL, NULL, NULL, NULL, 'Pinehurst Club ', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '197', 304, NULL),
(42, 363, NULL, NULL, NULL, NULL, 'Harbour House', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '192', 305, NULL),
(43, 364, NULL, NULL, NULL, NULL, 'Mystic Point', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '482', 306, NULL),
(44, 365, NULL, NULL, NULL, NULL, 'Glades Country Club', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '1255', 307, NULL),
(45, 366, NULL, NULL, NULL, NULL, '9 Island', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '271', 308, NULL),
(46, 367, NULL, NULL, NULL, NULL, 'Seamark', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '39', 309, NULL),
(47, 368, NULL, NULL, NULL, NULL, 'Balmoral Condo', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '423', 310, NULL),
(48, 369, NULL, NULL, NULL, NULL, 'Artesia', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '1000', 311, NULL),
(49, 370, NULL, NULL, NULL, NULL, 'Mayfair House Condo', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '223', 312, NULL),
(50, 371, NULL, NULL, NULL, NULL, 'OceanView Place', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '591', 313, NULL),
(51, 372, NULL, NULL, NULL, NULL, 'River Bridge', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '1100', 314, NULL),
(52, 373, NULL, NULL, NULL, NULL, 'Ocean Place', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '256', 315, NULL),
(53, 374, NULL, NULL, NULL, NULL, 'The Tides @ Bridgeside Square', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '246', 316, NULL),
(54, 375, NULL, NULL, NULL, NULL, 'OakBridge', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '279', 317, NULL),
(55, 376, NULL, NULL, NULL, NULL, 'Sand Pebble Beach Condominiums', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '242', 318, NULL),
(56, 377, NULL, NULL, NULL, NULL, 'The Atriums', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '106', 319, NULL),
(57, 378, NULL, NULL, NULL, NULL, 'Plaza of Bal Harbour', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '302', 320, NULL),
(58, 379, NULL, NULL, NULL, NULL, 'Nirvana Condos', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '385', 321, NULL),
(59, 380, NULL, NULL, NULL, NULL, 'Commodore Plaza', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '654', 322, NULL),
(60, 381, NULL, NULL, NULL, NULL, 'Fairways of Tamarac', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '174', 323, NULL),
(61, 382, NULL, NULL, NULL, NULL, 'Patrician of the Palm Beaches', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '224', 324, NULL),
(62, 383, NULL, NULL, NULL, NULL, 'Alexander Hotel/Condo', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '230', 325, NULL),
(63, 384, NULL, NULL, NULL, NULL, 'Las Verdes', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '1232', 326, NULL),
(64, 385, NULL, NULL, NULL, NULL, 'Lakes of Savannah', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '242', 327, NULL),
(65, 386, NULL, NULL, NULL, NULL, 'East Pointe Towers', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '274', 328, NULL),
(66, 387, NULL, NULL, NULL, NULL, 'Bravura 1 Condo', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '192', 329, NULL),
(67, 388, NULL, NULL, NULL, NULL, 'TOWERS OF KENDAL LAKES', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '180', 330, NULL),
(68, 389, NULL, NULL, NULL, NULL, 'Commodore Club South', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '186', 331, NULL),
(69, 390, NULL, NULL, NULL, NULL, 'Oceanfront Plaza', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '193', 332, NULL),
(70, 391, NULL, NULL, NULL, NULL, 'Hillsboro Cove', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '318', 333, NULL),
(71, 509, NULL, NULL, NULL, '', 'JEM', NULL, NULL, NULL, NULL, NULL, 50, NULL, NULL, NULL, NULL, '100', 523, 524);

-- --------------------------------------------------------

--
-- Table structure for table `accountaccountaffiliation`
--

CREATE TABLE IF NOT EXISTS `accountaccountaffiliation` (
`id` int(11) unsigned NOT NULL,
  `item_id` int(11) unsigned DEFAULT NULL,
  `primaryaccountaffiliation_account_id` int(11) unsigned DEFAULT NULL,
  `secondaryaccountaffiliation_account_id` int(11) unsigned DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `accountcontactaffiliation`
--

CREATE TABLE IF NOT EXISTS `accountcontactaffiliation` (
`id` int(11) unsigned NOT NULL,
  `primary` tinyint(1) unsigned DEFAULT NULL,
  `item_id` int(11) unsigned DEFAULT NULL,
  `role_customfield_id` int(11) unsigned DEFAULT NULL,
  `accountaffiliation_account_id` int(11) unsigned DEFAULT NULL,
  `contactaffiliation_contact_id` int(11) unsigned DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `accountstarred`
--

CREATE TABLE IF NOT EXISTS `accountstarred` (
`id` int(11) unsigned NOT NULL,
  `basestarredmodel_id` int(11) unsigned DEFAULT NULL,
  `account_id` int(11) unsigned DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `account_project`
--

CREATE TABLE IF NOT EXISTS `account_project` (
`id` int(11) unsigned NOT NULL,
  `account_id` int(11) unsigned DEFAULT NULL,
  `project_id` int(11) unsigned DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `account_read`
--

CREATE TABLE IF NOT EXISTS `account_read` (
  `securableitem_id` int(11) unsigned NOT NULL,
  `munge_id` varchar(12) COLLATE utf8_unicode_ci NOT NULL,
  `count` int(8) unsigned NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

--
-- Dumping data for table `account_read`
--

INSERT INTO `account_read` (`securableitem_id`, `munge_id`, `count`) VALUES
(510, 'G3', 1);

-- --------------------------------------------------------

--
-- Table structure for table `account_read_subscription`
--

CREATE TABLE IF NOT EXISTS `account_read_subscription` (
`id` int(11) unsigned NOT NULL,
  `userid` int(11) unsigned NOT NULL,
  `modelid` int(11) unsigned NOT NULL,
  `modifieddatetime` datetime DEFAULT NULL,
  `subscriptiontype` tinyint(4) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `account_read_subscription_temp_build`
--

CREATE TABLE IF NOT EXISTS `account_read_subscription_temp_build` (
`id` int(11) unsigned NOT NULL,
  `accountid` int(11) unsigned NOT NULL
) ENGINE=InnoDB AUTO_INCREMENT=71 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

--
-- Dumping data for table `account_read_subscription_temp_build`
--

INSERT INTO `account_read_subscription_temp_build` (`id`, `accountid`) VALUES
(1, 8),
(2, 9),
(3, 10),
(4, 11),
(5, 12),
(6, 5),
(7, 3),
(8, 6),
(9, 7),
(10, 2),
(11, 4),
(12, 13),
(13, 14),
(14, 15),
(15, 16),
(16, 17),
(17, 18),
(18, 19),
(19, 20),
(20, 21),
(21, 22),
(22, 23),
(23, 24),
(24, 25),
(25, 26),
(26, 27),
(27, 28),
(28, 29),
(29, 30),
(30, 31),
(31, 32),
(32, 33),
(33, 34),
(34, 35),
(35, 36),
(36, 37),
(37, 38),
(38, 39),
(39, 40),
(40, 41),
(41, 42),
(42, 43),
(43, 44),
(44, 45),
(45, 46),
(46, 47),
(47, 48),
(48, 49),
(49, 50),
(50, 51),
(51, 52),
(52, 53),
(53, 54),
(54, 55),
(55, 56),
(56, 57),
(57, 58),
(58, 59),
(59, 60),
(60, 61),
(61, 62),
(62, 63),
(63, 64),
(64, 65),
(65, 66),
(66, 67),
(67, 68),
(68, 69),
(69, 70),
(70, 71);

-- --------------------------------------------------------

--
-- Table structure for table `activelanguage`
--

CREATE TABLE IF NOT EXISTS `activelanguage` (
`id` int(11) unsigned NOT NULL,
  `code` varchar(16) COLLATE utf8_unicode_ci DEFAULT NULL,
  `name` varchar(64) COLLATE utf8_unicode_ci DEFAULT NULL,
  `nativename` varchar(64) COLLATE utf8_unicode_ci DEFAULT NULL,
  `activationdatetime` datetime DEFAULT NULL,
  `lastupdatedatetime` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `activity`
--

CREATE TABLE IF NOT EXISTS `activity` (
`id` int(11) unsigned NOT NULL,
  `ownedsecurableitem_id` int(11) unsigned DEFAULT NULL,
  `latestdatetime` datetime DEFAULT NULL
) ENGINE=InnoDB AUTO_INCREMENT=85 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

--
-- Dumping data for table `activity`
--

INSERT INTO `activity` (`id`, `ownedsecurableitem_id`, `latestdatetime`) VALUES
(4, 122, '2013-08-07 12:30:33'),
(5, 123, '2013-08-10 12:30:33'),
(6, 124, '2013-07-31 12:30:33'),
(7, 125, '2013-07-09 12:30:33'),
(8, 126, '2013-08-18 12:30:34'),
(9, 127, '2013-07-17 12:30:34'),
(10, 128, '2013-07-12 12:30:34'),
(11, 129, '2013-08-03 12:30:34'),
(12, 130, '2013-07-26 12:30:34'),
(13, 131, '2013-08-06 12:30:34'),
(14, 132, '2013-06-26 12:30:34'),
(15, 133, '2013-06-29 12:30:34'),
(16, 134, '2013-06-29 12:30:34'),
(17, 135, '2013-07-27 12:30:34'),
(18, 136, '2013-07-06 12:30:34'),
(19, 137, '2013-07-15 12:30:34'),
(20, 138, '2013-08-14 12:30:34'),
(21, 139, '2013-08-18 12:30:34'),
(22, 140, '2013-05-29 12:30:34'),
(23, 141, '2013-06-13 12:30:34'),
(24, 142, '2013-06-10 12:30:34'),
(25, 143, '2013-06-24 12:30:34'),
(26, 144, '2013-06-19 12:30:34'),
(27, 145, '2013-05-31 12:30:34'),
(28, 146, '2013-05-27 12:30:35'),
(29, 147, '2013-05-31 12:30:35'),
(30, 148, '2013-06-11 12:30:35'),
(31, 149, '2013-06-20 12:30:35'),
(32, 150, '2013-06-10 12:30:35'),
(33, 151, '2013-06-04 12:30:35'),
(34, 152, '2013-06-13 12:30:35'),
(35, 153, '2013-06-18 12:30:35'),
(36, 154, '2013-06-14 12:30:35'),
(37, 155, '2013-06-14 12:30:35'),
(38, 156, '2013-06-06 12:30:35'),
(39, 157, '2013-06-18 12:30:35'),
(40, 162, '2013-03-24 12:30:36'),
(41, 163, '2013-05-02 12:30:36'),
(42, 164, '2013-04-10 12:30:36'),
(43, 165, '2013-06-15 12:30:36'),
(44, 166, '2013-02-08 12:30:36'),
(45, 167, '2013-05-11 12:30:36'),
(46, 168, '2013-04-20 12:30:36'),
(47, 169, '2012-12-30 12:30:36'),
(48, 170, '2013-02-03 12:30:36'),
(49, 171, '2013-03-04 12:30:36'),
(50, 172, '2012-12-22 12:30:36'),
(51, 173, '2013-05-31 12:30:36'),
(52, 174, '2013-05-03 12:30:36'),
(53, 175, '2013-01-21 12:30:36'),
(54, 176, '2013-01-01 12:30:36'),
(55, 177, '2013-04-02 12:30:37'),
(56, 178, '2013-06-04 12:30:37'),
(57, 179, '2013-02-15 12:30:37'),
(58, 249, '2013-06-25 12:30:46'),
(59, 258, '2013-06-25 12:30:46'),
(60, 260, '2013-06-25 12:30:46'),
(61, 264, '2013-06-02 12:33:17'),
(62, 265, '2013-05-24 12:32:47'),
(63, 266, '2013-05-18 12:31:32'),
(64, 267, '2013-05-13 12:31:02'),
(65, 268, '2013-05-31 12:36:47'),
(66, 269, '2013-05-15 12:31:47'),
(67, 270, '2013-06-25 12:30:47'),
(68, 271, '2013-05-23 12:33:02'),
(69, 272, '2013-06-15 12:35:17'),
(70, 273, '2013-05-13 12:33:02'),
(71, 274, '2013-05-30 12:34:02'),
(72, 275, '2013-06-25 12:30:47'),
(73, 276, '2013-06-25 12:30:47'),
(74, 277, '2013-06-25 12:30:47'),
(75, 278, '2013-06-25 12:30:47'),
(76, 279, '2013-06-25 12:30:47'),
(77, 280, '2013-06-25 12:30:47'),
(78, 281, '2013-06-01 12:33:02'),
(79, 306, '2016-01-06 12:26:00'),
(80, 307, '2016-01-08 06:00:00'),
(81, 308, '2016-01-07 03:47:42'),
(82, 309, '2016-01-07 03:48:00'),
(83, 310, '2016-01-07 03:47:00'),
(84, 311, '2016-01-07 03:51:43');

-- --------------------------------------------------------

--
-- Table structure for table `activity_item`
--

CREATE TABLE IF NOT EXISTS `activity_item` (
`id` int(11) unsigned NOT NULL,
  `activity_id` int(11) unsigned DEFAULT NULL,
  `item_id` int(11) unsigned DEFAULT NULL
) ENGINE=InnoDB AUTO_INCREMENT=228 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

--
-- Dumping data for table `activity_item`
--

INSERT INTO `activity_item` (`id`, `activity_id`, `item_id`) VALUES
(5, 4, 91),
(8, 5, 91),
(11, 6, 94),
(14, 7, 90),
(17, 8, 90),
(20, 9, 91),
(23, 10, 90),
(26, 11, 90),
(29, 12, 90),
(32, 13, 89),
(35, 14, 87),
(38, 15, 87),
(41, 16, 90),
(44, 17, 89),
(47, 18, 94),
(50, 19, 85),
(53, 20, 91),
(56, 21, 87),
(59, 22, 89),
(62, 23, 87),
(65, 24, 94),
(68, 25, 93),
(71, 26, 93),
(74, 27, 90),
(77, 28, 90),
(80, 29, 87),
(83, 30, 91),
(86, 31, 89),
(89, 32, 94),
(92, 33, 90),
(95, 34, 90),
(98, 35, 88),
(101, 36, 88),
(104, 37, 89),
(107, 38, 94),
(110, 39, 90),
(113, 40, 90),
(116, 41, 89),
(119, 42, 91),
(122, 43, 94),
(125, 44, 90),
(128, 45, 93),
(131, 46, 88),
(134, 47, 87),
(137, 48, 85),
(140, 49, 85),
(143, 50, 90),
(146, 51, 89),
(149, 52, 87),
(152, 53, 93),
(155, 54, 90),
(158, 55, 87),
(161, 56, 89),
(164, 57, 89),
(170, 61, 85),
(173, 62, 87),
(176, 63, 87),
(179, 64, 89),
(182, 65, 90),
(185, 66, 85),
(188, 67, 94),
(191, 68, 93),
(194, 69, 93),
(197, 70, 91),
(200, 71, 91),
(203, 72, 90),
(206, 73, 90),
(209, 74, 87),
(212, 75, 87),
(215, 76, 85),
(218, 77, 85),
(221, 78, 85),
(223, 80, 574),
(224, 81, 574),
(226, 83, 574),
(227, 84, 574);

-- --------------------------------------------------------

--
-- Table structure for table `actual_permissions_cache`
--

CREATE TABLE IF NOT EXISTS `actual_permissions_cache` (
  `securableitem_id` int(11) unsigned NOT NULL,
  `permitable_id` int(11) unsigned NOT NULL,
  `allow_permissions` tinyint(3) unsigned NOT NULL,
  `deny_permissions` tinyint(3) unsigned NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `actual_rights_cache`
--

CREATE TABLE IF NOT EXISTS `actual_rights_cache` (
  `identifier` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
  `entry` int(11) unsigned NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

--
-- Dumping data for table `actual_rights_cache`
--

INSERT INTO `actual_rights_cache` (`identifier`, `entry`) VALUES
('1AccountAccountAffiliationsModuleAccess AccountAccountAffiliations TabActualRight', 1),
('1AccountContactAffiliationsModuleAccess AccountContactAffiliations TabActualRight', 1),
('1AccountsModuleAccess Accounts TabActualRight', 1),
('1AccountsModuleCreate AccountsActualRight', 1),
('1AccountsModuleDelete AccountsActualRight', 1),
('1CalendarsModuleAccess Calandar TabActualRight', 1),
('1CalendarsModuleCreate CalendarActualRight', 1),
('1CalendarsModuleDelete CalendarActualRight', 1),
('1CampaignsModuleAccess Campaigns TabActualRight', 1),
('1CampaignsModuleCreate CampaignsActualRight', 1),
('1CampaignsModuleDelete CampaignsActualRight', 1),
('1ConfigurationModuleAccess Administration TabActualRight', 1),
('1ContactsModuleAccess Contacts TabActualRight', 1),
('1ContactsModuleCreate ContactsActualRight', 1),
('1ContactsModuleDelete ContactsActualRight', 1),
('1ContactWebFormsModuleAccess Contact Web Forms TabActualRight', 1),
('1ContactWebFormsModuleCreate Contact Web FormsActualRight', 1),
('1ContactWebFormsModuleDelete Contact Web FormsActualRight', 1),
('1ContractsModuleAccess Contracts TabActualRight', 1),
('1ContractsModuleCreate ContractsActualRight', 1),
('1ContractsModuleDelete ContractsActualRight', 1),
('1ConversationsModuleAccess Conversations TabActualRight', 1),
('1ConversationsModuleCreate ConversationsActualRight', 1),
('1ConversationsModuleDelete ConversationsActualRight', 1),
('1DesignerModuleAccess Designer ToolActualRight', 1),
('1EmailMessagesModuleAccess Email ConfigurationActualRight', 1),
('1EmailMessagesModuleAccess Emails TabActualRight', 1),
('1EmailMessagesModuleCreate EmailsActualRight', 1),
('1EmailMessagesModuleDelete EmailsActualRight', 1),
('1EmailTemplatesModuleAccess Email TemplatesActualRight', 1),
('1EmailTemplatesModuleCreate Email TemplatesActualRight', 1),
('1EmailTemplatesModuleDelete Email TemplatesActualRight', 1),
('1ExportModuleAccess Export ToolActualRight', 1),
('1GameRewardsModuleAccess Game Rewards TabActualRight', 1),
('1GroupsModuleAccess Groups TabActualRight', 1),
('1GroupsModuleCreate GroupsActualRight', 1),
('1GroupsModuleDelete GroupsActualRight', 1),
('1HomeModuleAccess DashboardsActualRight', 1),
('1HomeModuleCreate DashboardsActualRight', 1),
('1HomeModuleDelete DashboardsActualRight', 1),
('1ImportModuleAccess Import ToolActualRight', 1),
('1JobsManagerModuleAccess Jobs Manager TabActualRight', 1),
('1LeadsModuleAccess Leads TabActualRight', 1),
('1LeadsModuleConvert LeadsActualRight', 1),
('1LeadsModuleCreate LeadsActualRight', 1),
('1LeadsModuleDelete LeadsActualRight', 1),
('1MapsModuleAccess Maps AdministrationActualRight', 1),
('1MarketingListsModuleAccess Marketing Lists TabActualRight', 1),
('1MarketingListsModuleCreate Marketing ListsActualRight', 1),
('1MarketingListsModuleDelete Marketing ListsActualRight', 1),
('1MarketingModuleAccess Marketing ConfigurationActualRight', 1),
('1MarketingModuleAccess Marketing TabActualRight', 1),
('1MeetingsModuleAccess MeetingsActualRight', 1),
('1MeetingsModuleCreate MeetingsActualRight', 1),
('1MeetingsModuleDelete MeetingsActualRight', 1),
('1MissionsModuleAccess Missions TabActualRight', 1),
('1MissionsModuleCreate MissionsActualRight', 1),
('1MissionsModuleDelete MissionsActualRight', 1),
('1NotesModuleAccess NotesActualRight', 1),
('1NotesModuleCreate NotesActualRight', 1),
('1NotesModuleDelete NotesActualRight', 1),
('1OpportunitiesModuleAccess Opportunities TabActualRight', 1),
('1OpportunitiesModuleCreate OpportunitiesActualRight', 1),
('1OpportunitiesModuleDelete OpportunitiesActualRight', 1),
('1ProductsModuleAccess Products TabActualRight', 1),
('1ProductsModuleCreate ProductsActualRight', 1),
('1ProductsModuleDelete ProductsActualRight', 1),
('1ProductTemplatesModuleAccess Catalog Items TabActualRight', 1),
('1ProductTemplatesModuleCreate Catalog ItemsActualRight', 1),
('1ProductTemplatesModuleDelete Catalog ItemsActualRight', 1),
('1ProjectsModuleAccess Projects TabActualRight', 1),
('1ProjectsModuleCreate ProjectsActualRight', 1),
('1ProjectsModuleDelete ProjectsActualRight', 1),
('1ReportsModuleAccess Reports TabActualRight', 1),
('1ReportsModuleCreate ReportsActualRight', 1),
('1ReportsModuleDelete ReportsActualRight', 1),
('1RolesModuleAccess Roles TabActualRight', 1),
('1RolesModuleCreate RolesActualRight', 1),
('1RolesModuleDelete RolesActualRight', 1),
('1RolesModuleDeleteActualRight', 1),
('1SocialItemsModuleAccess Social ItemsActualRight', 1),
('1TasksModuleAccess TasksActualRight', 1),
('1TasksModuleCreate TasksActualRight', 1),
('1TasksModuleDelete TasksActualRight', 1),
('1UsersModuleAccess Game Rewards TabActualRight', 1),
('1UsersModuleAccess Users TabActualRight', 1),
('1UsersModuleChange User PasswordsActualRight', 1),
('1UsersModuleCreate UsersActualRight', 1),
('1UsersModuleLogin Via MobileActualRight', 1),
('1UsersModuleLogin Via Web APIActualRight', 1),
('1UsersModuleLogin Via WebActualRight', 1),
('1WorkflowsModuleAccess Workflows TabActualRight', 1),
('1WorkflowsModuleCreate WorkflowsActualRight', 1),
('1WorkflowsModuleDelete WorkflowsActualRight', 1),
('1ZurmoModuleAccess Administration TabActualRight', 1),
('1ZurmoModuleAccess Currency ConfigurationActualRight', 1),
('1ZurmoModuleAccess Global ConfigurationActualRight', 1),
('1ZurmoModuleMass DeleteActualRight', 1),
('1ZurmoModuleMass MergeActualRight', 1),
('1ZurmoModuleMass UpdateActualRight', 1),
('1ZurmoModulePush Dashboard or LayoutActualRight', 1);

-- --------------------------------------------------------

--
-- Table structure for table `address`
--

CREATE TABLE IF NOT EXISTS `address` (
`id` int(11) unsigned NOT NULL,
  `city` varchar(32) COLLATE utf8_unicode_ci DEFAULT NULL,
  `country` varchar(32) COLLATE utf8_unicode_ci DEFAULT NULL,
  `invalid` tinyint(1) unsigned DEFAULT NULL,
  `postalcode` varchar(16) COLLATE utf8_unicode_ci DEFAULT NULL,
  `street1` varchar(128) COLLATE utf8_unicode_ci DEFAULT NULL,
  `street2` varchar(128) COLLATE utf8_unicode_ci DEFAULT NULL,
  `state` varchar(32) COLLATE utf8_unicode_ci DEFAULT NULL,
  `latitude` double DEFAULT NULL,
  `longitude` double DEFAULT NULL
) ENGINE=InnoDB AUTO_INCREMENT=51 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

--
-- Dumping data for table `address`
--

INSERT INTO `address` (`id`, `city`, `country`, `invalid`, `postalcode`, `street1`, `street2`, `state`, `latitude`, `longitude`) VALUES
(2, 'Milwaukee', NULL, 0, '53233', '5690 West Battery Center', NULL, 'WI', NULL, NULL),
(3, 'Washington', NULL, 0, '20375', '21696 South Elm Parkway', NULL, 'DC', NULL, NULL),
(4, 'Dallas', NULL, 0, '75201', '28075 South Washington Parkway', NULL, 'TX', NULL, NULL),
(5, 'Philadelphia', NULL, 0, '19152', '30348 East Corporate Creek', NULL, 'PA', NULL, NULL),
(6, 'Dallas', NULL, 0, '75233', '37647 South View Lane', NULL, 'TX', NULL, NULL),
(7, 'Los Angeles', NULL, 0, '90010', '17324 East Pine Creek', NULL, 'CA', NULL, NULL),
(8, 'Baltimore', NULL, 0, '21215', '23742 East Thompson Blvd', NULL, 'MD', NULL, NULL),
(9, 'San Francisco', NULL, 0, '94101', '37927 East Third Blvd', NULL, 'CA', NULL, NULL),
(16, 'Phoenix', NULL, 0, '85003', '38960 West Franklin Center', NULL, 'AZ', NULL, NULL),
(17, 'Philadelphia', NULL, 0, '19152', '2772 East Thompson Street', NULL, 'PA', NULL, NULL),
(18, 'Chicago', NULL, 0, '60601', '8622 North Madison Lane', NULL, 'IL', NULL, NULL),
(19, 'San Diego', NULL, 0, '92101', '26811 West Arlington Blvd', NULL, 'CA', NULL, NULL),
(20, 'Philadelphia', NULL, 0, '19102', '4279 South Third Ave', NULL, 'PA', NULL, NULL),
(21, 'Washington', NULL, 0, '20375', '7483 North Franklin Creek', NULL, 'DC', NULL, NULL),
(22, 'Phoenix', NULL, 0, '85003', '27993 East Third Court', NULL, 'AZ', NULL, NULL),
(23, 'Chicago', NULL, 0, '60652', '9805 West Hill Blvd', NULL, 'IL', NULL, NULL),
(24, 'San Francisco', NULL, 0, '94121', '25669 North View Ave', NULL, 'CA', NULL, NULL),
(25, 'San Jose', NULL, 0, '95131', '14730 East Arlington Parkway', NULL, 'CA', NULL, NULL),
(26, 'Dallas', NULL, 0, '75287', '17239 North Cedar Creek', NULL, 'TX', NULL, NULL),
(27, 'Chicago', NULL, 0, '60601', '25394 North Busse Trail', NULL, 'IL', NULL, NULL),
(28, 'Houston', NULL, 0, '77099', '22571 South Elm Road', NULL, 'TX', NULL, NULL),
(29, 'Detroit', NULL, 0, '48223', '26570 West Alameda Center', NULL, 'MI', NULL, NULL),
(30, 'Milwaukee', NULL, 0, '53233', '32563 South Thompson Lane', NULL, 'WI', NULL, NULL),
(31, 'Dallas', NULL, 0, '75201', '38638 East Ontario Creek', NULL, 'TX', NULL, NULL),
(32, 'Chicago', NULL, 0, '60601', '28162 South Hill Lane', NULL, 'IL', NULL, NULL),
(33, 'Milwaukee', NULL, 0, '53202', '23709 North Oak Parkway', NULL, 'WI', NULL, NULL),
(34, 'Baltimore', NULL, 0, '21239', '5420 North Spring Road', NULL, 'MD', NULL, NULL),
(35, 'New York', NULL, 0, '10169', '18337 North Thomas Road', NULL, 'NY', NULL, NULL),
(36, 'Baltimore', NULL, 0, '21201', '14758 South Park Circle', NULL, 'MD', NULL, NULL),
(37, 'Phoenix', NULL, 0, '85021', '13640 West Hill Court', NULL, 'AZ', NULL, NULL),
(38, 'San Jose', NULL, 0, '95148', '33535 South Battery Street', NULL, 'CA', NULL, NULL),
(39, 'San Diego', NULL, 0, '92129', '6885 South Second Trail', NULL, 'CA', NULL, NULL),
(40, '', '', NULL, '', '', '', '', NULL, NULL),
(41, '', '', NULL, '', '', '', '', NULL, NULL),
(42, '', '', NULL, '', '', '', '', NULL, NULL),
(47, 'Coral Gables', 'USA', 0, '33146', '1360 S Dixe Highway', 'Suite 200', 'FL', NULL, NULL),
(48, '', '', NULL, '', '', '', '', NULL, NULL),
(49, '', '', NULL, '', '', '', '', NULL, NULL),
(50, 'Miami', '', 0, '33130', '100 SW 10th Street', '', 'FL', NULL, NULL);

-- --------------------------------------------------------

--
-- Table structure for table `auditevent`
--

CREATE TABLE IF NOT EXISTS `auditevent` (
`id` int(11) unsigned NOT NULL,
  `modelid` int(11) DEFAULT NULL,
  `_user_id` int(11) unsigned DEFAULT NULL,
  `datetime` datetime DEFAULT NULL,
  `eventname` varchar(64) COLLATE utf8_unicode_ci DEFAULT NULL,
  `modulename` varchar(64) COLLATE utf8_unicode_ci DEFAULT NULL,
  `modelclassname` varchar(64) COLLATE utf8_unicode_ci DEFAULT NULL,
  `serializeddata` text COLLATE utf8_unicode_ci
) ENGINE=InnoDB AUTO_INCREMENT=1867 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

--
-- Dumping data for table `auditevent`
--

INSERT INTO `auditevent` (`id`, `modelid`, `_user_id`, `datetime`, `eventname`, `modulename`, `modelclassname`, `serializeddata`) VALUES
(1, 1, 1, '2013-06-25 12:27:49', 'Item Created', 'ZurmoModule', 'User', 's:10:"Super User";'),
(2, 1, 1, '2013-06-25 12:27:49', 'User Password Changed', 'UsersModule', 'User', 's:5:"super";'),
(3, 1, 1, '2013-06-25 12:27:49', 'Item Created', 'ZurmoModule', 'Group', 's:20:"Super Administrators";'),
(114, 3, 1, '2013-06-25 12:29:36', 'Item Created', 'ZurmoModule', 'Group', 's:8:"Everyone";'),
(115, 2, 1, '2013-06-25 12:29:36', 'Item Created', 'ZurmoModule', 'NotificationMessage', 's:6:"(None)";'),
(116, 2, 1, '2013-06-25 12:29:36', 'Item Created', 'ZurmoModule', 'Notification', 's:52:"Remove the api test entry script for production use.";'),
(117, 4, 1, '2013-06-25 12:29:36', 'Item Created', 'ZurmoModule', 'Group', 's:4:"East";'),
(118, 5, 1, '2013-06-25 12:29:36', 'Item Created', 'ZurmoModule', 'Group', 's:4:"West";'),
(119, 6, 1, '2013-06-25 12:29:36', 'Item Created', 'ZurmoModule', 'Group', 's:18:"East Channel Sales";'),
(120, 7, 1, '2013-06-25 12:29:36', 'Item Created', 'ZurmoModule', 'Group', 's:18:"West Channel Sales";'),
(121, 8, 1, '2013-06-25 12:29:36', 'Item Created', 'ZurmoModule', 'Group', 's:17:"East Direct Sales";'),
(122, 9, 1, '2013-06-25 12:29:36', 'Item Created', 'ZurmoModule', 'Group', 's:17:"West Direct Sales";'),
(123, 2, 1, '2013-06-25 12:29:36', 'Item Created', 'ZurmoModule', 'Role', 's:9:"Executive";'),
(124, 3, 1, '2013-06-25 12:29:36', 'Item Created', 'ZurmoModule', 'Role', 's:7:"Manager";'),
(125, 4, 1, '2013-06-25 12:29:36', 'Item Created', 'ZurmoModule', 'Role', 's:9:"Associate";'),
(126, 1, 1, '2013-06-25 12:29:36', 'Item Modified', 'ZurmoModule', 'User', 'a:4:{i:0;s:10:"Super User";i:1;a:2:{i:0;s:12:"primaryEmail";i:1;s:12:"emailAddress";}i:2;N;i:3;s:25:"Super.test@test.zurmo.com";}'),
(127, 3, 1, '2013-06-25 12:29:36', 'Item Created', 'ZurmoModule', 'User', 's:10:"Jason Blue";'),
(128, 3, 1, '2013-06-25 12:29:36', 'User Password Changed', 'UsersModule', 'User', 's:5:"admin";'),
(129, 4, 1, '2013-06-25 12:29:37', 'Item Created', 'ZurmoModule', 'User', 's:9:"Jim Smith";'),
(130, 4, 1, '2013-06-25 12:29:37', 'User Password Changed', 'UsersModule', 'User', 's:3:"jim";'),
(131, 5, 1, '2013-06-25 12:29:37', 'Item Created', 'ZurmoModule', 'User', 's:10:"John Smith";'),
(132, 5, 1, '2013-06-25 12:29:37', 'User Password Changed', 'UsersModule', 'User', 's:4:"john";'),
(133, 6, 1, '2013-06-25 12:29:37', 'Item Created', 'ZurmoModule', 'User', 's:11:"Sally Smith";'),
(134, 6, 1, '2013-06-25 12:29:37', 'User Password Changed', 'UsersModule', 'User', 's:5:"sally";'),
(135, 7, 1, '2013-06-25 12:29:37', 'Item Created', 'ZurmoModule', 'User', 's:10:"Mary Smith";'),
(136, 7, 1, '2013-06-25 12:29:37', 'User Password Changed', 'UsersModule', 'User', 's:4:"mary";'),
(137, 8, 1, '2013-06-25 12:29:37', 'Item Created', 'ZurmoModule', 'User', 's:11:"Katie Smith";'),
(138, 8, 1, '2013-06-25 12:29:37', 'User Password Changed', 'UsersModule', 'User', 's:5:"katie";'),
(139, 9, 1, '2013-06-25 12:29:38', 'Item Created', 'ZurmoModule', 'User', 's:10:"Jill Smith";'),
(140, 9, 1, '2013-06-25 12:29:38', 'User Password Changed', 'UsersModule', 'User', 's:4:"jill";'),
(141, 10, 1, '2013-06-25 12:29:38', 'Item Created', 'ZurmoModule', 'User', 's:9:"Sam Smith";'),
(142, 10, 1, '2013-06-25 12:29:38', 'User Password Changed', 'UsersModule', 'User', 's:3:"sam";'),
(143, 2, 1, '2013-06-25 12:29:38', 'Item Created', 'ZurmoModule', 'Account', 's:9:"Gringotts";'),
(144, 3, 1, '2013-06-25 12:29:38', 'Item Created', 'ZurmoModule', 'Account', 's:23:"Big T Burgers and Fries";'),
(145, 4, 1, '2013-06-25 12:29:38', 'Item Created', 'ZurmoModule', 'Account', 's:12:"Sample, Inc.";'),
(146, 5, 1, '2013-06-25 12:29:38', 'Item Created', 'ZurmoModule', 'Account', 's:14:"Allied Biscuit";'),
(147, 6, 1, '2013-06-25 12:29:38', 'Item Created', 'ZurmoModule', 'Account', 's:10:"Globo-Chem";'),
(148, 7, 1, '2013-06-25 12:29:39', 'Item Created', 'ZurmoModule', 'Account', 's:17:"Wayne Enterprises";'),
(149, 2, 1, '2013-06-25 12:29:39', 'Item Created', 'ZurmoModule', 'MarketingList', 's:9:"Prospects";'),
(150, 3, 1, '2013-06-25 12:29:39', 'Item Created', 'ZurmoModule', 'MarketingList', 's:5:"Sales";'),
(151, 4, 1, '2013-06-25 12:29:39', 'Item Created', 'ZurmoModule', 'MarketingList', 's:7:"Clients";'),
(152, 5, 1, '2013-06-25 12:29:39', 'Item Created', 'ZurmoModule', 'MarketingList', 's:9:"Companies";'),
(153, 6, 1, '2013-06-25 12:29:39', 'Item Created', 'ZurmoModule', 'MarketingList', 's:10:"New Offers";'),
(154, 2, 1, '2013-06-25 12:29:39', 'Item Created', 'ZurmoModule', 'Contact', 's:13:"Jose Robinson";'),
(155, 3, 1, '2013-06-25 12:29:40', 'Item Created', 'ZurmoModule', 'Contact', 's:11:"Kirby Davis";'),
(156, 4, 1, '2013-06-25 12:29:40', 'Item Created', 'ZurmoModule', 'Contact', 's:12:"Laura Miller";'),
(157, 5, 1, '2013-06-25 12:29:40', 'Item Created', 'ZurmoModule', 'Contact', 's:15:"Walter Williams";'),
(158, 6, 1, '2013-06-25 12:29:40', 'Item Created', 'ZurmoModule', 'Contact', 's:12:"Alice Martin";'),
(159, 7, 1, '2013-06-25 12:29:40', 'Item Created', 'ZurmoModule', 'Contact', 's:11:"Jeffrey Lee";'),
(160, 8, 1, '2013-06-25 12:29:40', 'Item Created', 'ZurmoModule', 'Contact', 's:11:"Maya Wilson";'),
(161, 9, 1, '2013-06-25 12:29:40', 'Item Created', 'ZurmoModule', 'Contact', 's:13:"Kirby Johnson";'),
(162, 10, 1, '2013-06-25 12:29:41', 'Item Created', 'ZurmoModule', 'Contact', 's:12:"Sarah Harris";'),
(163, 11, 1, '2013-06-25 12:29:41', 'Item Created', 'ZurmoModule', 'Contact', 's:12:"Sarah Harris";'),
(164, 12, 1, '2013-06-25 12:29:41', 'Item Created', 'ZurmoModule', 'Contact', 's:12:"Ester Taylor";'),
(165, 13, 1, '2013-06-25 12:29:41', 'Item Created', 'ZurmoModule', 'Contact', 's:13:"Jake Williams";'),
(166, 2, 1, '2013-06-25 12:29:49', 'Item Created', 'ZurmoModule', 'Autoresponder', 's:23:"You are now subscribed.";'),
(167, 3, 1, '2013-06-25 12:29:49', 'Item Created', 'ZurmoModule', 'Autoresponder', 's:21:"You subscribed today.";'),
(168, 4, 1, '2013-06-25 12:29:49', 'Item Created', 'ZurmoModule', 'Autoresponder', 's:24:"You are now unsubscribed";'),
(169, 5, 1, '2013-06-25 12:29:49', 'Item Created', 'ZurmoModule', 'Autoresponder', 's:47:"Your unsubscription triggered the next big bang";'),
(170, 2, 1, '2013-06-25 12:29:49', 'Item Created', 'ZurmoModule', 'EmailFolder', 's:5:"Draft";'),
(171, 3, 1, '2013-06-25 12:29:49', 'Item Created', 'ZurmoModule', 'EmailFolder', 's:5:"Inbox";'),
(172, 4, 1, '2013-06-25 12:29:49', 'Item Created', 'ZurmoModule', 'EmailFolder', 's:4:"Sent";'),
(173, 5, 1, '2013-06-25 12:29:49', 'Item Created', 'ZurmoModule', 'EmailFolder', 's:6:"Outbox";'),
(174, 6, 1, '2013-06-25 12:29:49', 'Item Created', 'ZurmoModule', 'EmailFolder', 's:12:"Outbox Error";'),
(175, 7, 1, '2013-06-25 12:29:49', 'Item Created', 'ZurmoModule', 'EmailFolder', 's:14:"Outbox Failure";'),
(176, 8, 1, '2013-06-25 12:29:49', 'Item Created', 'ZurmoModule', 'EmailFolder', 's:8:"Archived";'),
(177, 9, 1, '2013-06-25 12:29:49', 'Item Created', 'ZurmoModule', 'EmailFolder', 's:18:"Archived Unmatched";'),
(178, 2, 1, '2013-06-25 12:29:49', 'Item Created', 'ZurmoModule', 'EmailBox', 's:7:"Default";'),
(179, 2, 1, '2013-06-25 12:29:50', 'Item Created', 'ZurmoModule', 'AutoresponderItemActivity', 's:40:"2013-06-25 12:29:49: Jake Williams/Click";'),
(180, 3, 1, '2013-06-25 12:29:50', 'Item Created', 'ZurmoModule', 'AutoresponderItemActivity', 's:42:"2013-06-25 12:29:50: Walter Williams/Click";'),
(181, 4, 1, '2013-06-25 12:29:50', 'Item Created', 'ZurmoModule', 'AutoresponderItemActivity', 's:40:"2013-06-25 12:29:50: Jake Williams/Click";'),
(182, 5, 1, '2013-06-25 12:29:50', 'Item Created', 'ZurmoModule', 'AutoresponderItemActivity', 's:40:"2013-06-25 12:29:50: Jake Williams/Click";'),
(183, 6, 1, '2013-06-25 12:29:50', 'Item Created', 'ZurmoModule', 'AutoresponderItemActivity', 's:40:"2013-06-25 12:29:50: Jake Williams/Click";'),
(184, 7, 1, '2013-06-25 12:29:50', 'Item Created', 'ZurmoModule', 'AutoresponderItemActivity', 's:40:"2013-06-25 12:29:50: Jose Robinson/Click";'),
(185, 8, 1, '2013-06-25 12:29:50', 'Item Created', 'ZurmoModule', 'AutoresponderItemActivity', 's:42:"2013-06-25 12:29:50: Walter Williams/Click";'),
(186, 9, 1, '2013-06-25 12:29:50', 'Item Created', 'ZurmoModule', 'AutoresponderItemActivity', 's:42:"2013-06-25 12:29:50: Walter Williams/Click";'),
(187, 10, 1, '2013-06-25 12:29:50', 'Item Created', 'ZurmoModule', 'AutoresponderItemActivity', 's:42:"2013-06-25 12:29:50: Walter Williams/Click";'),
(188, 11, 1, '2013-06-25 12:29:50', 'Item Created', 'ZurmoModule', 'AutoresponderItemActivity', 's:42:"2013-06-25 12:29:50: Walter Williams/Click";'),
(189, 12, 1, '2013-06-25 12:29:51', 'Item Created', 'ZurmoModule', 'AutoresponderItemActivity', 's:40:"2013-06-25 12:29:50: Jake Williams/Click";'),
(190, 13, 1, '2013-06-25 12:29:51', 'Item Created', 'ZurmoModule', 'AutoresponderItemActivity', 's:38:"2013-06-25 12:29:51: Kirby Davis/Click";'),
(191, 14, 1, '2013-06-25 12:29:51', 'Item Created', 'ZurmoModule', 'AutoresponderItemActivity', 's:38:"2013-06-25 12:29:51: Laura Miller/Open";'),
(192, 15, 1, '2013-06-25 12:29:51', 'Item Created', 'ZurmoModule', 'AutoresponderItemActivity', 's:39:"2013-06-25 12:29:51: Laura Miller/Click";'),
(193, 16, 1, '2013-06-25 12:29:51', 'Item Created', 'ZurmoModule', 'AutoresponderItemActivity', 's:40:"2013-06-25 12:29:51: Alice Martin/Bounce";'),
(194, 17, 1, '2013-06-25 12:29:51', 'Item Created', 'ZurmoModule', 'AutoresponderItemActivity', 's:42:"2013-06-25 12:29:51: Walter Williams/Click";'),
(195, 18, 1, '2013-06-25 12:29:51', 'Item Created', 'ZurmoModule', 'AutoresponderItemActivity', 's:41:"2013-06-25 12:29:51: Walter Williams/Open";'),
(196, 19, 1, '2013-06-25 12:29:51', 'Item Created', 'ZurmoModule', 'AutoresponderItemActivity', 's:39:"2013-06-25 12:29:51: Kirby Johnson/Open";'),
(197, 2, 1, '2013-06-25 12:29:52', 'Item Created', 'ZurmoModule', 'EmailMessage', 's:26:"A test archived sent email";'),
(198, 3, 1, '2013-06-25 12:29:54', 'Item Created', 'ZurmoModule', 'EmailMessage', 's:26:"A test archived sent email";'),
(199, 4, 1, '2013-06-25 12:29:56', 'Item Created', 'ZurmoModule', 'EmailMessage', 's:26:"A test archived sent email";'),
(200, 5, 1, '2013-06-25 12:29:59', 'Item Created', 'ZurmoModule', 'EmailMessage', 's:26:"A test archived sent email";'),
(201, 6, 1, '2013-06-25 12:30:01', 'Item Created', 'ZurmoModule', 'EmailMessage', 's:26:"A test archived sent email";'),
(202, 7, 1, '2013-06-25 12:30:03', 'Item Created', 'ZurmoModule', 'EmailMessage', 's:26:"A test archived sent email";'),
(203, 8, 1, '2013-06-25 12:30:06', 'Item Created', 'ZurmoModule', 'EmailMessage', 's:26:"A test archived sent email";'),
(204, 9, 1, '2013-06-25 12:30:08', 'Item Created', 'ZurmoModule', 'EmailMessage', 's:26:"A test archived sent email";'),
(205, 10, 1, '2013-06-25 12:30:10', 'Item Created', 'ZurmoModule', 'EmailMessage', 's:26:"A test archived sent email";'),
(206, 11, 1, '2013-06-25 12:30:12', 'Item Created', 'ZurmoModule', 'EmailMessage', 's:26:"A test archived sent email";'),
(207, 12, 1, '2013-06-25 12:30:15', 'Item Created', 'ZurmoModule', 'EmailMessage', 's:26:"A test archived sent email";'),
(208, 13, 1, '2013-06-25 12:30:17', 'Item Created', 'ZurmoModule', 'EmailMessage', 's:26:"A test archived sent email";'),
(209, 14, 1, '2013-06-25 12:30:19', 'Item Created', 'ZurmoModule', 'EmailMessage', 's:26:"A test archived sent email";'),
(210, 15, 1, '2013-06-25 12:30:21', 'Item Created', 'ZurmoModule', 'EmailMessage', 's:26:"A test archived sent email";'),
(211, 16, 1, '2013-06-25 12:30:21', 'Item Created', 'ZurmoModule', 'EmailMessage', 's:26:"A test archived sent email";'),
(212, 17, 1, '2013-06-25 12:30:21', 'Item Created', 'ZurmoModule', 'EmailMessage', 's:26:"A test archived sent email";'),
(213, 18, 1, '2013-06-25 12:30:21', 'Item Created', 'ZurmoModule', 'EmailMessage', 's:26:"A test archived sent email";'),
(214, 19, 1, '2013-06-25 12:30:21', 'Item Created', 'ZurmoModule', 'EmailMessage', 's:26:"A test archived sent email";'),
(215, 2, 1, '2013-06-25 12:30:21', 'Item Created', 'ZurmoModule', 'Campaign', 's:28:"10% discount for new clients";'),
(216, 3, 1, '2013-06-25 12:30:22', 'Item Created', 'ZurmoModule', 'Campaign', 's:32:"5% discount for existing clients";'),
(217, 4, 1, '2013-06-25 12:30:22', 'Item Created', 'ZurmoModule', 'Campaign', 's:33:"Infrastructure redesign completed";'),
(218, 5, 1, '2013-06-25 12:30:22', 'Item Created', 'ZurmoModule', 'Campaign', 's:14:"Christmas Sale";'),
(219, 6, 1, '2013-06-25 12:30:22', 'Item Created', 'ZurmoModule', 'Campaign', 's:22:"Zurmo Upgrade Complete";'),
(220, 7, 1, '2013-06-25 12:30:22', 'Item Created', 'ZurmoModule', 'Campaign', 's:31:"Loyalty Program - Special Deals";'),
(221, 8, 1, '2013-06-25 12:30:22', 'Item Created', 'ZurmoModule', 'Campaign', 's:27:"Loyalty Member - Enroll Now";'),
(222, 9, 1, '2013-06-25 12:30:23', 'Item Created', 'ZurmoModule', 'Campaign', 's:28:"Loyalty Members - Free Lunch";'),
(223, 10, 1, '2013-06-25 12:30:23', 'Item Created', 'ZurmoModule', 'Campaign', 's:32:"Loyalty Members - Bring a friend";'),
(224, 11, 1, '2013-06-25 12:30:23', 'Item Created', 'ZurmoModule', 'Campaign', 's:30:"Loyalty Members - Trip to Rome";'),
(225, 2, 1, '2013-06-25 12:30:24', 'Item Created', 'ZurmoModule', 'CampaignItemActivity', 's:40:"2013-06-25 12:30:24: Jake Williams/Click";'),
(226, 3, 1, '2013-06-25 12:30:24', 'Item Created', 'ZurmoModule', 'CampaignItemActivity', 's:39:"2013-06-25 12:30:24: Ester Taylor/Click";'),
(227, 4, 1, '2013-06-25 12:30:24', 'Item Created', 'ZurmoModule', 'CampaignItemActivity', 's:39:"2013-06-25 12:30:24: Sarah Harris/Click";'),
(228, 5, 1, '2013-06-25 12:30:24', 'Item Created', 'ZurmoModule', 'CampaignItemActivity', 's:40:"2013-06-25 12:30:24: Kirby Johnson/Click";'),
(229, 6, 1, '2013-06-25 12:30:24', 'Item Created', 'ZurmoModule', 'CampaignItemActivity', 's:39:"2013-06-25 12:30:24: Maya Wilson/Bounce";'),
(230, 7, 1, '2013-06-25 12:30:24', 'Item Created', 'ZurmoModule', 'CampaignItemActivity', 's:39:"2013-06-25 12:30:24: Sarah Harris/Click";'),
(231, 8, 1, '2013-06-25 12:30:24', 'Item Created', 'ZurmoModule', 'CampaignItemActivity', 's:38:"2013-06-25 12:30:24: Kirby Davis/Click";'),
(232, 9, 1, '2013-06-25 12:30:24', 'Item Created', 'ZurmoModule', 'CampaignItemActivity', 's:38:"2013-06-25 12:30:24: Maya Wilson/Click";'),
(233, 10, 1, '2013-06-25 12:30:24', 'Item Created', 'ZurmoModule', 'CampaignItemActivity', 's:38:"2013-06-25 12:30:24: Maya Wilson/Click";'),
(234, 11, 1, '2013-06-25 12:30:24', 'Item Created', 'ZurmoModule', 'CampaignItemActivity', 's:40:"2013-06-25 12:30:24: Jose Robinson/Click";'),
(235, 12, 1, '2013-06-25 12:30:24', 'Item Created', 'ZurmoModule', 'CampaignItemActivity', 's:39:"2013-06-25 12:30:24: Laura Miller/Click";'),
(236, 13, 1, '2013-06-25 12:30:24', 'Item Created', 'ZurmoModule', 'CampaignItemActivity', 's:40:"2013-06-25 12:30:24: Alice Martin/Bounce";'),
(237, 14, 1, '2013-06-25 12:30:24', 'Item Created', 'ZurmoModule', 'CampaignItemActivity', 's:40:"2013-06-25 12:30:24: Kirby Johnson/Click";'),
(238, 15, 1, '2013-06-25 12:30:24', 'Item Created', 'ZurmoModule', 'CampaignItemActivity', 's:38:"2013-06-25 12:30:24: Maya Wilson/Click";'),
(239, 16, 1, '2013-06-25 12:30:24', 'Item Created', 'ZurmoModule', 'CampaignItemActivity', 's:40:"2013-06-25 12:30:24: Jake Williams/Click";'),
(240, 17, 1, '2013-06-25 12:30:24', 'Item Created', 'ZurmoModule', 'CampaignItemActivity', 's:38:"2013-06-25 12:30:24: Jeffrey Lee/Click";'),
(241, 18, 1, '2013-06-25 12:30:25', 'Item Created', 'ZurmoModule', 'CampaignItemActivity', 's:37:"2013-06-25 12:30:25: Maya Wilson/Open";'),
(242, 19, 1, '2013-06-25 12:30:25', 'Item Created', 'ZurmoModule', 'CampaignItemActivity', 's:39:"2013-06-25 12:30:25: Kirby Davis/Bounce";'),
(243, 20, 1, '2013-06-25 12:30:25', 'Item Created', 'ZurmoModule', 'EmailMessage', 's:26:"A test archived sent email";'),
(244, 21, 1, '2013-06-25 12:30:25', 'Item Created', 'ZurmoModule', 'EmailMessage', 's:26:"A test archived sent email";'),
(245, 22, 1, '2013-06-25 12:30:25', 'Item Created', 'ZurmoModule', 'EmailMessage', 's:26:"A test archived sent email";'),
(246, 23, 1, '2013-06-25 12:30:25', 'Item Created', 'ZurmoModule', 'EmailMessage', 's:26:"A test archived sent email";'),
(247, 24, 1, '2013-06-25 12:30:25', 'Item Created', 'ZurmoModule', 'EmailMessage', 's:26:"A test archived sent email";'),
(248, 25, 1, '2013-06-25 12:30:26', 'Item Created', 'ZurmoModule', 'EmailMessage', 's:26:"A test archived sent email";'),
(249, 26, 1, '2013-06-25 12:30:26', 'Item Created', 'ZurmoModule', 'EmailMessage', 's:26:"A test archived sent email";'),
(250, 27, 1, '2013-06-25 12:30:26', 'Item Created', 'ZurmoModule', 'EmailMessage', 's:26:"A test archived sent email";'),
(251, 28, 1, '2013-06-25 12:30:26', 'Item Created', 'ZurmoModule', 'EmailMessage', 's:26:"A test archived sent email";'),
(252, 29, 1, '2013-06-25 12:30:26', 'Item Created', 'ZurmoModule', 'EmailMessage', 's:26:"A test archived sent email";'),
(253, 30, 1, '2013-06-25 12:30:26', 'Item Created', 'ZurmoModule', 'EmailMessage', 's:26:"A test archived sent email";'),
(254, 31, 1, '2013-06-25 12:30:27', 'Item Created', 'ZurmoModule', 'EmailMessage', 's:26:"A test archived sent email";'),
(255, 32, 1, '2013-06-25 12:30:27', 'Item Created', 'ZurmoModule', 'EmailMessage', 's:26:"A test archived sent email";'),
(256, 33, 1, '2013-06-25 12:30:27', 'Item Created', 'ZurmoModule', 'EmailMessage', 's:26:"A test archived sent email";'),
(257, 34, 1, '2013-06-25 12:30:27', 'Item Created', 'ZurmoModule', 'EmailMessage', 's:26:"A test archived sent email";'),
(258, 35, 1, '2013-06-25 12:30:27', 'Item Created', 'ZurmoModule', 'EmailMessage', 's:26:"A test archived sent email";'),
(259, 36, 1, '2013-06-25 12:30:27', 'Item Created', 'ZurmoModule', 'EmailMessage', 's:26:"A test archived sent email";'),
(260, 37, 1, '2013-06-25 12:30:28', 'Item Created', 'ZurmoModule', 'EmailMessage', 's:26:"A test archived sent email";'),
(261, 2, 1, '2013-06-25 12:30:28', 'Item Created', 'ZurmoModule', 'Comment', 's:16:"Interesting Idea";'),
(262, 3, 1, '2013-06-25 12:30:28', 'Item Created', 'ZurmoModule', 'Comment', 's:74:"I am not sure Mars is best.  What about Titan?  It offers some advantages.";'),
(263, 4, 1, '2013-06-25 12:30:28', 'Item Created', 'ZurmoModule', 'Comment', 's:30:"Are we allowed to hire aliens?";'),
(264, 5, 1, '2013-06-25 12:30:28', 'Item Created', 'ZurmoModule', 'Comment', 's:236:"Some info about Mars: Mars is the fourth planet from the Sun in the Solar System. Named after the Roman god of war, Mars, it is often described as the "Red Planet" as the iron oxide prevalent on its surface gives it a reddish appearance";'),
(265, 6, 1, '2013-06-25 12:30:28', 'Item Created', 'ZurmoModule', 'Comment', 's:32:"Great idea guys. Keep it coming.";'),
(266, 2, 1, '2013-06-25 12:30:28', 'Item Created', 'ZurmoModule', 'Conversation', 's:65:"Should we consider building a new corporate headquarters on Mars?";'),
(267, 7, 1, '2013-06-25 12:30:28', 'Item Created', 'ZurmoModule', 'Comment', 's:19:"Elephants are cool.";'),
(268, 8, 1, '2013-06-25 12:30:28', 'Item Created', 'ZurmoModule', 'Comment', 's:319:"What about giraffes.  Here is some info: he giraffe (Giraffa camelopardalis) is an African even-toed ungulate mammal, the tallest living terrestrial animal and the largest ruminant. Its specific name refers to its camel-like face and the patches of color on its fur, which bear a vague resemblance to a leopard''s spots.";'),
(269, 9, 1, '2013-06-25 12:30:28', 'Item Created', 'ZurmoModule', 'Comment', 's:61:"I think something like a snake eating a mouse could be funny.";'),
(270, 10, 1, '2013-06-25 12:30:28', 'Item Created', 'ZurmoModule', 'Comment', 's:32:"Great idea guys. Keep it coming.";'),
(271, 3, 1, '2013-06-25 12:30:28', 'Item Created', 'ZurmoModule', 'Conversation', 's:87:"I am considering a new marketing campaign that uses elephants.  What do you guys think?";'),
(272, 11, 1, '2013-06-25 12:30:29', 'Item Created', 'ZurmoModule', 'Comment', 's:59:"That should be fun.  Bring your laptop in case we need you!";'),
(273, 12, 1, '2013-06-25 12:30:29', 'Item Created', 'ZurmoModule', 'Comment', 's:51:"Do not bring your laptop.  That would ruin the fun.";'),
(274, 13, 1, '2013-06-25 12:30:29', 'Item Created', 'ZurmoModule', 'Comment', 's:34:"Make sure you hike up the volcano.";'),
(275, 14, 1, '2013-06-25 12:30:29', 'Item Created', 'ZurmoModule', 'Comment', 's:26:"I want to take a vacation.";'),
(276, 15, 1, '2013-06-25 12:30:29', 'Item Created', 'ZurmoModule', 'Comment', 's:63:"We should have a company retreat in Hawaii.  That would be fun!";'),
(277, 16, 1, '2013-06-25 12:30:29', 'Item Created', 'ZurmoModule', 'Comment', 's:32:"Great idea guys. Keep it coming.";'),
(278, 4, 1, '2013-06-25 12:30:29', 'Item Created', 'ZurmoModule', 'Conversation', 's:25:"Vacation time in December";'),
(279, 2, 1, '2013-06-25 12:30:29', 'Item Created', 'ZurmoModule', 'EmailTemplate', 's:14:"Happy Birthday";'),
(280, 3, 1, '2013-06-25 12:30:29', 'Item Created', 'ZurmoModule', 'EmailTemplate', 's:8:"Discount";'),
(281, 4, 1, '2013-06-25 12:30:29', 'Item Created', 'ZurmoModule', 'EmailTemplate', 's:14:"Downtime Alert";'),
(282, 5, 1, '2013-06-25 12:30:29', 'Item Created', 'ZurmoModule', 'EmailTemplate', 's:14:"Sales decrease";'),
(283, 6, 1, '2013-06-25 12:30:29', 'Item Created', 'ZurmoModule', 'EmailTemplate', 's:14:"Missions alert";'),
(284, 7, 1, '2013-06-25 12:30:29', 'Item Created', 'ZurmoModule', 'EmailTemplate', 's:12:"Inbox Update";'),
(285, 2, 1, '2013-06-25 12:30:29', 'Item Created', 'ZurmoModule', 'GameScore', 's:9:"LoginUser";'),
(286, 2, 1, '2013-06-25 12:30:29', 'Item Created', 'ZurmoModule', 'GamePoint', 's:12:"UserAdoption";'),
(287, 3, 1, '2013-06-25 12:30:29', 'Item Created', 'ZurmoModule', 'GameScore', 's:13:"CreateAccount";'),
(288, 3, 1, '2013-06-25 12:30:30', 'Item Created', 'ZurmoModule', 'GamePoint', 's:11:"NewBusiness";'),
(289, 2, 1, '2013-06-25 12:30:30', 'Item Created', 'ZurmoModule', 'GameBadge', 's:11:"LoginUser 2";'),
(290, 3, 1, '2013-06-25 12:30:30', 'Item Created', 'ZurmoModule', 'GameBadge', 's:15:"CreateAccount 3";'),
(291, 2, 1, '2013-06-25 12:30:30', 'Item Created', 'ZurmoModule', 'GameLevel', 's:7:"General";'),
(292, 3, 1, '2013-06-25 12:30:30', 'Item Created', 'ZurmoModule', 'GameLevel', 's:11:"NewBusiness";'),
(293, 4, 1, '2013-06-25 12:30:30', 'Item Created', 'ZurmoModule', 'GameScore', 's:9:"LoginUser";'),
(294, 4, 1, '2013-06-25 12:30:30', 'Item Created', 'ZurmoModule', 'GamePoint', 's:12:"UserAdoption";'),
(295, 5, 1, '2013-06-25 12:30:30', 'Item Created', 'ZurmoModule', 'GameScore', 's:13:"CreateAccount";'),
(296, 5, 1, '2013-06-25 12:30:30', 'Item Created', 'ZurmoModule', 'GamePoint', 's:11:"NewBusiness";'),
(297, 4, 1, '2013-06-25 12:30:30', 'Item Created', 'ZurmoModule', 'GameBadge', 's:11:"LoginUser 2";'),
(298, 5, 1, '2013-06-25 12:30:30', 'Item Created', 'ZurmoModule', 'GameBadge', 's:15:"CreateAccount 3";'),
(299, 4, 1, '2013-06-25 12:30:30', 'Item Created', 'ZurmoModule', 'GameLevel', 's:7:"General";'),
(300, 5, 1, '2013-06-25 12:30:30', 'Item Created', 'ZurmoModule', 'GameLevel', 's:11:"NewBusiness";'),
(301, 6, 1, '2013-06-25 12:30:30', 'Item Created', 'ZurmoModule', 'GameScore', 's:9:"LoginUser";'),
(302, 6, 1, '2013-06-25 12:30:30', 'Item Created', 'ZurmoModule', 'GamePoint', 's:12:"UserAdoption";'),
(303, 7, 1, '2013-06-25 12:30:30', 'Item Created', 'ZurmoModule', 'GameScore', 's:13:"CreateAccount";'),
(304, 7, 1, '2013-06-25 12:30:30', 'Item Created', 'ZurmoModule', 'GamePoint', 's:11:"NewBusiness";'),
(305, 6, 1, '2013-06-25 12:30:30', 'Item Created', 'ZurmoModule', 'GameBadge', 's:11:"LoginUser 2";'),
(306, 7, 1, '2013-06-25 12:30:30', 'Item Created', 'ZurmoModule', 'GameBadge', 's:15:"CreateAccount 3";'),
(307, 6, 1, '2013-06-25 12:30:30', 'Item Created', 'ZurmoModule', 'GameLevel', 's:7:"General";'),
(308, 7, 1, '2013-06-25 12:30:30', 'Item Created', 'ZurmoModule', 'GameLevel', 's:11:"NewBusiness";'),
(309, 8, 1, '2013-06-25 12:30:30', 'Item Created', 'ZurmoModule', 'GameScore', 's:9:"LoginUser";'),
(310, 8, 1, '2013-06-25 12:30:30', 'Item Created', 'ZurmoModule', 'GamePoint', 's:12:"UserAdoption";'),
(311, 9, 1, '2013-06-25 12:30:30', 'Item Created', 'ZurmoModule', 'GameScore', 's:13:"CreateAccount";'),
(312, 9, 1, '2013-06-25 12:30:30', 'Item Created', 'ZurmoModule', 'GamePoint', 's:11:"NewBusiness";'),
(313, 8, 1, '2013-06-25 12:30:30', 'Item Created', 'ZurmoModule', 'GameBadge', 's:11:"LoginUser 2";'),
(314, 9, 1, '2013-06-25 12:30:30', 'Item Created', 'ZurmoModule', 'GameBadge', 's:15:"CreateAccount 3";'),
(315, 8, 1, '2013-06-25 12:30:30', 'Item Created', 'ZurmoModule', 'GameLevel', 's:7:"General";'),
(316, 9, 1, '2013-06-25 12:30:30', 'Item Created', 'ZurmoModule', 'GameLevel', 's:11:"NewBusiness";'),
(317, 10, 1, '2013-06-25 12:30:30', 'Item Created', 'ZurmoModule', 'GameScore', 's:9:"LoginUser";'),
(318, 10, 1, '2013-06-25 12:30:30', 'Item Created', 'ZurmoModule', 'GamePoint', 's:12:"UserAdoption";'),
(319, 11, 1, '2013-06-25 12:30:30', 'Item Created', 'ZurmoModule', 'GameScore', 's:13:"CreateAccount";'),
(320, 11, 1, '2013-06-25 12:30:30', 'Item Created', 'ZurmoModule', 'GamePoint', 's:11:"NewBusiness";'),
(321, 10, 1, '2013-06-25 12:30:30', 'Item Created', 'ZurmoModule', 'GameBadge', 's:11:"LoginUser 2";'),
(322, 11, 1, '2013-06-25 12:30:30', 'Item Created', 'ZurmoModule', 'GameBadge', 's:15:"CreateAccount 3";'),
(323, 10, 1, '2013-06-25 12:30:30', 'Item Created', 'ZurmoModule', 'GameLevel', 's:7:"General";'),
(324, 11, 1, '2013-06-25 12:30:30', 'Item Created', 'ZurmoModule', 'GameLevel', 's:11:"NewBusiness";'),
(325, 12, 1, '2013-06-25 12:30:30', 'Item Created', 'ZurmoModule', 'GameScore', 's:9:"LoginUser";'),
(326, 12, 1, '2013-06-25 12:30:30', 'Item Created', 'ZurmoModule', 'GamePoint', 's:12:"UserAdoption";'),
(327, 13, 1, '2013-06-25 12:30:30', 'Item Created', 'ZurmoModule', 'GameScore', 's:13:"CreateAccount";'),
(328, 13, 1, '2013-06-25 12:30:30', 'Item Created', 'ZurmoModule', 'GamePoint', 's:11:"NewBusiness";'),
(329, 12, 1, '2013-06-25 12:30:30', 'Item Created', 'ZurmoModule', 'GameBadge', 's:11:"LoginUser 2";'),
(330, 13, 1, '2013-06-25 12:30:30', 'Item Created', 'ZurmoModule', 'GameBadge', 's:15:"CreateAccount 3";'),
(331, 12, 1, '2013-06-25 12:30:30', 'Item Created', 'ZurmoModule', 'GameLevel', 's:7:"General";'),
(332, 13, 1, '2013-06-25 12:30:30', 'Item Created', 'ZurmoModule', 'GameLevel', 's:11:"NewBusiness";'),
(333, 14, 1, '2013-06-25 12:30:31', 'Item Created', 'ZurmoModule', 'GameScore', 's:9:"LoginUser";'),
(334, 14, 1, '2013-06-25 12:30:31', 'Item Created', 'ZurmoModule', 'GamePoint', 's:12:"UserAdoption";'),
(335, 15, 1, '2013-06-25 12:30:31', 'Item Created', 'ZurmoModule', 'GameScore', 's:13:"CreateAccount";'),
(336, 15, 1, '2013-06-25 12:30:31', 'Item Created', 'ZurmoModule', 'GamePoint', 's:11:"NewBusiness";'),
(337, 14, 1, '2013-06-25 12:30:31', 'Item Created', 'ZurmoModule', 'GameBadge', 's:11:"LoginUser 2";'),
(338, 15, 1, '2013-06-25 12:30:31', 'Item Created', 'ZurmoModule', 'GameBadge', 's:15:"CreateAccount 3";'),
(339, 14, 1, '2013-06-25 12:30:31', 'Item Created', 'ZurmoModule', 'GameLevel', 's:7:"General";'),
(340, 15, 1, '2013-06-25 12:30:31', 'Item Created', 'ZurmoModule', 'GameLevel', 's:11:"NewBusiness";'),
(341, 16, 1, '2013-06-25 12:30:31', 'Item Created', 'ZurmoModule', 'GameScore', 's:9:"LoginUser";'),
(342, 16, 1, '2013-06-25 12:30:31', 'Item Created', 'ZurmoModule', 'GamePoint', 's:12:"UserAdoption";'),
(343, 17, 1, '2013-06-25 12:30:31', 'Item Created', 'ZurmoModule', 'GameScore', 's:13:"CreateAccount";'),
(344, 17, 1, '2013-06-25 12:30:31', 'Item Created', 'ZurmoModule', 'GamePoint', 's:11:"NewBusiness";'),
(345, 16, 1, '2013-06-25 12:30:31', 'Item Created', 'ZurmoModule', 'GameBadge', 's:11:"LoginUser 2";'),
(346, 17, 1, '2013-06-25 12:30:31', 'Item Created', 'ZurmoModule', 'GameBadge', 's:15:"CreateAccount 3";'),
(347, 16, 1, '2013-06-25 12:30:31', 'Item Created', 'ZurmoModule', 'GameLevel', 's:7:"General";'),
(348, 17, 1, '2013-06-25 12:30:31', 'Item Created', 'ZurmoModule', 'GameLevel', 's:11:"NewBusiness";'),
(349, 18, 1, '2013-06-25 12:30:31', 'Item Created', 'ZurmoModule', 'GameScore', 's:9:"LoginUser";'),
(350, 18, 1, '2013-06-25 12:30:31', 'Item Created', 'ZurmoModule', 'GamePoint', 's:12:"UserAdoption";'),
(351, 19, 1, '2013-06-25 12:30:31', 'Item Created', 'ZurmoModule', 'GameScore', 's:13:"CreateAccount";'),
(352, 19, 1, '2013-06-25 12:30:31', 'Item Created', 'ZurmoModule', 'GamePoint', 's:11:"NewBusiness";'),
(353, 18, 1, '2013-06-25 12:30:31', 'Item Created', 'ZurmoModule', 'GameBadge', 's:11:"LoginUser 2";'),
(354, 19, 1, '2013-06-25 12:30:31', 'Item Created', 'ZurmoModule', 'GameBadge', 's:15:"CreateAccount 3";'),
(355, 18, 1, '2013-06-25 12:30:31', 'Item Created', 'ZurmoModule', 'GameLevel', 's:7:"General";'),
(356, 19, 1, '2013-06-25 12:30:31', 'Item Created', 'ZurmoModule', 'GameLevel', 's:11:"NewBusiness";'),
(357, 14, 1, '2013-06-25 12:30:31', 'Item Created', 'ZurmoModule', 'Contact', 's:14:"Kirby Williams";'),
(358, 15, 1, '2013-06-25 12:30:31', 'Item Created', 'ZurmoModule', 'Contact', 's:10:"Ray Harris";'),
(359, 16, 1, '2013-06-25 12:30:31', 'Item Created', 'ZurmoModule', 'Contact', 's:16:"Sophie Rodriguez";'),
(360, 17, 1, '2013-06-25 12:30:31', 'Item Created', 'ZurmoModule', 'Contact', 's:7:"Nev Lee";'),
(361, 18, 1, '2013-06-25 12:30:32', 'Item Created', 'ZurmoModule', 'Contact', 's:9:"Kirby Lee";'),
(362, 19, 1, '2013-06-25 12:30:32', 'Item Created', 'ZurmoModule', 'Contact', 's:13:"Jeffrey Clark";'),
(363, 20, 1, '2013-06-25 12:30:32', 'Item Created', 'ZurmoModule', 'Contact', 's:12:"Lisa Johnson";'),
(364, 21, 1, '2013-06-25 12:30:32', 'Item Created', 'ZurmoModule', 'Contact', 's:12:"Ray Robinson";'),
(365, 22, 1, '2013-06-25 12:30:32', 'Item Created', 'ZurmoModule', 'Contact', 's:10:"Jake Lewis";'),
(366, 23, 1, '2013-06-25 12:30:32', 'Item Created', 'ZurmoModule', 'Contact', 's:12:"Alice Walker";'),
(367, 24, 1, '2013-06-25 12:30:32', 'Item Created', 'ZurmoModule', 'Contact', 's:9:"Jose Hall";'),
(368, 25, 1, '2013-06-25 12:30:32', 'Item Created', 'ZurmoModule', 'Contact', 's:12:"Ray Martinez";'),
(369, 2, 1, '2013-06-25 12:30:32', 'Item Created', 'ZurmoModule', 'Opportunity', 's:17:"Training Services";'),
(370, 3, 1, '2013-06-25 12:30:33', 'Item Created', 'ZurmoModule', 'Opportunity', 's:19:"Consulting Services";'),
(371, 4, 1, '2013-06-25 12:30:33', 'Item Created', 'ZurmoModule', 'Opportunity', 's:22:"Open Source Consulting";'),
(372, 5, 1, '2013-06-25 12:30:33', 'Item Created', 'ZurmoModule', 'Opportunity', 's:22:"Open Source Consulting";'),
(373, 6, 1, '2013-06-25 12:30:33', 'Item Created', 'ZurmoModule', 'Opportunity', 's:19:"Enterprise Software";'),
(374, 7, 1, '2013-06-25 12:30:33', 'Item Created', 'ZurmoModule', 'Opportunity', 's:14:"Wonder Widgets";'),
(375, 8, 1, '2013-06-25 12:30:33', 'Item Created', 'ZurmoModule', 'Opportunity', 's:21:"Design Review Service";'),
(376, 9, 1, '2013-06-25 12:30:33', 'Item Created', 'ZurmoModule', 'Opportunity', 's:17:"Training Services";'),
(377, 10, 1, '2013-06-25 12:30:33', 'Item Created', 'ZurmoModule', 'Opportunity', 's:26:"Expensive Software Product";'),
(378, 11, 1, '2013-06-25 12:30:33', 'Item Created', 'ZurmoModule', 'Opportunity', 's:26:"Expensive Software Product";'),
(379, 12, 1, '2013-06-25 12:30:33', 'Item Created', 'ZurmoModule', 'Opportunity', 's:23:"Cross Country Shipments";'),
(380, 13, 1, '2013-06-25 12:30:33', 'Item Created', 'ZurmoModule', 'Opportunity', 's:14:"Wonder Widgets";'),
(381, 2, 1, '2013-06-25 12:30:33', 'Item Created', 'ZurmoModule', 'Meeting', 's:14:"Follow-up call";'),
(382, 3, 1, '2013-06-25 12:30:33', 'Item Created', 'ZurmoModule', 'Meeting', 's:18:"Phase 2 discussion";'),
(383, 4, 1, '2013-06-25 12:30:33', 'Item Created', 'ZurmoModule', 'Meeting', 's:15:"Proposal review";'),
(384, 5, 1, '2013-06-25 12:30:33', 'Item Created', 'ZurmoModule', 'Meeting', 's:21:"Client service review";'),
(385, 6, 1, '2013-06-25 12:30:34', 'Item Created', 'ZurmoModule', 'Meeting', 's:29:"Tradeshow preparation meeting";'),
(386, 7, 1, '2013-06-25 12:30:34', 'Item Created', 'ZurmoModule', 'Meeting', 's:16:"Project kick-off";'),
(387, 8, 1, '2013-06-25 12:30:34', 'Item Created', 'ZurmoModule', 'Meeting', 's:29:"Tradeshow preparation meeting";'),
(388, 9, 1, '2013-06-25 12:30:34', 'Item Created', 'ZurmoModule', 'Meeting', 's:33:"Technical requirements discussion";'),
(389, 10, 1, '2013-06-25 12:30:34', 'Item Created', 'ZurmoModule', 'Meeting', 's:14:"Call follow up";'),
(390, 11, 1, '2013-06-25 12:30:34', 'Item Created', 'ZurmoModule', 'Meeting', 's:14:"Follow-up call";'),
(391, 12, 1, '2013-06-25 12:30:34', 'Item Created', 'ZurmoModule', 'Meeting', 's:21:"Client service review";'),
(392, 13, 1, '2013-06-25 12:30:34', 'Item Created', 'ZurmoModule', 'Meeting', 's:23:"Circle back on proposal";'),
(393, 14, 1, '2013-06-25 12:30:34', 'Item Created', 'ZurmoModule', 'Meeting', 's:29:"Tradeshow preparation meeting";'),
(394, 15, 1, '2013-06-25 12:30:34', 'Item Created', 'ZurmoModule', 'Meeting', 's:15:"Proposal review";'),
(395, 16, 1, '2013-06-25 12:30:34', 'Item Created', 'ZurmoModule', 'Meeting', 's:15:"Proposal review";'),
(396, 17, 1, '2013-06-25 12:30:34', 'Item Created', 'ZurmoModule', 'Meeting', 's:14:"Follow-up call";'),
(397, 18, 1, '2013-06-25 12:30:34', 'Item Created', 'ZurmoModule', 'Meeting', 's:19:"Discuss new pricing";'),
(398, 19, 1, '2013-06-25 12:30:34', 'Item Created', 'ZurmoModule', 'Meeting', 's:15:"Proposal review";'),
(399, 20, 1, '2013-06-25 12:30:34', 'Item Created', 'ZurmoModule', 'Meeting', 's:19:"Discuss new pricing";'),
(400, 21, 1, '2013-06-25 12:30:34', 'Item Created', 'ZurmoModule', 'Meeting', 's:14:"Follow-up call";'),
(401, 22, 1, '2013-06-25 12:30:34', 'Item Created', 'ZurmoModule', 'Meeting', 's:14:"Follow-up call";'),
(402, 23, 1, '2013-06-25 12:30:34', 'Item Created', 'ZurmoModule', 'Meeting', 's:14:"Follow-up call";'),
(403, 24, 1, '2013-06-25 12:30:34', 'Item Created', 'ZurmoModule', 'Meeting', 's:21:"Client service review";'),
(404, 25, 1, '2013-06-25 12:30:34', 'Item Created', 'ZurmoModule', 'Meeting', 's:15:"Proposal review";'),
(405, 26, 1, '2013-06-25 12:30:35', 'Item Created', 'ZurmoModule', 'Meeting', 's:18:"Phase 2 discussion";'),
(406, 27, 1, '2013-06-25 12:30:35', 'Item Created', 'ZurmoModule', 'Meeting', 's:16:"Project kick-off";'),
(407, 28, 1, '2013-06-25 12:30:35', 'Item Created', 'ZurmoModule', 'Meeting', 's:14:"Follow-up call";'),
(408, 29, 1, '2013-06-25 12:30:35', 'Item Created', 'ZurmoModule', 'Meeting', 's:15:"Proposal review";'),
(409, 30, 1, '2013-06-25 12:30:35', 'Item Created', 'ZurmoModule', 'Meeting', 's:16:"Project kick-off";'),
(410, 31, 1, '2013-06-25 12:30:35', 'Item Created', 'ZurmoModule', 'Meeting', 's:16:"Project kick-off";'),
(411, 32, 1, '2013-06-25 12:30:35', 'Item Created', 'ZurmoModule', 'Meeting', 's:15:"Proposal review";'),
(412, 33, 1, '2013-06-25 12:30:35', 'Item Created', 'ZurmoModule', 'Meeting', 's:14:"Follow-up call";'),
(413, 34, 1, '2013-06-25 12:30:35', 'Item Created', 'ZurmoModule', 'Meeting', 's:18:"Phase 2 discussion";'),
(414, 35, 1, '2013-06-25 12:30:35', 'Item Created', 'ZurmoModule', 'Meeting', 's:18:"Phase 2 discussion";'),
(415, 36, 1, '2013-06-25 12:30:35', 'Item Created', 'ZurmoModule', 'Meeting', 's:18:"Phase 2 discussion";'),
(416, 37, 1, '2013-06-25 12:30:35', 'Item Created', 'ZurmoModule', 'Meeting', 's:14:"Follow-up call";'),
(417, 17, 1, '2013-06-25 12:30:35', 'Item Created', 'ZurmoModule', 'Comment', 's:22:"How about at a museum?";'),
(418, 18, 1, '2013-06-25 12:30:35', 'Item Created', 'ZurmoModule', 'Comment', 's:48:"I am going to be out of town, so I can''t attend.";'),
(419, 19, 1, '2013-06-25 12:30:35', 'Item Created', 'ZurmoModule', 'Comment', 's:27:"I guess i can take this on.";'),
(420, 2, 1, '2013-06-25 12:30:35', 'Item Created', 'ZurmoModule', 'Mission', 's:71:"Can someone figure out a good location for the company party this year?";'),
(421, 20, 1, '2013-06-25 12:30:35', 'Item Created', 'ZurmoModule', 'Comment', 's:63:"I don''t even know what this mission is.  Guess I can''t take it.";'),
(422, 21, 1, '2013-06-25 12:30:35', 'Item Created', 'ZurmoModule', 'Comment', 's:26:"Always good to save money!";'),
(423, 3, 1, '2013-06-25 12:30:35', 'Item Created', 'ZurmoModule', 'Mission', 's:58:"Analyze server infrastructure, look for ways to save money";'),
(424, 22, 1, '2013-06-25 12:30:36', 'Item Created', 'ZurmoModule', 'Comment', 's:30:"Can I go to a bank to do this?";'),
(425, 23, 1, '2013-06-25 12:30:36', 'Item Created', 'ZurmoModule', 'Comment', 's:44:"Yes, a bank will notarize a document for you";'),
(426, 4, 1, '2013-06-25 12:30:36', 'Item Created', 'ZurmoModule', 'Mission', 's:27:"Get tax document notarized ";'),
(427, 24, 1, '2013-06-25 12:30:36', 'Item Created', 'ZurmoModule', 'Comment', 's:36:"Is this for our consulting services?";'),
(428, 25, 1, '2013-06-25 12:30:36', 'Item Created', 'ZurmoModule', 'Comment', 's:62:"No, this is for a new offering we will have around our widgets";'),
(429, 5, 1, '2013-06-25 12:30:36', 'Item Created', 'ZurmoModule', 'Mission', 's:54:"Organize the new marketing initiative for summer sales";'),
(430, 2, 1, '2013-06-25 12:30:36', 'Item Created', 'ZurmoModule', 'Note', 's:39:"System integration - jumpstart proposal";'),
(431, 3, 1, '2013-06-25 12:30:36', 'Item Created', 'ZurmoModule', 'Note', 's:39:"System integration - jumpstart proposal";'),
(432, 4, 1, '2013-06-25 12:30:36', 'Item Created', 'ZurmoModule', 'Note', 's:44:"Accouting information regarding wire payment";'),
(433, 5, 1, '2013-06-25 12:30:36', 'Item Created', 'ZurmoModule', 'Note', 's:39:"System integration - jumpstart proposal";'),
(434, 6, 1, '2013-06-25 12:30:36', 'Item Created', 'ZurmoModule', 'Note', 's:39:"System integration - jumpstart proposal";'),
(435, 7, 1, '2013-06-25 12:30:36', 'Item Created', 'ZurmoModule', 'Note', 's:44:"Accouting information regarding wire payment";'),
(436, 8, 1, '2013-06-25 12:30:36', 'Item Created', 'ZurmoModule', 'Note', 's:28:"Competitive landscape notes.";'),
(437, 9, 1, '2013-06-25 12:30:36', 'Item Created', 'ZurmoModule', 'Note', 's:28:"Competitive landscape notes.";'),
(438, 10, 1, '2013-06-25 12:30:36', 'Item Created', 'ZurmoModule', 'Note', 's:28:"E-mail: Re: Product changes.";'),
(439, 11, 1, '2013-06-25 12:30:36', 'Item Created', 'ZurmoModule', 'Note', 's:42:"Contract additions. Special section notes.";'),
(440, 12, 1, '2013-06-25 12:30:36', 'Item Created', 'ZurmoModule', 'Note', 's:42:"Contract additions. Special section notes.";'),
(441, 13, 1, '2013-06-25 12:30:36', 'Item Created', 'ZurmoModule', 'Note', 's:42:"Contract additions. Special section notes.";'),
(442, 14, 1, '2013-06-25 12:30:36', 'Item Created', 'ZurmoModule', 'Note', 's:39:"System integration - jumpstart proposal";'),
(443, 15, 1, '2013-06-25 12:30:36', 'Item Created', 'ZurmoModule', 'Note', 's:42:"Contract additions. Special section notes.";'),
(444, 16, 1, '2013-06-25 12:30:37', 'Item Created', 'ZurmoModule', 'Note', 's:42:"Contract additions. Special section notes.";'),
(445, 17, 1, '2013-06-25 12:30:37', 'Item Created', 'ZurmoModule', 'Note', 's:28:"E-mail: Re: Product changes.";'),
(446, 18, 1, '2013-06-25 12:30:37', 'Item Created', 'ZurmoModule', 'Note', 's:42:"Contract additions. Special section notes.";'),
(447, 19, 1, '2013-06-25 12:30:37', 'Item Created', 'ZurmoModule', 'Note', 's:42:"Contract additions. Special section notes.";'),
(448, 2, 1, '2013-06-25 12:30:37', 'Item Created', 'ZurmoModule', 'SavedReport', 's:16:"New Leads Report";'),
(449, 3, 1, '2013-06-25 12:30:37', 'Item Created', 'ZurmoModule', 'SavedReport', 's:26:"Active Customer Email List";'),
(450, 4, 1, '2013-06-25 12:30:37', 'Item Created', 'ZurmoModule', 'SavedReport', 's:22:"Opportunities By Owner";'),
(451, 5, 1, '2013-06-25 12:30:37', 'Item Created', 'ZurmoModule', 'SavedReport', 's:33:"Closed won opportunities by month";'),
(452, 6, 1, '2013-06-25 12:30:37', 'Item Created', 'ZurmoModule', 'SavedReport', 's:22:"Opportunities by Stage";'),
(453, 2, 1, '2013-06-25 12:30:37', 'Item Created', 'ZurmoModule', 'ProductCatalog', 's:7:"Default";'),
(454, 2, 1, '2013-06-25 12:30:37', 'Item Created', 'ZurmoModule', 'ProductCategory', 's:6:"CD-DVD";'),
(455, 3, 1, '2013-06-25 12:30:37', 'Item Created', 'ZurmoModule', 'ProductCategory', 's:5:"Books";'),
(456, 4, 1, '2013-06-25 12:30:38', 'Item Created', 'ZurmoModule', 'ProductCategory', 's:5:"Music";'),
(457, 5, 1, '2013-06-25 12:30:38', 'Item Created', 'ZurmoModule', 'ProductCategory', 's:7:"Laptops";'),
(458, 6, 1, '2013-06-25 12:30:38', 'Item Created', 'ZurmoModule', 'ProductCategory', 's:6:"Camera";'),
(459, 7, 1, '2013-06-25 12:30:38', 'Item Created', 'ZurmoModule', 'ProductCategory', 's:8:"Handycam";'),
(460, 2, 1, '2013-06-25 12:30:38', 'Item Created', 'ZurmoModule', 'ProductTemplate', 's:11:"Amazing Kid";'),
(461, 3, 1, '2013-06-25 12:30:38', 'Item Created', 'ZurmoModule', 'ProductTemplate', 's:19:"You Can Do Anything";'),
(462, 4, 1, '2013-06-25 12:30:38', 'Item Created', 'ZurmoModule', 'ProductTemplate', 's:19:"A Bend in the River";'),
(463, 5, 1, '2013-06-25 12:30:38', 'Item Created', 'ZurmoModule', 'ProductTemplate', 's:21:"A Gift of Monotheists";'),
(464, 6, 1, '2013-06-25 12:30:38', 'Item Created', 'ZurmoModule', 'ProductTemplate', 's:18:"Once in a Lifetime";'),
(465, 7, 1, '2013-06-25 12:30:38', 'Item Created', 'ZurmoModule', 'ProductTemplate', 's:25:"Laptop Inc - Model LsntjG";'),
(466, 8, 1, '2013-06-25 12:30:38', 'Item Created', 'ZurmoModule', 'ProductTemplate', 's:25:"Laptop Inc - Model Ps9gyD";'),
(467, 9, 1, '2013-06-25 12:30:38', 'Item Created', 'ZurmoModule', 'ProductTemplate', 's:25:"Laptop Inc - Model nYmDt9";'),
(468, 10, 1, '2013-06-25 12:30:38', 'Item Created', 'ZurmoModule', 'ProductTemplate', 's:25:"Laptop Inc - Model eOKsFD";'),
(469, 11, 1, '2013-06-25 12:30:38', 'Item Created', 'ZurmoModule', 'ProductTemplate', 's:25:"Laptop Inc - Model btOJRS";'),
(470, 12, 1, '2013-06-25 12:30:38', 'Item Created', 'ZurmoModule', 'ProductTemplate', 's:25:"Laptop Inc - Model kr1JfZ";'),
(471, 13, 1, '2013-06-25 12:30:38', 'Item Created', 'ZurmoModule', 'ProductTemplate', 's:25:"Laptop Inc - Model ktRhOn";'),
(472, 14, 1, '2013-06-25 12:30:38', 'Item Created', 'ZurmoModule', 'ProductTemplate', 's:25:"Laptop Inc - Model xAwe35";'),
(473, 15, 1, '2013-06-25 12:30:38', 'Item Created', 'ZurmoModule', 'ProductTemplate', 's:25:"Laptop Inc - Model JcXZwA";'),
(474, 16, 1, '2013-06-25 12:30:38', 'Item Created', 'ZurmoModule', 'ProductTemplate', 's:37:"Camera Inc 2 MegaPixel - Model RIHmYF";'),
(475, 17, 1, '2013-06-25 12:30:38', 'Item Created', 'ZurmoModule', 'ProductTemplate', 's:37:"Camera Inc 2 MegaPixel - Model M9JqrI";'),
(476, 18, 1, '2013-06-25 12:30:38', 'Item Created', 'ZurmoModule', 'ProductTemplate', 's:37:"Camera Inc 2 MegaPixel - Model R9FmDg";'),
(477, 19, 1, '2013-06-25 12:30:38', 'Item Created', 'ZurmoModule', 'ProductTemplate', 's:37:"Camera Inc 2 MegaPixel - Model dKJCNi";'),
(478, 20, 1, '2013-06-25 12:30:38', 'Item Created', 'ZurmoModule', 'ProductTemplate', 's:37:"Camera Inc 2 MegaPixel - Model jxQeLq";'),
(479, 21, 1, '2013-06-25 12:30:38', 'Item Created', 'ZurmoModule', 'ProductTemplate', 's:37:"Camera Inc 2 MegaPixel - Model l4wupF";'),
(480, 22, 1, '2013-06-25 12:30:38', 'Item Created', 'ZurmoModule', 'ProductTemplate', 's:37:"Camera Inc 2 MegaPixel - Model 6IfjV3";'),
(481, 23, 1, '2013-06-25 12:30:38', 'Item Created', 'ZurmoModule', 'ProductTemplate', 's:37:"Camera Inc 2 MegaPixel - Model JCZFLB";'),
(482, 24, 1, '2013-06-25 12:30:39', 'Item Created', 'ZurmoModule', 'ProductTemplate', 's:37:"Camera Inc 2 MegaPixel - Model u0ziKO";'),
(483, 25, 1, '2013-06-25 12:30:39', 'Item Created', 'ZurmoModule', 'ProductTemplate', 's:27:"Handycam Inc - Model DrUPcM";'),
(484, 26, 1, '2013-06-25 12:30:39', 'Item Created', 'ZurmoModule', 'ProductTemplate', 's:27:"Handycam Inc - Model D4I5CU";'),
(485, 27, 1, '2013-06-25 12:30:39', 'Item Created', 'ZurmoModule', 'ProductTemplate', 's:27:"Handycam Inc - Model jMStmA";'),
(486, 28, 1, '2013-06-25 12:30:39', 'Item Created', 'ZurmoModule', 'ProductTemplate', 's:27:"Handycam Inc - Model nErS4b";'),
(487, 29, 1, '2013-06-25 12:30:39', 'Item Created', 'ZurmoModule', 'ProductTemplate', 's:27:"Handycam Inc - Model N5WdJi";'),
(488, 30, 1, '2013-06-25 12:30:39', 'Item Created', 'ZurmoModule', 'ProductTemplate', 's:27:"Handycam Inc - Model lCfm76";'),
(489, 31, 1, '2013-06-25 12:30:39', 'Item Created', 'ZurmoModule', 'ProductTemplate', 's:27:"Handycam Inc - Model 68e3Ms";'),
(490, 32, 1, '2013-06-25 12:30:39', 'Item Created', 'ZurmoModule', 'ProductTemplate', 's:27:"Handycam Inc - Model jIo9N7";'),
(491, 33, 1, '2013-06-25 12:30:39', 'Item Created', 'ZurmoModule', 'ProductTemplate', 's:27:"Handycam Inc - Model Pn1TQx";'),
(492, 2, 1, '2013-06-25 12:30:39', 'Item Created', 'ZurmoModule', 'Product', 's:18:"Amazing Kid Sample";'),
(493, 3, 1, '2013-06-25 12:30:39', 'Item Created', 'ZurmoModule', 'Product', 's:26:"You Can Do Anything Sample";'),
(494, 4, 1, '2013-06-25 12:30:39', 'Item Created', 'ZurmoModule', 'Product', 's:34:"A Bend in the River November Issue";'),
(495, 5, 1, '2013-06-25 12:30:39', 'Item Created', 'ZurmoModule', 'Product', 's:35:"A Gift of Monotheists October Issue";'),
(496, 6, 1, '2013-06-25 12:30:39', 'Item Created', 'ZurmoModule', 'Product', 's:30:"Enjoy Once in a Lifetime Music";'),
(497, 7, 1, '2013-06-25 12:30:40', 'Item Created', 'ZurmoModule', 'Product', 's:29:"Laptop Inc - Model LsntjG-PFp";'),
(498, 8, 1, '2013-06-25 12:30:40', 'Item Created', 'ZurmoModule', 'Product', 's:29:"Laptop Inc - Model LsntjG-PQs";'),
(499, 9, 1, '2013-06-25 12:30:40', 'Item Created', 'ZurmoModule', 'Product', 's:29:"Laptop Inc - Model Ps9gyD-PdD";'),
(500, 10, 1, '2013-06-25 12:30:40', 'Item Created', 'ZurmoModule', 'Product', 's:29:"Laptop Inc - Model Ps9gyD-P1f";'),
(501, 11, 1, '2013-06-25 12:30:40', 'Item Created', 'ZurmoModule', 'Product', 's:29:"Laptop Inc - Model nYmDt9-PTc";'),
(502, 12, 1, '2013-06-25 12:30:40', 'Item Created', 'ZurmoModule', 'Product', 's:29:"Laptop Inc - Model nYmDt9-PhS";'),
(503, 13, 1, '2013-06-25 12:30:40', 'Item Created', 'ZurmoModule', 'Product', 's:29:"Laptop Inc - Model eOKsFD-P1S";'),
(504, 14, 1, '2013-06-25 12:30:40', 'Item Created', 'ZurmoModule', 'Product', 's:29:"Laptop Inc - Model eOKsFD-Pfq";'),
(505, 15, 1, '2013-06-25 12:30:40', 'Item Created', 'ZurmoModule', 'Product', 's:29:"Laptop Inc - Model btOJRS-PPp";'),
(506, 16, 1, '2013-06-25 12:30:41', 'Item Created', 'ZurmoModule', 'Product', 's:29:"Laptop Inc - Model btOJRS-PUm";'),
(507, 17, 1, '2013-06-25 12:30:41', 'Item Created', 'ZurmoModule', 'Product', 's:29:"Laptop Inc - Model kr1JfZ-PV3";'),
(508, 18, 1, '2013-06-25 12:30:41', 'Item Created', 'ZurmoModule', 'Product', 's:29:"Laptop Inc - Model kr1JfZ-Pyg";'),
(509, 19, 1, '2013-06-25 12:30:41', 'Item Created', 'ZurmoModule', 'Product', 's:29:"Laptop Inc - Model ktRhOn-PDw";'),
(510, 20, 1, '2013-06-25 12:30:41', 'Item Created', 'ZurmoModule', 'Product', 's:29:"Laptop Inc - Model ktRhOn-PBT";'),
(511, 21, 1, '2013-06-25 12:30:41', 'Item Created', 'ZurmoModule', 'Product', 's:29:"Laptop Inc - Model xAwe35-Pk0";'),
(512, 22, 1, '2013-06-25 12:30:41', 'Item Created', 'ZurmoModule', 'Product', 's:29:"Laptop Inc - Model xAwe35-Pwp";'),
(513, 23, 1, '2013-06-25 12:30:41', 'Item Created', 'ZurmoModule', 'Product', 's:29:"Laptop Inc - Model JcXZwA-PF2";'),
(514, 24, 1, '2013-06-25 12:30:41', 'Item Created', 'ZurmoModule', 'Product', 's:29:"Laptop Inc - Model JcXZwA-PW5";'),
(515, 25, 1, '2013-06-25 12:30:42', 'Item Created', 'ZurmoModule', 'Product', 's:41:"Camera Inc 2 MegaPixel - Model RIHmYF-PxS";'),
(516, 26, 1, '2013-06-25 12:30:42', 'Item Created', 'ZurmoModule', 'Product', 's:41:"Camera Inc 2 MegaPixel - Model RIHmYF-PI2";'),
(517, 27, 1, '2013-06-25 12:30:42', 'Item Created', 'ZurmoModule', 'Product', 's:41:"Camera Inc 2 MegaPixel - Model M9JqrI-Pkl";'),
(518, 28, 1, '2013-06-25 12:30:42', 'Item Created', 'ZurmoModule', 'Product', 's:41:"Camera Inc 2 MegaPixel - Model M9JqrI-P3O";'),
(519, 29, 1, '2013-06-25 12:30:42', 'Item Created', 'ZurmoModule', 'Product', 's:41:"Camera Inc 2 MegaPixel - Model R9FmDg-PrE";'),
(520, 30, 1, '2013-06-25 12:30:42', 'Item Created', 'ZurmoModule', 'Product', 's:41:"Camera Inc 2 MegaPixel - Model R9FmDg-P3M";'),
(521, 31, 1, '2013-06-25 12:30:42', 'Item Created', 'ZurmoModule', 'Product', 's:41:"Camera Inc 2 MegaPixel - Model dKJCNi-Ppx";'),
(522, 32, 1, '2013-06-25 12:30:42', 'Item Created', 'ZurmoModule', 'Product', 's:41:"Camera Inc 2 MegaPixel - Model dKJCNi-PWO";'),
(523, 33, 1, '2013-06-25 12:30:42', 'Item Created', 'ZurmoModule', 'Product', 's:41:"Camera Inc 2 MegaPixel - Model jxQeLq-P97";'),
(524, 34, 1, '2013-06-25 12:30:42', 'Item Created', 'ZurmoModule', 'Product', 's:41:"Camera Inc 2 MegaPixel - Model jxQeLq-PTM";'),
(525, 35, 1, '2013-06-25 12:30:43', 'Item Created', 'ZurmoModule', 'Product', 's:41:"Camera Inc 2 MegaPixel - Model l4wupF-Pjv";'),
(526, 36, 1, '2013-06-25 12:30:43', 'Item Created', 'ZurmoModule', 'Product', 's:41:"Camera Inc 2 MegaPixel - Model l4wupF-PoW";'),
(527, 37, 1, '2013-06-25 12:30:43', 'Item Created', 'ZurmoModule', 'Product', 's:41:"Camera Inc 2 MegaPixel - Model 6IfjV3-Pm7";'),
(528, 38, 1, '2013-06-25 12:30:43', 'Item Created', 'ZurmoModule', 'Product', 's:41:"Camera Inc 2 MegaPixel - Model 6IfjV3-PY3";'),
(529, 39, 1, '2013-06-25 12:30:43', 'Item Created', 'ZurmoModule', 'Product', 's:41:"Camera Inc 2 MegaPixel - Model JCZFLB-POf";'),
(530, 40, 1, '2013-06-25 12:30:43', 'Item Created', 'ZurmoModule', 'Product', 's:41:"Camera Inc 2 MegaPixel - Model JCZFLB-PQu";'),
(531, 41, 1, '2013-06-25 12:30:43', 'Item Created', 'ZurmoModule', 'Product', 's:41:"Camera Inc 2 MegaPixel - Model u0ziKO-PI4";'),
(532, 42, 1, '2013-06-25 12:30:43', 'Item Created', 'ZurmoModule', 'Product', 's:41:"Camera Inc 2 MegaPixel - Model u0ziKO-PNn";'),
(533, 43, 1, '2013-06-25 12:30:43', 'Item Created', 'ZurmoModule', 'Product', 's:31:"Handycam Inc - Model DrUPcM-PmS";'),
(534, 44, 1, '2013-06-25 12:30:44', 'Item Created', 'ZurmoModule', 'Product', 's:31:"Handycam Inc - Model DrUPcM-PXO";'),
(535, 45, 1, '2013-06-25 12:30:44', 'Item Created', 'ZurmoModule', 'Product', 's:31:"Handycam Inc - Model D4I5CU-PdE";'),
(536, 46, 1, '2013-06-25 12:30:44', 'Item Created', 'ZurmoModule', 'Product', 's:31:"Handycam Inc - Model D4I5CU-P7m";'),
(537, 47, 1, '2013-06-25 12:30:44', 'Item Created', 'ZurmoModule', 'Product', 's:31:"Handycam Inc - Model jMStmA-P0y";'),
(538, 48, 1, '2013-06-25 12:30:44', 'Item Created', 'ZurmoModule', 'Product', 's:31:"Handycam Inc - Model jMStmA-PbJ";');
INSERT INTO `auditevent` (`id`, `modelid`, `_user_id`, `datetime`, `eventname`, `modulename`, `modelclassname`, `serializeddata`) VALUES
(539, 49, 1, '2013-06-25 12:30:44', 'Item Created', 'ZurmoModule', 'Product', 's:31:"Handycam Inc - Model nErS4b-P8u";'),
(540, 50, 1, '2013-06-25 12:30:44', 'Item Created', 'ZurmoModule', 'Product', 's:31:"Handycam Inc - Model nErS4b-PtP";'),
(541, 51, 1, '2013-06-25 12:30:44', 'Item Created', 'ZurmoModule', 'Product', 's:31:"Handycam Inc - Model N5WdJi-PZQ";'),
(542, 52, 1, '2013-06-25 12:30:44', 'Item Created', 'ZurmoModule', 'Product', 's:31:"Handycam Inc - Model N5WdJi-Pyl";'),
(543, 53, 1, '2013-06-25 12:30:45', 'Item Created', 'ZurmoModule', 'Product', 's:31:"Handycam Inc - Model lCfm76-PWB";'),
(544, 54, 1, '2013-06-25 12:30:45', 'Item Created', 'ZurmoModule', 'Product', 's:31:"Handycam Inc - Model lCfm76-PgK";'),
(545, 55, 1, '2013-06-25 12:30:45', 'Item Created', 'ZurmoModule', 'Product', 's:31:"Handycam Inc - Model 68e3Ms-PWH";'),
(546, 56, 1, '2013-06-25 12:30:45', 'Item Created', 'ZurmoModule', 'Product', 's:31:"Handycam Inc - Model 68e3Ms-Pph";'),
(547, 57, 1, '2013-06-25 12:30:45', 'Item Created', 'ZurmoModule', 'Product', 's:31:"Handycam Inc - Model jIo9N7-PZG";'),
(548, 58, 1, '2013-06-25 12:30:45', 'Item Created', 'ZurmoModule', 'Product', 's:31:"Handycam Inc - Model jIo9N7-PaW";'),
(549, 59, 1, '2013-06-25 12:30:45', 'Item Created', 'ZurmoModule', 'Product', 's:31:"Handycam Inc - Model Pn1TQx-Pmj";'),
(550, 60, 1, '2013-06-25 12:30:45', 'Item Created', 'ZurmoModule', 'Product', 's:31:"Handycam Inc - Model Pn1TQx-Pew";'),
(551, 2, 1, '2013-06-25 12:30:45', 'Item Created', 'ZurmoModule', 'SocialItem', 's:57:"Game on! I received a new badge: 5 opportunities searched";'),
(552, 3, 1, '2013-06-25 12:30:45', 'Item Created', 'ZurmoModule', 'SocialItem', 's:59:"Anyone interested in going to San Diego for the trade show?";'),
(553, 4, 1, '2013-06-25 12:30:45', 'Item Created', 'ZurmoModule', 'SocialItem', 's:52:"Game on! I received a new badge: 15 accounts created";'),
(554, 26, 1, '2013-06-25 12:30:45', 'Item Created', 'ZurmoModule', 'Comment', 's:17:"Dude, get to work";'),
(555, 27, 1, '2013-06-25 12:30:45', 'Item Created', 'ZurmoModule', 'Comment', 's:19:"Lets get some beers";'),
(556, 5, 1, '2013-06-25 12:30:45', 'Item Created', 'ZurmoModule', 'SocialItem', 's:15:"I love fridays!";'),
(557, 28, 1, '2013-06-25 12:30:46', 'Item Created', 'ZurmoModule', 'Comment', 's:23:"I wish i was in sales..";'),
(558, 29, 1, '2013-06-25 12:30:46', 'Item Created', 'ZurmoModule', 'Comment', 's:63:"Dude, IT just twiddles their thumbs most of the time anyways :)";'),
(559, 30, 1, '2013-06-25 12:30:46', 'Item Created', 'ZurmoModule', 'Comment', 's:15:"Yeah whatever..";'),
(560, 31, 1, '2013-06-25 12:30:46', 'Item Created', 'ZurmoModule', 'Comment', 's:56:"I am in for golf, primarly drinking and riding the cart.";'),
(561, 6, 1, '2013-06-25 12:30:46', 'Item Created', 'ZurmoModule', 'SocialItem', 's:9:"Golf time";'),
(562, 20, 1, '2013-06-25 12:30:46', 'Item Created', 'ZurmoModule', 'Note', 's:27:"This account is heating up!";'),
(563, 32, 1, '2013-06-25 12:30:46', 'Item Created', 'ZurmoModule', 'Comment', 's:45:"I would love us to get this guy as a customer";'),
(564, 33, 1, '2013-06-25 12:30:46', 'Item Created', 'ZurmoModule', 'Comment', 's:14:"I second that.";'),
(565, 34, 1, '2013-06-25 12:30:46', 'Item Created', 'ZurmoModule', 'Comment', 's:30:"Would be an amazing case study";'),
(566, 7, 1, '2013-06-25 12:30:46', 'Item Created', 'ZurmoModule', 'SocialItem', 's:9:"(Unnamed)";'),
(567, 8, 1, '2013-06-25 12:30:46', 'Item Created', 'ZurmoModule', 'SocialItem', 's:26:"Game on! I reached level 4";'),
(568, 9, 1, '2013-06-25 12:30:46', 'Item Created', 'ZurmoModule', 'SocialItem', 's:59:"Game on! I received a new badge: Logged in 5 times at night";'),
(569, 10, 1, '2013-06-25 12:30:46', 'Item Created', 'ZurmoModule', 'SocialItem', 's:26:"Just stubbed my toe. Ouch!";'),
(570, 11, 1, '2013-06-25 12:30:46', 'Item Created', 'ZurmoModule', 'SocialItem', 's:50:"Game on! I received a new badge: For being awesome";'),
(571, 12, 1, '2013-06-25 12:30:46', 'Item Created', 'ZurmoModule', 'SocialItem', 's:65:"Ask Barry why we can''t use our cell phones in the conference room";'),
(572, 13, 1, '2013-06-25 12:30:46', 'Item Created', 'ZurmoModule', 'SocialItem', 's:26:"Game on! I reached level 2";'),
(573, 35, 1, '2013-06-25 12:30:46', 'Item Created', 'ZurmoModule', 'Comment', 's:22:"How about at a museum?";'),
(574, 36, 1, '2013-06-25 12:30:46', 'Item Created', 'ZurmoModule', 'Comment', 's:48:"I am going to be out of town, so I can''t attend.";'),
(575, 37, 1, '2013-06-25 12:30:46', 'Item Created', 'ZurmoModule', 'Comment', 's:27:"I guess i can take this on.";'),
(576, 14, 1, '2013-06-25 12:30:46', 'Item Created', 'ZurmoModule', 'SocialItem', 's:41:"Where should we have the Christmas party?";'),
(577, 21, 1, '2013-06-25 12:30:46', 'Item Created', 'ZurmoModule', 'Note', 's:50:"Why is this customer having so many problems. Sigh";'),
(578, 38, 1, '2013-06-25 12:30:46', 'Item Created', 'ZurmoModule', 'Comment', 's:45:"Did you contact Sarah in client services yet?";'),
(579, 39, 1, '2013-06-25 12:30:46', 'Item Created', 'ZurmoModule', 'Comment', 's:28:"That is probably a good idea";'),
(580, 40, 1, '2013-06-25 12:30:46', 'Item Created', 'ZurmoModule', 'Comment', 's:34:"Only if sarah is having a good day";'),
(581, 15, 1, '2013-06-25 12:30:46', 'Item Created', 'ZurmoModule', 'SocialItem', 's:9:"(Unnamed)";'),
(582, 22, 1, '2013-06-25 12:30:46', 'Item Created', 'ZurmoModule', 'Note', 's:25:"Bam. Closed another deal!";'),
(583, 41, 1, '2013-06-25 12:30:46', 'Item Created', 'ZurmoModule', 'Comment', 's:8:"Awesome!";'),
(584, 42, 1, '2013-06-25 12:30:46', 'Item Created', 'ZurmoModule', 'Comment', 's:14:"I second that.";'),
(585, 43, 1, '2013-06-25 12:30:46', 'Item Created', 'ZurmoModule', 'Comment', 's:29:"You are buying drinks tonight";'),
(586, 16, 1, '2013-06-25 12:30:46', 'Item Created', 'ZurmoModule', 'SocialItem', 's:9:"(Unnamed)";'),
(587, 17, 1, '2013-06-25 12:30:46', 'Item Created', 'ZurmoModule', 'SocialItem', 's:26:"Game on! I reached level 3";'),
(588, 18, 1, '2013-06-25 12:30:47', 'Item Created', 'ZurmoModule', 'SocialItem', 's:26:"Game on! I reached level 5";'),
(589, 2, 1, '2013-06-25 12:30:47', 'Item Created', 'ZurmoModule', 'Task', 's:20:"Send follow up email";'),
(590, 3, 1, '2013-06-25 12:30:47', 'Item Created', 'ZurmoModule', 'Task', 's:20:"Send product catalog";'),
(591, 4, 1, '2013-06-25 12:30:47', 'Item Created', 'ZurmoModule', 'Task', 's:22:"Follow up with renewal";'),
(592, 5, 1, '2013-06-25 12:30:47', 'Item Created', 'ZurmoModule', 'Task', 's:20:"Send product catalog";'),
(593, 6, 1, '2013-06-25 12:30:47', 'Item Created', 'ZurmoModule', 'Task', 's:9:"Follow Up";'),
(594, 7, 1, '2013-06-25 12:30:47', 'Item Created', 'ZurmoModule', 'Task', 's:15:"Make a proposal";'),
(595, 8, 1, '2013-06-25 12:30:47', 'Item Created', 'ZurmoModule', 'Task', 's:20:"Send follow up email";'),
(596, 9, 1, '2013-06-25 12:30:47', 'Item Created', 'ZurmoModule', 'Task', 's:15:"Make a proposal";'),
(597, 10, 1, '2013-06-25 12:30:47', 'Item Created', 'ZurmoModule', 'Task', 's:15:"Build prototype";'),
(598, 11, 1, '2013-06-25 12:30:47', 'Item Created', 'ZurmoModule', 'Task', 's:28:"Document changes to proposal";'),
(599, 12, 1, '2013-06-25 12:30:47', 'Item Created', 'ZurmoModule', 'Task', 's:25:"Research position changes";'),
(600, 13, 1, '2013-06-25 12:30:47', 'Item Created', 'ZurmoModule', 'Task', 's:15:"Make a proposal";'),
(601, 14, 1, '2013-06-25 12:30:47', 'Item Created', 'ZurmoModule', 'Task', 's:26:"Review contract with legal";'),
(602, 15, 1, '2013-06-25 12:30:47', 'Item Created', 'ZurmoModule', 'Task', 's:15:"Make a proposal";'),
(603, 16, 1, '2013-06-25 12:30:47', 'Item Created', 'ZurmoModule', 'Task', 's:20:"Send follow up email";'),
(604, 17, 1, '2013-06-25 12:30:47', 'Item Created', 'ZurmoModule', 'Task', 's:20:"Send follow up email";'),
(605, 18, 1, '2013-06-25 12:30:47', 'Item Created', 'ZurmoModule', 'Task', 's:25:"Research position changes";'),
(606, 19, 1, '2013-06-25 12:30:47', 'Item Created', 'ZurmoModule', 'Task', 's:25:"Research position changes";'),
(607, 2, 1, '2013-06-25 12:30:47', 'Item Created', 'ZurmoModule', 'ContactWebForm', 's:18:"Corporate Web Form";'),
(608, 3, 1, '2013-06-25 12:30:48', 'Item Created', 'ZurmoModule', 'ContactWebForm', 's:21:"Sales Portal Web Form";'),
(609, 4, 1, '2013-06-25 12:30:48', 'Item Created', 'ZurmoModule', 'ContactWebForm', 's:23:"Clients Portal Web Form";'),
(610, 5, 1, '2013-06-25 12:30:48', 'Item Created', 'ZurmoModule', 'ContactWebForm', 's:32:"Customer Support Portal Web Form";'),
(611, 6, 1, '2013-06-25 12:30:48', 'Item Created', 'ZurmoModule', 'ContactWebForm', 's:19:"Sales Team Web Form";'),
(612, 26, 1, '2013-06-25 12:30:48', 'Item Created', 'ZurmoModule', 'Contact', 's:11:"Alice Brown";'),
(613, 2, 1, '2013-06-25 12:30:48', 'Item Created', 'ZurmoModule', 'ContactWebFormEntry', 's:6:"(None)";'),
(614, 27, 1, '2013-06-25 12:30:48', 'Item Created', 'ZurmoModule', 'Contact', 's:9:"Jim Smith";'),
(615, 3, 1, '2013-06-25 12:30:48', 'Item Created', 'ZurmoModule', 'ContactWebFormEntry', 's:6:"(None)";'),
(616, 4, 1, '2013-06-25 12:30:48', 'Item Created', 'ZurmoModule', 'ContactWebFormEntry', 's:6:"(None)";'),
(617, 28, 1, '2013-06-25 12:30:48', 'Item Created', 'ZurmoModule', 'Contact', 's:12:"Keith Cooper";'),
(618, 5, 1, '2013-06-25 12:30:49', 'Item Created', 'ZurmoModule', 'ContactWebFormEntry', 's:6:"(None)";'),
(619, 29, 1, '2013-06-25 12:30:49', 'Item Created', 'ZurmoModule', 'Contact', 's:9:"Sarah Lee";'),
(620, 6, 1, '2013-06-25 12:30:49', 'Item Created', 'ZurmoModule', 'ContactWebFormEntry', 's:6:"(None)";'),
(621, 8, 1, '2016-01-04 16:06:37', 'Item Created', 'ZurmoModule', 'EmailTemplate', 's:5:"Blank";'),
(622, 9, 1, '2016-01-04 16:06:37', 'Item Created', 'ZurmoModule', 'EmailTemplate', 's:8:"1 Column";'),
(623, 10, 1, '2016-01-04 16:06:37', 'Item Created', 'ZurmoModule', 'EmailTemplate', 's:9:"2 Columns";'),
(624, 11, 1, '2016-01-04 16:06:37', 'Item Created', 'ZurmoModule', 'EmailTemplate', 's:27:"2 Columns with strong right";'),
(625, 12, 1, '2016-01-04 16:06:37', 'Item Created', 'ZurmoModule', 'EmailTemplate', 's:9:"3 Columns";'),
(626, 13, 1, '2016-01-04 16:06:37', 'Item Created', 'ZurmoModule', 'EmailTemplate', 's:19:"3 Columns with Hero";'),
(627, 1, 1, '2016-01-04 16:06:40', 'User Password Changed', 'UsersModule', 'User', 's:5:"super";'),
(628, 3, 1, '2016-01-04 16:06:41', 'User Password Changed', 'UsersModule', 'User', 's:5:"admin";'),
(629, 4, 1, '2016-01-04 16:06:41', 'User Password Changed', 'UsersModule', 'User', 's:3:"jim";'),
(630, 5, 1, '2016-01-04 16:06:41', 'User Password Changed', 'UsersModule', 'User', 's:4:"john";'),
(631, 6, 1, '2016-01-04 16:06:42', 'User Password Changed', 'UsersModule', 'User', 's:5:"sally";'),
(632, 7, 1, '2016-01-04 16:06:42', 'User Password Changed', 'UsersModule', 'User', 's:4:"mary";'),
(633, 8, 1, '2016-01-04 16:06:43', 'User Password Changed', 'UsersModule', 'User', 's:5:"katie";'),
(634, 9, 1, '2016-01-04 16:06:43', 'User Password Changed', 'UsersModule', 'User', 's:4:"jill";'),
(635, 10, 1, '2016-01-04 16:06:43', 'User Password Changed', 'UsersModule', 'User', 's:3:"sam";'),
(636, 3, 1, '2016-01-04 16:06:51', 'Item Created', 'ZurmoModule', 'NotificationMessage', 's:6:"(None)";'),
(637, 3, 1, '2016-01-04 16:06:51', 'Item Created', 'ZurmoModule', 'Notification', 's:44:"Clear the assets folder on server(optional).";'),
(638, NULL, 1, '2016-01-04 16:08:45', 'User Logged In', 'UsersModule', NULL, 'N;'),
(639, NULL, 1, '2016-01-04 16:26:58', 'User Logged In', 'UsersModule', NULL, 'N;'),
(640, NULL, 1, '2016-01-04 16:40:10', 'User Logged Out', 'UsersModule', NULL, 'N;'),
(641, NULL, 1, '2016-01-04 16:40:43', 'User Logged Out', 'UsersModule', NULL, 'N;'),
(642, NULL, 1, '2016-01-04 16:59:11', 'User Logged In', 'UsersModule', NULL, 'N;'),
(643, NULL, 1, '2016-01-05 05:58:32', 'User Logged In', 'UsersModule', NULL, 'N;'),
(644, 20, 1, '2016-01-05 05:58:33', 'Item Created', 'ZurmoModule', 'GameScore', 's:8:"NightOwl";'),
(645, 20, 1, '2016-01-05 05:58:36', 'Item Created', 'ZurmoModule', 'GameBadge', 's:10:"NightOwl 1";'),
(646, NULL, 1, '2016-01-05 10:29:35', 'User Logged In', 'UsersModule', NULL, 'N;'),
(647, 21, 1, '2016-01-05 10:29:36', 'Item Created', 'ZurmoModule', 'GameScore', 's:9:"EarlyBird";'),
(648, 21, 1, '2016-01-05 10:29:37', 'Item Created', 'ZurmoModule', 'GameBadge', 's:11:"EarlyBird 1";'),
(649, 11, 1, '2016-01-05 10:33:35', 'Item Created', 'ZurmoModule', 'User', 's:11:"System User";'),
(650, 11, 1, '2016-01-05 10:33:35', 'User Password Changed', 'UsersModule', 'User', 's:22:"backendjoboractionuser";'),
(651, 11, 1, '2016-01-05 10:33:35', 'Item Modified', 'ZurmoModule', 'User', 'a:4:{i:0;s:11:"System User";i:1;a:1:{i:0;s:8:"isActive";}i:2;s:5:"false";i:3;s:4:"true";}'),
(652, 11, 1, '2016-01-05 10:33:36', 'Item Modified', 'ZurmoModule', 'User', 'a:4:{i:0;s:11:"System User";i:1;a:1:{i:0;s:8:"isActive";}i:2;s:4:"true";i:3;s:5:"false";}'),
(653, 22, 1, '2016-01-05 10:33:39', 'Item Created', 'ZurmoModule', 'GameScore', 's:14:"CreateContract";'),
(654, 1, 1, '2016-01-05 10:33:39', 'Item Created', 'ZurmoModule', 'Contract', 's:4:"test";'),
(655, 20, 1, '2016-01-05 10:33:40', 'Item Created', 'ZurmoModule', 'GamePoint', 's:5:"Sales";'),
(656, 22, 1, '2016-01-05 10:33:40', 'Item Created', 'ZurmoModule', 'GameBadge', 's:16:"CreateContract 1";'),
(657, 2, 1, '2016-01-05 10:35:04', 'Item Created', 'ZurmoModule', 'Contract', 's:5:"test1";'),
(658, 23, 1, '2016-01-05 10:35:04', 'Item Created', 'ZurmoModule', 'GameScore', 's:14:"UpdateContract";'),
(659, 1, 1, '2016-01-05 10:35:05', 'Item Created', 'ZurmoModule', 'GameCoin', 's:7:"2 coins";'),
(660, 2, 1, '2016-01-05 10:35:05', 'Item Viewed', 'ZurmoModule', 'Contract', 'a:2:{i:0;s:5:"test1";i:1;s:15:"ContractsModule";}'),
(661, 3, 1, '2016-01-05 10:39:23', 'Item Created', 'ZurmoModule', 'Contract', 's:5:"werwr";'),
(662, 3, 1, '2016-01-05 10:39:23', 'Item Viewed', 'ZurmoModule', 'Contract', 'a:2:{i:0;s:5:"werwr";i:1;s:15:"ContractsModule";}'),
(663, 3, 1, '2016-01-05 10:44:26', 'Item Viewed', 'ZurmoModule', 'Contract', 'a:2:{i:0;s:5:"werwr";i:1;s:15:"ContractsModule";}'),
(664, 3, 1, '2016-01-05 10:44:56', 'Item Viewed', 'ZurmoModule', 'Contract', 'a:2:{i:0;s:5:"werwr";i:1;s:15:"ContractsModule";}'),
(665, 3, 1, '2016-01-05 10:48:58', 'Item Viewed', 'ZurmoModule', 'Contract', 'a:2:{i:0;s:5:"werwr";i:1;s:15:"ContractsModule";}'),
(666, 3, 1, '2016-01-05 10:52:52', 'Item Viewed', 'ZurmoModule', 'Contract', 'a:2:{i:0;s:5:"werwr";i:1;s:15:"ContractsModule";}'),
(667, 3, 1, '2016-01-05 10:54:51', 'Item Viewed', 'ZurmoModule', 'Contract', 'a:2:{i:0;s:5:"werwr";i:1;s:15:"ContractsModule";}'),
(668, 3, 1, '2016-01-05 10:56:07', 'Item Viewed', 'ZurmoModule', 'Contract', 'a:2:{i:0;s:5:"werwr";i:1;s:15:"ContractsModule";}'),
(669, 3, 1, '2016-01-05 10:57:44', 'Item Viewed', 'ZurmoModule', 'Contract', 'a:2:{i:0;s:5:"werwr";i:1;s:15:"ContractsModule";}'),
(670, 3, 1, '2016-01-05 10:58:25', 'Item Viewed', 'ZurmoModule', 'Contract', 'a:2:{i:0;s:5:"werwr";i:1;s:15:"ContractsModule";}'),
(671, 3, 1, '2016-01-05 11:01:09', 'Item Viewed', 'ZurmoModule', 'Contract', 'a:2:{i:0;s:5:"werwr";i:1;s:15:"ContractsModule";}'),
(672, 3, 1, '2016-01-05 11:02:56', 'Item Viewed', 'ZurmoModule', 'Contract', 'a:2:{i:0;s:5:"werwr";i:1;s:15:"ContractsModule";}'),
(673, 3, 1, '2016-01-05 11:03:15', 'Item Viewed', 'ZurmoModule', 'Contract', 'a:2:{i:0;s:5:"werwr";i:1;s:15:"ContractsModule";}'),
(674, 3, 1, '2016-01-05 11:03:56', 'Item Viewed', 'ZurmoModule', 'Contract', 'a:2:{i:0;s:5:"werwr";i:1;s:15:"ContractsModule";}'),
(675, 3, 1, '2016-01-05 11:04:05', 'Item Viewed', 'ZurmoModule', 'Contract', 'a:2:{i:0;s:5:"werwr";i:1;s:15:"ContractsModule";}'),
(676, 3, 1, '2016-01-05 11:04:07', 'Item Viewed', 'ZurmoModule', 'Contract', 'a:2:{i:0;s:5:"werwr";i:1;s:15:"ContractsModule";}'),
(677, 3, 1, '2016-01-05 11:04:08', 'Item Viewed', 'ZurmoModule', 'Contract', 'a:2:{i:0;s:5:"werwr";i:1;s:15:"ContractsModule";}'),
(678, 3, 1, '2016-01-05 11:04:17', 'Item Viewed', 'ZurmoModule', 'Contract', 'a:2:{i:0;s:5:"werwr";i:1;s:15:"ContractsModule";}'),
(679, 3, 1, '2016-01-05 11:04:59', 'Item Viewed', 'ZurmoModule', 'Contract', 'a:2:{i:0;s:5:"werwr";i:1;s:15:"ContractsModule";}'),
(680, 3, 1, '2016-01-05 11:05:40', 'Item Viewed', 'ZurmoModule', 'Contract', 'a:2:{i:0;s:5:"werwr";i:1;s:15:"ContractsModule";}'),
(681, 3, 1, '2016-01-05 11:05:58', 'Item Viewed', 'ZurmoModule', 'Contract', 'a:2:{i:0;s:5:"werwr";i:1;s:15:"ContractsModule";}'),
(682, 3, 1, '2016-01-05 11:08:58', 'Item Viewed', 'ZurmoModule', 'Contract', 'a:2:{i:0;s:5:"werwr";i:1;s:15:"ContractsModule";}'),
(683, 3, 1, '2016-01-05 11:09:22', 'Item Viewed', 'ZurmoModule', 'Contract', 'a:2:{i:0;s:5:"werwr";i:1;s:15:"ContractsModule";}'),
(684, 4, 1, '2016-01-05 11:11:02', 'Item Created', 'ZurmoModule', 'Contract', 's:5:"ewrwr";'),
(685, 4, 1, '2016-01-05 11:11:03', 'Item Viewed', 'ZurmoModule', 'Contract', 'a:2:{i:0;s:5:"ewrwr";i:1;s:15:"ContractsModule";}'),
(686, 4, 1, '2016-01-05 11:11:48', 'Item Viewed', 'ZurmoModule', 'Contract', 'a:2:{i:0;s:5:"ewrwr";i:1;s:15:"ContractsModule";}'),
(687, 4, 1, '2016-01-05 11:16:02', 'Item Viewed', 'ZurmoModule', 'Contract', 'a:2:{i:0;s:5:"ewrwr";i:1;s:15:"ContractsModule";}'),
(688, 4, 1, '2016-01-05 11:16:04', 'Item Viewed', 'ZurmoModule', 'Contract', 'a:2:{i:0;s:5:"ewrwr";i:1;s:15:"ContractsModule";}'),
(689, 2, 1, '2016-01-05 11:16:51', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:17:"Training Services";i:1;s:19:"OpportunitiesModule";}'),
(690, 4, 1, '2016-01-05 11:18:09', 'Item Viewed', 'ZurmoModule', 'Contract', 'a:2:{i:0;s:5:"ewrwr";i:1;s:15:"ContractsModule";}'),
(691, 4, 1, '2016-01-05 11:18:17', 'Item Viewed', 'ZurmoModule', 'Contract', 'a:2:{i:0;s:5:"ewrwr";i:1;s:15:"ContractsModule";}'),
(692, 4, 1, '2016-01-05 11:20:27', 'Item Viewed', 'ZurmoModule', 'Contract', 'a:2:{i:0;s:5:"ewrwr";i:1;s:15:"ContractsModule";}'),
(693, 4, 1, '2016-01-05 11:21:37', 'Item Viewed', 'ZurmoModule', 'Contract', 'a:2:{i:0;s:5:"ewrwr";i:1;s:15:"ContractsModule";}'),
(694, 4, 1, '2016-01-05 11:24:25', 'Item Viewed', 'ZurmoModule', 'Contract', 'a:2:{i:0;s:5:"ewrwr";i:1;s:15:"ContractsModule";}'),
(695, 4, 1, '2016-01-05 11:29:00', 'Item Viewed', 'ZurmoModule', 'Contract', 'a:2:{i:0;s:5:"ewrwr";i:1;s:15:"ContractsModule";}'),
(696, NULL, 1, '2016-01-05 12:25:55', 'User Logged In', 'UsersModule', NULL, 'N;'),
(697, 4, 1, '2016-01-05 12:25:55', 'Item Viewed', 'ZurmoModule', 'Contract', 'a:2:{i:0;s:5:"ewrwr";i:1;s:15:"ContractsModule";}'),
(698, 4, 1, '2016-01-05 12:26:01', 'Item Viewed', 'ZurmoModule', 'Contract', 'a:2:{i:0;s:5:"ewrwr";i:1;s:15:"ContractsModule";}'),
(699, 4, 1, '2016-01-05 12:26:18', 'Item Viewed', 'ZurmoModule', 'Contract', 'a:2:{i:0;s:5:"ewrwr";i:1;s:15:"ContractsModule";}'),
(700, 4, 1, '2016-01-05 12:26:59', 'Item Viewed', 'ZurmoModule', 'Contract', 'a:2:{i:0;s:5:"ewrwr";i:1;s:15:"ContractsModule";}'),
(701, 4, 1, '2016-01-05 12:27:55', 'Item Viewed', 'ZurmoModule', 'Contract', 'a:2:{i:0;s:5:"ewrwr";i:1;s:15:"ContractsModule";}'),
(702, 4, 1, '2016-01-05 12:28:04', 'Item Viewed', 'ZurmoModule', 'Contract', 'a:2:{i:0;s:5:"ewrwr";i:1;s:15:"ContractsModule";}'),
(703, 4, 1, '2016-01-05 12:29:33', 'Item Viewed', 'ZurmoModule', 'Contract', 'a:2:{i:0;s:5:"ewrwr";i:1;s:15:"ContractsModule";}'),
(704, 4, 1, '2016-01-05 12:29:35', 'Item Viewed', 'ZurmoModule', 'Contract', 'a:2:{i:0;s:5:"ewrwr";i:1;s:15:"ContractsModule";}'),
(705, 4, 1, '2016-01-05 12:35:25', 'Item Viewed', 'ZurmoModule', 'Contract', 'a:2:{i:0;s:5:"ewrwr";i:1;s:15:"ContractsModule";}'),
(706, 4, 1, '2016-01-05 12:35:36', 'Item Viewed', 'ZurmoModule', 'Contract', 'a:2:{i:0;s:5:"ewrwr";i:1;s:15:"ContractsModule";}'),
(707, 4, 1, '2016-01-05 12:41:02', 'Item Viewed', 'ZurmoModule', 'Contract', 'a:2:{i:0;s:5:"ewrwr";i:1;s:15:"ContractsModule";}'),
(708, 4, 1, '2016-01-05 12:50:38', 'Item Viewed', 'ZurmoModule', 'Contract', 'a:2:{i:0;s:5:"ewrwr";i:1;s:15:"ContractsModule";}'),
(709, 4, 1, '2016-01-05 12:50:40', 'Item Viewed', 'ZurmoModule', 'Contract', 'a:2:{i:0;s:5:"ewrwr";i:1;s:15:"ContractsModule";}'),
(710, 4, 1, '2016-01-05 12:51:04', 'Item Viewed', 'ZurmoModule', 'Contract', 'a:2:{i:0;s:5:"ewrwr";i:1;s:15:"ContractsModule";}'),
(711, 4, 1, '2016-01-05 13:07:57', 'Item Viewed', 'ZurmoModule', 'Contract', 'a:2:{i:0;s:5:"ewrwr";i:1;s:15:"ContractsModule";}'),
(712, 5, 1, '2016-01-05 13:10:17', 'Item Created', 'ZurmoModule', 'Contract', 's:4:"dgaf";'),
(713, 22, 1, '2016-01-05 13:10:18', 'Item Modified', 'ZurmoModule', 'GameBadge', 'a:4:{i:0;s:16:"CreateContract 2";i:1;a:1:{i:0;s:5:"grade";}i:2;s:1:"1";i:3;i:2;}'),
(714, 5, 1, '2016-01-05 13:10:19', 'Item Viewed', 'ZurmoModule', 'Contract', 'a:2:{i:0;s:4:"dgaf";i:1;s:15:"ContractsModule";}'),
(715, NULL, 1, '2016-01-05 13:11:03', 'User Logged Out', 'UsersModule', NULL, 'N;'),
(716, NULL, 1, '2016-01-05 13:11:15', 'User Logged In', 'UsersModule', NULL, 'N;'),
(717, 5, 1, '2016-01-05 13:11:35', 'Item Viewed', 'ZurmoModule', 'Contract', 'a:2:{i:0;s:4:"dgaf";i:1;s:15:"ContractsModule";}'),
(718, 5, 1, '2016-01-05 13:17:52', 'Item Viewed', 'ZurmoModule', 'Contract', 'a:2:{i:0;s:4:"dgaf";i:1;s:15:"ContractsModule";}'),
(719, NULL, 1, '2016-01-06 05:42:44', 'User Logged In', 'UsersModule', NULL, 'N;'),
(720, 5, 1, '2016-01-06 05:42:53', 'Item Viewed', 'ZurmoModule', 'Contract', 'a:2:{i:0;s:4:"dgaf";i:1;s:15:"ContractsModule";}'),
(721, 5, 1, '2016-01-06 06:06:27', 'Item Viewed', 'ZurmoModule', 'Contract', 'a:2:{i:0;s:4:"dgaf";i:1;s:15:"ContractsModule";}'),
(722, 5, 1, '2016-01-06 06:23:31', 'Item Viewed', 'ZurmoModule', 'Contract', 'a:2:{i:0;s:4:"dgaf";i:1;s:15:"ContractsModule";}'),
(723, 5, 1, '2016-01-06 06:25:54', 'Item Viewed', 'ZurmoModule', 'Contract', 'a:2:{i:0;s:4:"dgaf";i:1;s:15:"ContractsModule";}'),
(724, 20, 1, '2016-01-06 06:56:51', 'Item Created', 'ZurmoModule', 'GameLevel', 's:5:"Sales";'),
(725, 5, 1, '2016-01-06 06:56:52', 'Item Viewed', 'ZurmoModule', 'Contract', 'a:2:{i:0;s:4:"dgaf";i:1;s:15:"ContractsModule";}'),
(726, 6, 1, '2016-01-06 06:57:04', 'Item Created', 'ZurmoModule', 'Contract', 's:11:"dgafwewewew";'),
(727, 6, 1, '2016-01-06 06:57:04', 'Item Viewed', 'ZurmoModule', 'Contract', 'a:2:{i:0;s:11:"dgafwewewew";i:1;s:15:"ContractsModule";}'),
(728, NULL, 1, '2016-01-06 12:12:24', 'User Logged In', 'UsersModule', NULL, 'N;'),
(729, 1, 1, '2016-01-06 12:21:36', 'Item Created', 'ZurmoModule', 'SavedCalendar', 's:11:"My Meetings";'),
(730, 1, 1, '2016-01-06 12:21:37', 'Item Modified', 'ZurmoModule', 'SavedCalendar', 'a:4:{i:0;s:11:"My Meetings";i:1;a:1:{i:0;s:5:"color";}i:2;N;i:3;s:7:"#315AB0";}'),
(731, 1, 1, '2016-01-06 12:21:38', 'Item Modified', 'ZurmoModule', 'SavedCalendar', 'a:4:{i:0;s:11:"My Meetings";i:1;a:1:{i:0;s:14:"serializedData";}i:2;N;i:3;s:283:"a:2:{s:7:"Filters";a:1:{i:0;a:6:{s:27:"attributeIndexOrDerivedType";s:11:"owner__User";s:17:"structurePosition";s:1:"1";s:8:"operator";s:6:"equals";s:5:"value";i:1;s:24:"stringifiedModelForValue";s:10:"Super User";s:18:"availableAtRunTime";s:1:"0";}}s:16:"filtersStructure";s:1:"1";}";}'),
(732, 2, 1, '2016-01-06 12:21:39', 'Item Created', 'ZurmoModule', 'SavedCalendar', 's:8:"My Tasks";'),
(733, 2, 1, '2016-01-06 12:21:39', 'Item Modified', 'ZurmoModule', 'SavedCalendar', 'a:4:{i:0;s:8:"My Tasks";i:1;a:1:{i:0;s:5:"color";}i:2;N;i:3;s:7:"#66367b";}'),
(734, 2, 1, '2016-01-06 12:21:40', 'Item Modified', 'ZurmoModule', 'SavedCalendar', 'a:4:{i:0;s:8:"My Tasks";i:1;a:1:{i:0;s:14:"serializedData";}i:2;N;i:3;s:283:"a:2:{s:7:"Filters";a:1:{i:0;a:6:{s:27:"attributeIndexOrDerivedType";s:11:"owner__User";s:17:"structurePosition";s:1:"1";s:8:"operator";s:6:"equals";s:5:"value";i:1;s:24:"stringifiedModelForValue";s:10:"Super User";s:18:"availableAtRunTime";s:1:"0";}}s:16:"filtersStructure";s:1:"1";}";}'),
(735, 6, 1, '2016-01-06 12:25:39', 'Item Viewed', 'ZurmoModule', 'Contract', 'a:2:{i:0;s:11:"dgafwewewew";i:1;s:15:"ContractsModule";}'),
(736, 24, 1, '2016-01-06 12:26:02', 'Item Created', 'ZurmoModule', 'GameScore', 's:13:"CreateContact";'),
(737, 30, 1, '2016-01-06 12:26:02', 'Item Created', 'ZurmoModule', 'Contact', 's:9:"ewrw werw";'),
(738, 25, 1, '2016-01-06 12:26:03', 'Item Created', 'ZurmoModule', 'GameScore', 's:13:"UpdateContact";'),
(739, 21, 1, '2016-01-06 12:26:03', 'Item Created', 'ZurmoModule', 'GamePoint', 's:17:"AccountManagement";'),
(740, 23, 1, '2016-01-06 12:26:04', 'Item Created', 'ZurmoModule', 'GameBadge', 's:15:"CreateContact 1";'),
(741, 6, 1, '2016-01-06 12:26:04', 'Item Viewed', 'ZurmoModule', 'Contract', 'a:2:{i:0;s:11:"dgafwewewew";i:1;s:15:"ContractsModule";}'),
(742, 6, 1, '2016-01-06 12:26:54', 'Item Viewed', 'ZurmoModule', 'Contract', 'a:2:{i:0;s:11:"dgafwewewew";i:1;s:15:"ContractsModule";}'),
(743, 26, 1, '2016-01-06 12:27:00', 'Item Created', 'ZurmoModule', 'GameScore', 's:10:"CreateNote";'),
(744, 23, 1, '2016-01-06 12:27:00', 'Item Created', 'ZurmoModule', 'Note', 's:5:"dsfsf";'),
(745, 27, 1, '2016-01-06 12:27:01', 'Item Created', 'ZurmoModule', 'GameScore', 's:10:"UpdateNote";'),
(746, 22, 1, '2016-01-06 12:27:01', 'Item Created', 'ZurmoModule', 'GamePoint', 's:13:"Communication";'),
(747, 24, 1, '2016-01-06 12:27:01', 'Item Created', 'ZurmoModule', 'GameBadge', 's:12:"CreateNote 1";'),
(748, NULL, 1, '2016-01-07 03:38:29', 'User Logged In', 'UsersModule', NULL, 'N;'),
(749, 1, 1, '2016-01-07 03:39:10', 'Item Viewed', 'ZurmoModule', 'User', 'a:2:{i:0;s:10:"Super User";i:1;s:11:"UsersModule";}'),
(750, 1, 1, '2016-01-07 03:39:29', 'User Password Changed', 'UsersModule', 'User', 's:5:"super";'),
(751, 1, 1, '2016-01-07 03:39:29', 'Item Viewed', 'ZurmoModule', 'User', 'a:2:{i:0;s:10:"Super User";i:1;s:11:"UsersModule";}'),
(752, 6, 1, '2016-01-07 03:41:02', 'Item Viewed', 'ZurmoModule', 'Contract', 'a:2:{i:0;s:11:"dgafwewewew";i:1;s:15:"ContractsModule";}'),
(753, 6, 1, '2016-01-07 03:46:30', 'Item Viewed', 'ZurmoModule', 'Contract', 'a:2:{i:0;s:11:"dgafwewewew";i:1;s:15:"ContractsModule";}'),
(754, 6, 1, '2016-01-07 03:47:05', 'Item Viewed', 'ZurmoModule', 'Contract', 'a:2:{i:0;s:11:"dgafwewewew";i:1;s:15:"ContractsModule";}'),
(755, 28, 1, '2016-01-07 03:47:26', 'Item Created', 'ZurmoModule', 'GameScore', 's:13:"CreateMeeting";'),
(756, 38, 1, '2016-01-07 03:47:26', 'Item Created', 'ZurmoModule', 'Meeting', 's:4:"test";'),
(757, 29, 1, '2016-01-07 03:47:27', 'Item Created', 'ZurmoModule', 'GameScore', 's:13:"UpdateMeeting";'),
(758, 25, 1, '2016-01-07 03:47:28', 'Item Created', 'ZurmoModule', 'GameBadge', 's:15:"CreateMeeting 1";'),
(759, 6, 1, '2016-01-07 03:47:28', 'Item Viewed', 'ZurmoModule', 'Contract', 'a:2:{i:0;s:11:"dgafwewewew";i:1;s:15:"ContractsModule";}'),
(760, 30, 1, '2016-01-07 03:47:43', 'Item Created', 'ZurmoModule', 'GameScore', 's:10:"CreateTask";'),
(761, 20, 1, '2016-01-07 03:47:43', 'Item Created', 'ZurmoModule', 'Task', 's:4:"test";'),
(762, 31, 1, '2016-01-07 03:47:44', 'Item Created', 'ZurmoModule', 'GameScore', 's:10:"UpdateTask";'),
(763, 20, 1, '2016-01-07 03:47:44', 'Item Viewed', 'ZurmoModule', 'Task', 'a:2:{i:0;s:4:"test";i:1;s:11:"TasksModule";}'),
(764, 23, 1, '2016-01-07 03:47:45', 'Item Created', 'ZurmoModule', 'GamePoint', 's:14:"TimeManagement";'),
(765, 26, 1, '2016-01-07 03:47:45', 'Item Created', 'ZurmoModule', 'GameBadge', 's:12:"CreateTask 1";'),
(766, 6, 1, '2016-01-07 03:47:46', 'Item Viewed', 'ZurmoModule', 'Contract', 'a:2:{i:0;s:11:"dgafwewewew";i:1;s:15:"ContractsModule";}'),
(767, 12, 1, '2016-01-07 03:48:12', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:23:"Cross Country Shipments";i:1;s:19:"OpportunitiesModule";}'),
(768, 24, 1, '2016-01-07 03:48:17', 'Item Created', 'ZurmoModule', 'Note', 's:8:"sadfasdf";'),
(769, 25, 1, '2016-01-07 03:48:31', 'Item Created', 'ZurmoModule', 'Note', 's:8:"asdfasfs";'),
(770, 6, 1, '2016-01-07 03:48:52', 'Item Modified', 'ZurmoModule', 'Contract', 'a:4:{i:0;s:6:"werwrw";i:1;a:1:{i:0;s:4:"name";}i:2;s:11:"dgafwewewew";i:3;s:6:"werwrw";}'),
(771, 6, 1, '2016-01-07 03:48:53', 'Item Viewed', 'ZurmoModule', 'Contract', 'a:2:{i:0;s:6:"werwrw";i:1;s:15:"ContractsModule";}'),
(772, 32, 1, '2016-01-07 03:49:10', 'Item Created', 'ZurmoModule', 'GameScore', 's:17:"UpdateOpportunity";'),
(773, 12, 1, '2016-01-07 03:49:10', 'Item Modified', 'ZurmoModule', 'Opportunity', 'a:4:{i:0;s:24:"Cross Country Shipments2";i:1;a:1:{i:0;s:4:"name";}i:2;s:23:"Cross Country Shipments";i:3;s:24:"Cross Country Shipments2";}'),
(774, 12, 1, '2016-01-07 03:49:10', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:24:"Cross Country Shipments2";i:1;s:19:"OpportunitiesModule";}'),
(775, 12, 1, '2016-01-07 03:49:24', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:24:"Cross Country Shipments2";i:1;s:19:"OpportunitiesModule";}'),
(776, 6, 1, '2016-01-07 03:49:27', 'Item Viewed', 'ZurmoModule', 'Contract', 'a:2:{i:0;s:6:"werwrw";i:1;s:15:"ContractsModule";}'),
(777, 12, 1, '2016-01-07 03:49:31', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:24:"Cross Country Shipments2";i:1;s:19:"OpportunitiesModule";}'),
(778, 6, 1, '2016-01-07 03:49:37', 'Item Viewed', 'ZurmoModule', 'Contract', 'a:2:{i:0;s:6:"werwrw";i:1;s:15:"ContractsModule";}'),
(779, 12, 1, '2016-01-07 03:49:50', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:24:"Cross Country Shipments2";i:1;s:19:"OpportunitiesModule";}'),
(780, 12, 1, '2016-01-07 03:50:00', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:24:"Cross Country Shipments2";i:1;s:19:"OpportunitiesModule";}'),
(781, 12, 1, '2016-01-07 03:50:14', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:24:"Cross Country Shipments2";i:1;s:19:"OpportunitiesModule";}'),
(782, 6, 1, '2016-01-07 03:50:16', 'Item Viewed', 'ZurmoModule', 'Contract', 'a:2:{i:0;s:6:"werwrw";i:1;s:15:"ContractsModule";}'),
(783, 6, 1, '2016-01-07 03:50:36', 'Item Viewed', 'ZurmoModule', 'Contract', 'a:2:{i:0;s:6:"werwrw";i:1;s:15:"ContractsModule";}'),
(784, 6, 1, '2016-01-07 03:50:41', 'Item Viewed', 'ZurmoModule', 'Contract', 'a:2:{i:0;s:6:"werwrw";i:1;s:15:"ContractsModule";}'),
(785, 6, 1, '2016-01-07 03:50:51', 'Item Viewed', 'ZurmoModule', 'Contract', 'a:2:{i:0;s:6:"werwrw";i:1;s:15:"ContractsModule";}'),
(786, 6, 1, '2016-01-07 03:51:07', 'Item Viewed', 'ZurmoModule', 'Contract', 'a:2:{i:0;s:6:"werwrw";i:1;s:15:"ContractsModule";}'),
(787, 20, 1, '2016-01-07 03:51:34', 'Item Modified', 'ZurmoModule', 'Task', 'a:4:{i:0;s:5:"test3";i:1;a:1:{i:0;s:4:"name";}i:2;s:4:"test";i:3;s:5:"test3";}'),
(788, 20, 1, '2016-01-07 03:51:35', 'Item Modified', 'ZurmoModule', 'Task', 'a:4:{i:0;s:5:"test3";i:1;a:1:{i:0;s:11:"dueDateTime";}i:2;s:19:"0000-00-00 00:00:00";i:3;s:0:"";}'),
(789, 20, 1, '2016-01-07 03:51:35', 'Item Viewed', 'ZurmoModule', 'Task', 'a:2:{i:0;s:5:"test3";i:1;s:11:"TasksModule";}'),
(790, 6, 1, '2016-01-07 03:51:36', 'Item Viewed', 'ZurmoModule', 'Contract', 'a:2:{i:0;s:6:"werwrw";i:1;s:15:"ContractsModule";}'),
(791, 6, 1, '2016-01-07 03:51:38', 'Item Viewed', 'ZurmoModule', 'Contract', 'a:2:{i:0;s:6:"werwrw";i:1;s:15:"ContractsModule";}'),
(792, 21, 1, '2016-01-07 03:51:45', 'Item Created', 'ZurmoModule', 'Task', 's:6:"test34";'),
(793, 21, 1, '2016-01-07 03:51:45', 'Item Viewed', 'ZurmoModule', 'Task', 'a:2:{i:0;s:6:"test34";i:1;s:11:"TasksModule";}'),
(794, 6, 1, '2016-01-07 03:51:47', 'Item Viewed', 'ZurmoModule', 'Contract', 'a:2:{i:0;s:6:"werwrw";i:1;s:15:"ContractsModule";}'),
(795, 6, 1, '2016-01-07 03:51:48', 'Item Viewed', 'ZurmoModule', 'Contract', 'a:2:{i:0;s:6:"werwrw";i:1;s:15:"ContractsModule";}'),
(796, 6, 1, '2016-01-07 03:52:10', 'Item Viewed', 'ZurmoModule', 'Contract', 'a:2:{i:0;s:6:"werwrw";i:1;s:15:"ContractsModule";}'),
(797, 6, 1, '2016-01-07 03:52:20', 'Item Viewed', 'ZurmoModule', 'Contract', 'a:2:{i:0;s:6:"werwrw";i:1;s:15:"ContractsModule";}'),
(798, 6, 1, '2016-01-07 04:33:43', 'Item Viewed', 'ZurmoModule', 'Contract', 'a:2:{i:0;s:6:"werwrw";i:1;s:15:"ContractsModule";}'),
(799, 1, 1, '2016-01-07 04:56:12', 'Item Created', 'ZurmoModule', 'Dashboard', 's:9:"Dashboard";'),
(800, 10, 1, '2016-01-07 04:56:14', 'Item Created', 'ZurmoModule', 'EmailFolder', 's:5:"Draft";'),
(801, 11, 1, '2016-01-07 04:56:14', 'Item Created', 'ZurmoModule', 'EmailFolder', 's:4:"Sent";'),
(802, 12, 1, '2016-01-07 04:56:14', 'Item Created', 'ZurmoModule', 'EmailFolder', 's:6:"Outbox";'),
(803, 13, 1, '2016-01-07 04:56:14', 'Item Created', 'ZurmoModule', 'EmailFolder', 's:12:"Outbox Error";'),
(804, 14, 1, '2016-01-07 04:56:15', 'Item Created', 'ZurmoModule', 'EmailFolder', 's:14:"Outbox Failure";'),
(805, 15, 1, '2016-01-07 04:56:15', 'Item Created', 'ZurmoModule', 'EmailFolder', 's:5:"Inbox";'),
(806, 16, 1, '2016-01-07 04:56:15', 'Item Created', 'ZurmoModule', 'EmailFolder', 's:8:"Archived";'),
(807, 17, 1, '2016-01-07 04:56:15', 'Item Created', 'ZurmoModule', 'EmailFolder', 's:18:"Archived Unmatched";'),
(808, 3, 1, '2016-01-07 04:56:16', 'Item Created', 'ZurmoModule', 'EmailBox', 's:20:"System Notifications";'),
(809, NULL, 1, '2016-01-07 05:49:54', 'User Logged In', 'UsersModule', NULL, 'N;'),
(810, NULL, 1, '2016-01-07 08:42:29', 'User Logged In', 'UsersModule', NULL, 'N;'),
(811, 5, 1, '2016-01-07 10:56:08', 'Item Viewed', 'ZurmoModule', 'Contract', 'a:2:{i:0;s:4:"dgaf";i:1;s:15:"ContractsModule";}'),
(812, NULL, 1, '2016-01-07 15:47:37', 'User Logged In', 'UsersModule', NULL, 'N;'),
(813, 3, 1, '2016-01-07 15:48:11', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:19:"Consulting Services";i:1;s:19:"OpportunitiesModule";}'),
(814, NULL, 1, '2016-01-07 16:15:14', 'User Logged In', 'UsersModule', NULL, 'N;'),
(815, NULL, 1, '2016-01-07 17:05:54', 'User Logged Out', 'UsersModule', NULL, 'N;'),
(816, NULL, 1, '2016-01-07 17:06:18', 'User Logged In', 'UsersModule', NULL, 'N;'),
(817, 18, 1, '2016-01-07 17:06:18', 'Item Modified', 'ZurmoModule', 'GameBadge', 'a:4:{i:0;s:11:"LoginUser 3";i:1;a:1:{i:0;s:5:"grade";}i:2;s:1:"2";i:3;i:3;}'),
(818, 3, 1, '2016-01-07 17:07:21', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:19:"Consulting Services";i:1;s:19:"OpportunitiesModule";}'),
(819, NULL, 1, '2016-01-08 16:27:08', 'User Logged In', 'UsersModule', NULL, 'N;'),
(820, 3, 1, '2016-01-08 16:27:38', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:19:"Consulting Services";i:1;s:19:"OpportunitiesModule";}'),
(821, 33, 1, '2016-01-08 17:01:25', 'Item Created', 'ZurmoModule', 'GameScore', 's:17:"CreateOpportunity";'),
(822, 14, 1, '2016-01-08 17:01:25', 'Item Created', 'ZurmoModule', 'Opportunity', 's:8:"test sss";'),
(823, 27, 1, '2016-01-08 17:01:27', 'Item Created', 'ZurmoModule', 'GameBadge', 's:19:"CreateOpportunity 1";'),
(824, 14, 1, '2016-01-08 17:01:30', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:8:"test sss";i:1;s:19:"OpportunitiesModule";}'),
(825, 7, 1, '2016-01-08 17:02:32', 'Item Created', 'ZurmoModule', 'Contract', 's:9:"dssssssss";'),
(826, 7, 1, '2016-01-08 17:02:37', 'Item Viewed', 'ZurmoModule', 'Contract', 'a:2:{i:0;s:9:"dssssssss";i:1;s:15:"ContractsModule";}'),
(827, 5, 1, '2016-01-08 17:16:50', 'Item Viewed', 'ZurmoModule', 'Account', 'a:2:{i:0;s:14:"Allied Biscuit";i:1;s:14:"AccountsModule";}'),
(828, 8, 1, '2016-01-08 17:17:25', 'Item Created', 'ZurmoModule', 'Account', 's:12:"Test account";'),
(829, 34, 1, '2016-01-08 17:17:26', 'Item Created', 'ZurmoModule', 'GameScore', 's:13:"UpdateAccount";'),
(830, 8, 1, '2016-01-08 17:17:30', 'Item Viewed', 'ZurmoModule', 'Account', 'a:2:{i:0;s:12:"Test account";i:1;s:14:"AccountsModule";}'),
(831, 8, 1, '2016-01-08 17:49:26', 'Item Viewed', 'ZurmoModule', 'Account', 'a:2:{i:0;s:12:"Test account";i:1;s:14:"AccountsModule";}'),
(832, 7, 1, '2016-01-08 19:02:03', 'Item Viewed', 'ZurmoModule', 'Contract', 'a:2:{i:0;s:9:"dssssssss";i:1;s:15:"ContractsModule";}'),
(833, 7, 1, '2016-01-08 19:02:50', 'Item Modified', 'ZurmoModule', 'Contract', 'a:4:{i:0;s:9:"dssssssss";i:1;a:1:{i:0;s:7:"account";}i:2;a:3:{i:0;s:7:"Account";i:1;i:5;i:2;s:14:"Allied Biscuit";}i:3;a:3:{i:0;s:7:"Account";i:1;i:6;i:2;s:10:"Globo-Chem";}}'),
(834, 7, 1, '2016-01-08 19:02:58', 'Item Viewed', 'ZurmoModule', 'Contract', 'a:2:{i:0;s:9:"dssssssss";i:1;s:15:"ContractsModule";}'),
(835, 5, 1, '2016-01-08 19:04:36', 'Item Viewed', 'ZurmoModule', 'Account', 'a:2:{i:0;s:14:"Allied Biscuit";i:1;s:14:"AccountsModule";}'),
(836, 5, 1, '2016-01-08 19:06:50', 'Item Viewed', 'ZurmoModule', 'Account', 'a:2:{i:0;s:14:"Allied Biscuit";i:1;s:14:"AccountsModule";}'),
(837, 5, 1, '2016-01-08 19:08:10', 'Item Viewed', 'ZurmoModule', 'Account', 'a:2:{i:0;s:14:"Allied Biscuit";i:1;s:14:"AccountsModule";}'),
(838, NULL, 1, '2016-01-10 10:03:13', 'User Logged In', 'UsersModule', NULL, 'N;'),
(839, 5, 1, '2016-01-10 10:05:12', 'Item Viewed', 'ZurmoModule', 'Account', 'a:2:{i:0;s:14:"Allied Biscuit";i:1;s:14:"AccountsModule";}'),
(840, 5, 1, '2016-01-10 10:12:45', 'Item Viewed', 'ZurmoModule', 'Account', 'a:2:{i:0;s:14:"Allied Biscuit";i:1;s:14:"AccountsModule";}'),
(841, 5, 1, '2016-01-10 10:13:21', 'Item Viewed', 'ZurmoModule', 'Account', 'a:2:{i:0;s:14:"Allied Biscuit";i:1;s:14:"AccountsModule";}'),
(842, 5, 1, '2016-01-10 10:13:54', 'Item Viewed', 'ZurmoModule', 'Account', 'a:2:{i:0;s:14:"Allied Biscuit";i:1;s:14:"AccountsModule";}'),
(843, 5, 1, '2016-01-10 10:23:53', 'Item Viewed', 'ZurmoModule', 'Account', 'a:2:{i:0;s:14:"Allied Biscuit";i:1;s:14:"AccountsModule";}'),
(844, 5, 1, '2016-01-10 10:28:46', 'Item Viewed', 'ZurmoModule', 'Account', 'a:2:{i:0;s:14:"Allied Biscuit";i:1;s:14:"AccountsModule";}'),
(845, NULL, 1, '2016-01-10 11:08:28', 'User Logged Out', 'UsersModule', NULL, 'N;'),
(846, NULL, 1, '2016-01-10 11:08:57', 'User Logged In', 'UsersModule', NULL, 'N;'),
(847, 5, 1, '2016-01-10 11:09:33', 'Item Viewed', 'ZurmoModule', 'Account', 'a:2:{i:0;s:14:"Allied Biscuit";i:1;s:14:"AccountsModule";}'),
(848, NULL, 1, '2016-01-10 11:15:56', 'User Logged In', 'UsersModule', NULL, 'N;'),
(849, 5, 1, '2016-01-10 11:26:31', 'Item Viewed', 'ZurmoModule', 'Account', 'a:2:{i:0;s:14:"Allied Biscuit";i:1;s:14:"AccountsModule";}'),
(850, NULL, 1, '2016-01-10 12:58:08', 'User Logged In', 'UsersModule', NULL, 'N;'),
(851, 5, 1, '2016-01-10 12:58:41', 'Item Viewed', 'ZurmoModule', 'Account', 'a:2:{i:0;s:14:"Allied Biscuit";i:1;s:14:"AccountsModule";}'),
(852, 5, 1, '2016-01-10 13:12:20', 'Item Viewed', 'ZurmoModule', 'Contract', 'a:2:{i:0;s:4:"dgaf";i:1;s:15:"ContractsModule";}'),
(853, 3, 1, '2016-01-10 13:14:53', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:19:"Consulting Services";i:1;s:19:"OpportunitiesModule";}'),
(854, 3, 1, '2016-01-10 13:16:07', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:19:"Consulting Services";i:1;s:19:"OpportunitiesModule";}'),
(855, 3, 1, '2016-01-10 13:24:05', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:19:"Consulting Services";i:1;s:19:"OpportunitiesModule";}'),
(856, 3, 1, '2016-01-10 13:32:18', 'Item Modified', 'ZurmoModule', 'Opportunity', 'a:4:{i:0;s:19:"Consulting Services";i:1;a:2:{i:0;s:6:"amount";i:1;s:5:"value";}i:2;s:6:"216000";i:3;s:6:"102222";}'),
(857, 3, 1, '2016-01-10 13:32:22', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:19:"Consulting Services";i:1;s:19:"OpportunitiesModule";}'),
(858, 3, 1, '2016-01-10 13:33:38', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:19:"Consulting Services";i:1;s:19:"OpportunitiesModule";}'),
(859, 5, 1, '2016-01-10 13:34:02', 'Item Viewed', 'ZurmoModule', 'Account', 'a:2:{i:0;s:14:"Allied Biscuit";i:1;s:14:"AccountsModule";}'),
(860, 5, 1, '2016-01-10 13:35:50', 'Item Viewed', 'ZurmoModule', 'Account', 'a:2:{i:0;s:14:"Allied Biscuit";i:1;s:14:"AccountsModule";}'),
(861, 5, 1, '2016-01-10 13:36:04', 'Item Viewed', 'ZurmoModule', 'Account', 'a:2:{i:0;s:14:"Allied Biscuit";i:1;s:14:"AccountsModule";}'),
(862, 3, 1, '2016-01-10 13:37:21', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:19:"Consulting Services";i:1;s:19:"OpportunitiesModule";}'),
(863, 7, 1, '2016-01-10 13:37:47', 'Item Viewed', 'ZurmoModule', 'Contract', 'a:2:{i:0;s:9:"dssssssss";i:1;s:15:"ContractsModule";}'),
(864, 5, 1, '2016-01-10 13:39:39', 'Item Viewed', 'ZurmoModule', 'Account', 'a:2:{i:0;s:14:"Allied Biscuit";i:1;s:14:"AccountsModule";}'),
(865, 5, 1, '2016-01-10 13:40:29', 'Item Viewed', 'ZurmoModule', 'Account', 'a:2:{i:0;s:14:"Allied Biscuit";i:1;s:14:"AccountsModule";}'),
(866, 5, 1, '2016-01-10 13:41:31', 'Item Viewed', 'ZurmoModule', 'Account', 'a:2:{i:0;s:14:"Allied Biscuit";i:1;s:14:"AccountsModule";}'),
(867, 5, 1, '2016-01-10 13:42:01', 'Item Viewed', 'ZurmoModule', 'Account', 'a:2:{i:0;s:14:"Allied Biscuit";i:1;s:14:"AccountsModule";}'),
(868, NULL, 1, '2016-01-10 13:42:20', 'User Logged Out', 'UsersModule', NULL, 'N;'),
(869, NULL, 1, '2016-01-10 13:42:44', 'User Logged In', 'UsersModule', NULL, 'N;'),
(870, 5, 1, '2016-01-10 13:43:06', 'Item Viewed', 'ZurmoModule', 'Account', 'a:2:{i:0;s:14:"Allied Biscuit";i:1;s:14:"AccountsModule";}'),
(871, 5, 1, '2016-01-10 13:44:48', 'Item Viewed', 'ZurmoModule', 'Account', 'a:2:{i:0;s:14:"Allied Biscuit";i:1;s:14:"AccountsModule";}'),
(872, 5, 1, '2016-01-10 13:45:08', 'Item Viewed', 'ZurmoModule', 'Account', 'a:2:{i:0;s:14:"Allied Biscuit";i:1;s:14:"AccountsModule";}'),
(873, 5, 1, '2016-01-10 13:50:41', 'Item Viewed', 'ZurmoModule', 'Account', 'a:2:{i:0;s:14:"Allied Biscuit";i:1;s:14:"AccountsModule";}'),
(874, 5, 1, '2016-01-10 13:50:53', 'Item Viewed', 'ZurmoModule', 'Account', 'a:2:{i:0;s:14:"Allied Biscuit";i:1;s:14:"AccountsModule";}'),
(875, 5, 1, '2016-01-10 13:51:51', 'Item Viewed', 'ZurmoModule', 'Account', 'a:2:{i:0;s:14:"Allied Biscuit";i:1;s:14:"AccountsModule";}'),
(876, 5, 1, '2016-01-10 13:53:32', 'Item Viewed', 'ZurmoModule', 'Account', 'a:2:{i:0;s:14:"Allied Biscuit";i:1;s:14:"AccountsModule";}'),
(877, 5, 1, '2016-01-10 13:53:59', 'Item Viewed', 'ZurmoModule', 'Account', 'a:2:{i:0;s:14:"Allied Biscuit";i:1;s:14:"AccountsModule";}'),
(878, 5, 1, '2016-01-10 13:55:39', 'Item Viewed', 'ZurmoModule', 'Account', 'a:2:{i:0;s:14:"Allied Biscuit";i:1;s:14:"AccountsModule";}'),
(879, 5, 1, '2016-01-10 13:56:02', 'Item Viewed', 'ZurmoModule', 'Account', 'a:2:{i:0;s:14:"Allied Biscuit";i:1;s:14:"AccountsModule";}'),
(880, 5, 1, '2016-01-10 13:58:21', 'Item Viewed', 'ZurmoModule', 'Account', 'a:2:{i:0;s:14:"Allied Biscuit";i:1;s:14:"AccountsModule";}'),
(881, 5, 1, '2016-01-10 14:00:28', 'Item Viewed', 'ZurmoModule', 'Account', 'a:2:{i:0;s:14:"Allied Biscuit";i:1;s:14:"AccountsModule";}'),
(882, 5, 1, '2016-01-10 14:02:07', 'Item Viewed', 'ZurmoModule', 'Account', 'a:2:{i:0;s:14:"Allied Biscuit";i:1;s:14:"AccountsModule";}'),
(883, 5, 1, '2016-01-10 14:02:17', 'Item Viewed', 'ZurmoModule', 'Account', 'a:2:{i:0;s:14:"Allied Biscuit";i:1;s:14:"AccountsModule";}'),
(884, 5, 1, '2016-01-10 14:02:31', 'Item Viewed', 'ZurmoModule', 'Account', 'a:2:{i:0;s:14:"Allied Biscuit";i:1;s:14:"AccountsModule";}'),
(885, 5, 1, '2016-01-10 14:03:01', 'Item Viewed', 'ZurmoModule', 'Account', 'a:2:{i:0;s:14:"Allied Biscuit";i:1;s:14:"AccountsModule";}'),
(886, 5, 1, '2016-01-10 14:05:15', 'Item Viewed', 'ZurmoModule', 'Account', 'a:2:{i:0;s:14:"Allied Biscuit";i:1;s:14:"AccountsModule";}'),
(887, 5, 1, '2016-01-10 14:05:46', 'Item Viewed', 'ZurmoModule', 'Account', 'a:2:{i:0;s:14:"Allied Biscuit";i:1;s:14:"AccountsModule";}'),
(888, 5, 1, '2016-01-10 14:07:03', 'Item Viewed', 'ZurmoModule', 'Account', 'a:2:{i:0;s:14:"Allied Biscuit";i:1;s:14:"AccountsModule";}'),
(889, 5, 1, '2016-01-10 14:07:34', 'Item Viewed', 'ZurmoModule', 'Account', 'a:2:{i:0;s:14:"Allied Biscuit";i:1;s:14:"AccountsModule";}'),
(890, NULL, 1, '2016-01-10 14:09:36', 'User Logged Out', 'UsersModule', NULL, 'N;'),
(891, NULL, 1, '2016-01-10 14:09:57', 'User Logged In', 'UsersModule', NULL, 'N;'),
(892, 5, 1, '2016-01-10 14:10:15', 'Item Viewed', 'ZurmoModule', 'Account', 'a:2:{i:0;s:14:"Allied Biscuit";i:1;s:14:"AccountsModule";}'),
(893, 5, 1, '2016-01-10 14:12:37', 'Item Viewed', 'ZurmoModule', 'Account', 'a:2:{i:0;s:14:"Allied Biscuit";i:1;s:14:"AccountsModule";}'),
(894, 5, 1, '2016-01-10 14:12:52', 'Item Viewed', 'ZurmoModule', 'Account', 'a:2:{i:0;s:14:"Allied Biscuit";i:1;s:14:"AccountsModule";}'),
(895, 5, 1, '2016-01-10 14:13:10', 'Item Viewed', 'ZurmoModule', 'Account', 'a:2:{i:0;s:14:"Allied Biscuit";i:1;s:14:"AccountsModule";}'),
(896, 5, 1, '2016-01-10 14:13:35', 'Item Viewed', 'ZurmoModule', 'Account', 'a:2:{i:0;s:14:"Allied Biscuit";i:1;s:14:"AccountsModule";}'),
(897, 5, 1, '2016-01-10 14:13:47', 'Item Viewed', 'ZurmoModule', 'Account', 'a:2:{i:0;s:14:"Allied Biscuit";i:1;s:14:"AccountsModule";}'),
(898, 5, 1, '2016-01-10 14:14:08', 'Item Viewed', 'ZurmoModule', 'Account', 'a:2:{i:0;s:14:"Allied Biscuit";i:1;s:14:"AccountsModule";}'),
(899, 5, 1, '2016-01-10 14:14:26', 'Item Viewed', 'ZurmoModule', 'Account', 'a:2:{i:0;s:14:"Allied Biscuit";i:1;s:14:"AccountsModule";}'),
(900, 5, 1, '2016-01-10 14:20:25', 'Item Viewed', 'ZurmoModule', 'Account', 'a:2:{i:0;s:14:"Allied Biscuit";i:1;s:14:"AccountsModule";}'),
(901, NULL, 1, '2016-01-10 14:21:19', 'User Logged In', 'UsersModule', NULL, 'N;'),
(902, 5, 1, '2016-01-10 14:21:38', 'Item Viewed', 'ZurmoModule', 'Account', 'a:2:{i:0;s:14:"Allied Biscuit";i:1;s:14:"AccountsModule";}'),
(903, 5, 1, '2016-01-10 14:22:06', 'Item Viewed', 'ZurmoModule', 'Account', 'a:2:{i:0;s:14:"Allied Biscuit";i:1;s:14:"AccountsModule";}'),
(904, 5, 1, '2016-01-10 14:23:30', 'Item Viewed', 'ZurmoModule', 'Account', 'a:2:{i:0;s:14:"Allied Biscuit";i:1;s:14:"AccountsModule";}'),
(905, 3, 1, '2016-01-10 14:25:09', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:19:"Consulting Services";i:1;s:19:"OpportunitiesModule";}'),
(906, 3, 1, '2016-01-10 14:34:48', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:19:"Consulting Services";i:1;s:19:"OpportunitiesModule";}'),
(907, 3, 1, '2016-01-10 14:35:25', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:19:"Consulting Services";i:1;s:19:"OpportunitiesModule";}'),
(908, 3, 1, '2016-01-10 14:39:21', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:19:"Consulting Services";i:1;s:19:"OpportunitiesModule";}'),
(909, 3, 1, '2016-01-10 14:56:57', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:19:"Consulting Services";i:1;s:19:"OpportunitiesModule";}'),
(910, 3, 1, '2016-01-10 15:09:50', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:19:"Consulting Services";i:1;s:19:"OpportunitiesModule";}'),
(911, 3, 1, '2016-01-10 15:12:05', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:19:"Consulting Services";i:1;s:19:"OpportunitiesModule";}'),
(912, 5, 1, '2016-01-10 15:24:39', 'Item Viewed', 'ZurmoModule', 'Account', 'a:2:{i:0;s:14:"Allied Biscuit";i:1;s:14:"AccountsModule";}'),
(913, 5, 1, '2016-01-10 15:24:53', 'Item Viewed', 'ZurmoModule', 'Account', 'a:2:{i:0;s:14:"Allied Biscuit";i:1;s:14:"AccountsModule";}'),
(914, 5, 1, '2016-01-10 15:28:58', 'Item Viewed', 'ZurmoModule', 'Account', 'a:2:{i:0;s:14:"Allied Biscuit";i:1;s:14:"AccountsModule";}'),
(915, 3, 1, '2016-01-10 15:29:18', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:19:"Consulting Services";i:1;s:19:"OpportunitiesModule";}'),
(916, 5, 1, '2016-01-10 15:48:19', 'Item Viewed', 'ZurmoModule', 'Account', 'a:2:{i:0;s:14:"Allied Biscuit";i:1;s:14:"AccountsModule";}'),
(917, 5, 1, '2016-01-10 15:48:49', 'Item Viewed', 'ZurmoModule', 'Account', 'a:2:{i:0;s:14:"Allied Biscuit";i:1;s:14:"AccountsModule";}'),
(918, 5, 1, '2016-01-10 15:49:08', 'Item Viewed', 'ZurmoModule', 'Account', 'a:2:{i:0;s:14:"Allied Biscuit";i:1;s:14:"AccountsModule";}'),
(919, 5, 1, '2016-01-10 15:49:31', 'Item Viewed', 'ZurmoModule', 'Account', 'a:2:{i:0;s:14:"Allied Biscuit";i:1;s:14:"AccountsModule";}'),
(920, 5, 1, '2016-01-10 15:50:26', 'Item Viewed', 'ZurmoModule', 'Account', 'a:2:{i:0;s:14:"Allied Biscuit";i:1;s:14:"AccountsModule";}'),
(921, 5, 1, '2016-01-10 15:50:45', 'Item Viewed', 'ZurmoModule', 'Account', 'a:2:{i:0;s:14:"Allied Biscuit";i:1;s:14:"AccountsModule";}'),
(922, 5, 1, '2016-01-10 15:51:12', 'Item Viewed', 'ZurmoModule', 'Account', 'a:2:{i:0;s:14:"Allied Biscuit";i:1;s:14:"AccountsModule";}'),
(923, NULL, 1, '2016-01-10 15:51:23', 'User Logged Out', 'UsersModule', NULL, 'N;'),
(924, NULL, 1, '2016-01-10 15:51:46', 'User Logged In', 'UsersModule', NULL, 'N;'),
(925, 5, 1, '2016-01-10 15:52:07', 'Item Viewed', 'ZurmoModule', 'Account', 'a:2:{i:0;s:14:"Allied Biscuit";i:1;s:14:"AccountsModule";}'),
(926, NULL, 1, '2016-01-10 15:53:19', 'User Logged In', 'UsersModule', NULL, 'N;'),
(927, 5, 1, '2016-01-10 15:53:40', 'Item Viewed', 'ZurmoModule', 'Account', 'a:2:{i:0;s:14:"Allied Biscuit";i:1;s:14:"AccountsModule";}'),
(928, 5, 1, '2016-01-10 15:54:08', 'Item Viewed', 'ZurmoModule', 'Account', 'a:2:{i:0;s:14:"Allied Biscuit";i:1;s:14:"AccountsModule";}'),
(929, 5, 1, '2016-01-10 15:56:13', 'Item Viewed', 'ZurmoModule', 'Account', 'a:2:{i:0;s:14:"Allied Biscuit";i:1;s:14:"AccountsModule";}'),
(930, 3, 1, '2016-01-10 16:01:07', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:19:"Consulting Services";i:1;s:19:"OpportunitiesModule";}'),
(931, 3, 1, '2016-01-10 16:01:41', 'Item Modified', 'ZurmoModule', 'Opportunity', 'a:4:{i:0;s:19:"Consulting Services";i:1;a:2:{i:0;s:6:"amount";i:1;s:5:"value";}i:2;s:6:"102222";i:3;s:4:"1099";}'),
(932, 3, 1, '2016-01-10 16:01:45', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:19:"Consulting Services";i:1;s:19:"OpportunitiesModule";}'),
(933, 5, 1, '2016-01-10 16:02:33', 'Item Viewed', 'ZurmoModule', 'Account', 'a:2:{i:0;s:14:"Allied Biscuit";i:1;s:14:"AccountsModule";}'),
(934, 3, 1, '2016-01-10 16:02:53', 'Item Viewed', 'ZurmoModule', 'Account', 'a:2:{i:0;s:23:"Big T Burgers and Fries";i:1;s:14:"AccountsModule";}'),
(935, 3, 1, '2016-01-10 16:03:19', 'Item Viewed', 'ZurmoModule', 'Account', 'a:2:{i:0;s:23:"Big T Burgers and Fries";i:1;s:14:"AccountsModule";}'),
(936, 15, 1, '2016-01-10 16:04:15', 'Item Created', 'ZurmoModule', 'Opportunity', 's:8:"test opp";'),
(937, 3, 1, '2016-01-10 16:04:19', 'Item Viewed', 'ZurmoModule', 'Account', 'a:2:{i:0;s:23:"Big T Burgers and Fries";i:1;s:14:"AccountsModule";}'),
(938, 3, 1, '2016-01-10 16:05:13', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:19:"Consulting Services";i:1;s:19:"OpportunitiesModule";}'),
(939, 3, 1, '2016-01-10 16:09:42', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:19:"Consulting Services";i:1;s:19:"OpportunitiesModule";}'),
(940, 3, 1, '2016-01-10 16:13:39', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:19:"Consulting Services";i:1;s:19:"OpportunitiesModule";}');
INSERT INTO `auditevent` (`id`, `modelid`, `_user_id`, `datetime`, `eventname`, `modulename`, `modelclassname`, `serializeddata`) VALUES
(941, 3, 1, '2016-01-10 16:21:05', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:19:"Consulting Services";i:1;s:19:"OpportunitiesModule";}'),
(942, 3, 1, '2016-01-10 16:22:48', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:19:"Consulting Services";i:1;s:19:"OpportunitiesModule";}'),
(943, 5, 1, '2016-01-10 16:27:44', 'Item Viewed', 'ZurmoModule', 'Contract', 'a:2:{i:0;s:4:"dgaf";i:1;s:15:"ContractsModule";}'),
(944, 3, 1, '2016-01-10 16:31:16', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:19:"Consulting Services";i:1;s:19:"OpportunitiesModule";}'),
(945, 3, 1, '2016-01-10 16:48:09', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:19:"Consulting Services";i:1;s:19:"OpportunitiesModule";}'),
(946, 3, 1, '2016-01-10 16:48:44', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:19:"Consulting Services";i:1;s:19:"OpportunitiesModule";}'),
(947, 5, 1, '2016-01-10 16:49:26', 'Item Viewed', 'ZurmoModule', 'Contract', 'a:2:{i:0;s:4:"dgaf";i:1;s:15:"ContractsModule";}'),
(948, 3, 1, '2016-01-10 16:53:19', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:19:"Consulting Services";i:1;s:19:"OpportunitiesModule";}'),
(949, 3, 1, '2016-01-10 16:56:40', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:19:"Consulting Services";i:1;s:19:"OpportunitiesModule";}'),
(950, 3, 1, '2016-01-10 16:58:37', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:19:"Consulting Services";i:1;s:19:"OpportunitiesModule";}'),
(951, 3, 1, '2016-01-10 17:00:50', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:19:"Consulting Services";i:1;s:19:"OpportunitiesModule";}'),
(952, 3, 1, '2016-01-10 17:02:47', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:19:"Consulting Services";i:1;s:19:"OpportunitiesModule";}'),
(953, 3, 1, '2016-01-10 17:03:43', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:19:"Consulting Services";i:1;s:19:"OpportunitiesModule";}'),
(954, 3, 1, '2016-01-10 17:04:31', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:19:"Consulting Services";i:1;s:19:"OpportunitiesModule";}'),
(955, 3, 1, '2016-01-10 17:04:57', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:19:"Consulting Services";i:1;s:19:"OpportunitiesModule";}'),
(956, 3, 1, '2016-01-10 17:05:33', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:19:"Consulting Services";i:1;s:19:"OpportunitiesModule";}'),
(957, 3, 1, '2016-01-10 17:06:58', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:19:"Consulting Services";i:1;s:19:"OpportunitiesModule";}'),
(958, 3, 1, '2016-01-10 17:07:15', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:19:"Consulting Services";i:1;s:19:"OpportunitiesModule";}'),
(959, 3, 1, '2016-01-10 17:08:18', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:19:"Consulting Services";i:1;s:19:"OpportunitiesModule";}'),
(960, 3, 1, '2016-01-10 17:09:41', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:19:"Consulting Services";i:1;s:19:"OpportunitiesModule";}'),
(961, 3, 1, '2016-01-10 17:09:59', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:19:"Consulting Services";i:1;s:19:"OpportunitiesModule";}'),
(962, 3, 1, '2016-01-10 17:15:16', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:19:"Consulting Services";i:1;s:19:"OpportunitiesModule";}'),
(963, 3, 1, '2016-01-10 17:16:18', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:19:"Consulting Services";i:1;s:19:"OpportunitiesModule";}'),
(964, 3, 1, '2016-01-10 17:19:35', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:19:"Consulting Services";i:1;s:19:"OpportunitiesModule";}'),
(965, 3, 1, '2016-01-10 17:20:15', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:19:"Consulting Services";i:1;s:19:"OpportunitiesModule";}'),
(966, 3, 1, '2016-01-10 17:20:36', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:19:"Consulting Services";i:1;s:19:"OpportunitiesModule";}'),
(967, 3, 1, '2016-01-10 17:20:55', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:19:"Consulting Services";i:1;s:19:"OpportunitiesModule";}'),
(968, 3, 1, '2016-01-10 17:21:08', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:19:"Consulting Services";i:1;s:19:"OpportunitiesModule";}'),
(969, 3, 1, '2016-01-10 17:21:56', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:19:"Consulting Services";i:1;s:19:"OpportunitiesModule";}'),
(970, 3, 1, '2016-01-10 17:26:08', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:19:"Consulting Services";i:1;s:19:"OpportunitiesModule";}'),
(971, 3, 1, '2016-01-10 17:26:54', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:19:"Consulting Services";i:1;s:19:"OpportunitiesModule";}'),
(972, 3, 1, '2016-01-10 17:27:08', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:19:"Consulting Services";i:1;s:19:"OpportunitiesModule";}'),
(973, 3, 1, '2016-01-10 17:27:26', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:19:"Consulting Services";i:1;s:19:"OpportunitiesModule";}'),
(974, 3, 1, '2016-01-10 17:27:50', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:19:"Consulting Services";i:1;s:19:"OpportunitiesModule";}'),
(975, 3, 1, '2016-01-10 17:28:12', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:19:"Consulting Services";i:1;s:19:"OpportunitiesModule";}'),
(976, 3, 1, '2016-01-10 17:28:23', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:19:"Consulting Services";i:1;s:19:"OpportunitiesModule";}'),
(977, 3, 1, '2016-01-10 17:28:47', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:19:"Consulting Services";i:1;s:19:"OpportunitiesModule";}'),
(978, 3, 1, '2016-01-10 17:29:44', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:19:"Consulting Services";i:1;s:19:"OpportunitiesModule";}'),
(979, 3, 1, '2016-01-10 17:34:36', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:19:"Consulting Services";i:1;s:19:"OpportunitiesModule";}'),
(980, 3, 1, '2016-01-10 17:35:17', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:19:"Consulting Services";i:1;s:19:"OpportunitiesModule";}'),
(981, 3, 1, '2016-01-10 17:40:44', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:19:"Consulting Services";i:1;s:19:"OpportunitiesModule";}'),
(982, 3, 1, '2016-01-10 17:43:23', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:19:"Consulting Services";i:1;s:19:"OpportunitiesModule";}'),
(983, 3, 1, '2016-01-10 17:44:10', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:19:"Consulting Services";i:1;s:19:"OpportunitiesModule";}'),
(984, 3, 1, '2016-01-10 17:44:22', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:19:"Consulting Services";i:1;s:19:"OpportunitiesModule";}'),
(985, 3, 1, '2016-01-10 17:44:46', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:19:"Consulting Services";i:1;s:19:"OpportunitiesModule";}'),
(986, 3, 1, '2016-01-10 17:45:08', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:19:"Consulting Services";i:1;s:19:"OpportunitiesModule";}'),
(987, 3, 1, '2016-01-10 17:46:24', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:19:"Consulting Services";i:1;s:19:"OpportunitiesModule";}'),
(988, 3, 1, '2016-01-10 17:46:49', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:19:"Consulting Services";i:1;s:19:"OpportunitiesModule";}'),
(989, 3, 1, '2016-01-10 17:47:45', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:19:"Consulting Services";i:1;s:19:"OpportunitiesModule";}'),
(990, 3, 1, '2016-01-10 17:50:23', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:19:"Consulting Services";i:1;s:19:"OpportunitiesModule";}'),
(991, 3, 1, '2016-01-10 17:51:44', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:19:"Consulting Services";i:1;s:19:"OpportunitiesModule";}'),
(992, 3, 1, '2016-01-10 17:51:54', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:19:"Consulting Services";i:1;s:19:"OpportunitiesModule";}'),
(993, 3, 1, '2016-01-10 17:55:30', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:19:"Consulting Services";i:1;s:19:"OpportunitiesModule";}'),
(994, 3, 1, '2016-01-10 18:01:20', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:19:"Consulting Services";i:1;s:19:"OpportunitiesModule";}'),
(995, 3, 1, '2016-01-10 18:03:59', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:19:"Consulting Services";i:1;s:19:"OpportunitiesModule";}'),
(996, 3, 1, '2016-01-10 18:06:20', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:19:"Consulting Services";i:1;s:19:"OpportunitiesModule";}'),
(997, 3, 1, '2016-01-10 18:06:37', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:19:"Consulting Services";i:1;s:19:"OpportunitiesModule";}'),
(998, 3, 1, '2016-01-10 18:07:03', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:19:"Consulting Services";i:1;s:19:"OpportunitiesModule";}'),
(999, 3, 1, '2016-01-10 18:07:34', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:19:"Consulting Services";i:1;s:19:"OpportunitiesModule";}'),
(1000, 3, 1, '2016-01-10 18:09:50', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:19:"Consulting Services";i:1;s:19:"OpportunitiesModule";}'),
(1001, 3, 1, '2016-01-10 18:10:29', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:19:"Consulting Services";i:1;s:19:"OpportunitiesModule";}'),
(1002, 8, 1, '2016-01-10 18:11:03', 'Item Created', 'ZurmoModule', 'Contract', 's:3:"wer";'),
(1003, 3, 1, '2016-01-10 18:11:08', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:19:"Consulting Services";i:1;s:19:"OpportunitiesModule";}'),
(1004, 5, 1, '2016-01-10 18:12:38', 'Item Viewed', 'ZurmoModule', 'Account', 'a:2:{i:0;s:14:"Allied Biscuit";i:1;s:14:"AccountsModule";}'),
(1005, 5, 1, '2016-01-10 18:12:47', 'Item Viewed', 'ZurmoModule', 'Account', 'a:2:{i:0;s:14:"Allied Biscuit";i:1;s:14:"AccountsModule";}'),
(1006, 5, 1, '2016-01-10 18:13:11', 'Item Viewed', 'ZurmoModule', 'Account', 'a:2:{i:0;s:14:"Allied Biscuit";i:1;s:14:"AccountsModule";}'),
(1007, 3, 1, '2016-01-10 18:32:16', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:19:"Consulting Services";i:1;s:19:"OpportunitiesModule";}'),
(1008, NULL, 1, '2016-01-10 18:41:46', 'User Logged In', 'UsersModule', NULL, 'N;'),
(1009, 3, 1, '2016-01-10 18:43:10', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:19:"Consulting Services";i:1;s:19:"OpportunitiesModule";}'),
(1010, NULL, 1, '2016-01-10 18:54:32', 'User Logged In', 'UsersModule', NULL, 'N;'),
(1011, 3, 1, '2016-01-10 18:54:50', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:19:"Consulting Services";i:1;s:19:"OpportunitiesModule";}'),
(1012, 15, 1, '2016-01-10 18:55:34', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:8:"test opp";i:1;s:19:"OpportunitiesModule";}'),
(1013, 9, 1, '2016-01-10 18:56:48', 'Item Created', 'ZurmoModule', 'Contract', 's:4:"asdf";'),
(1014, 15, 1, '2016-01-10 18:56:52', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:8:"test opp";i:1;s:19:"OpportunitiesModule";}'),
(1015, NULL, 1, '2016-01-11 05:30:25', 'User Logged In', 'UsersModule', NULL, 'N;'),
(1016, 9, 1, '2016-01-11 05:39:44', 'Item Viewed', 'ZurmoModule', 'Contract', 'a:2:{i:0;s:4:"asdf";i:1;s:15:"ContractsModule";}'),
(1017, 9, 1, '2016-01-11 05:55:25', 'Item Modified', 'ZurmoModule', 'Contract', 'a:4:{i:0;s:4:"asdf";i:1;a:2:{i:0;s:6:"amount";i:1;s:5:"value";}i:2;s:4:"2796";i:3;s:3:"264";}'),
(1018, 9, 1, '2016-01-11 05:55:25', 'Item Viewed', 'ZurmoModule', 'Contract', 'a:2:{i:0;s:4:"asdf";i:1;s:15:"ContractsModule";}'),
(1019, NULL, 1, '2016-01-11 06:56:53', 'User Logged In', 'UsersModule', NULL, 'N;'),
(1020, 9, 1, '2016-01-11 06:58:03', 'Item Created', 'ZurmoModule', 'Account', 's:16:"Test New Account";'),
(1021, 9, 1, '2016-01-11 06:58:04', 'Item Viewed', 'ZurmoModule', 'Account', 'a:2:{i:0;s:16:"Test New Account";i:1;s:14:"AccountsModule";}'),
(1022, 16, 1, '2016-01-11 06:58:45', 'Item Created', 'ZurmoModule', 'Opportunity', 's:20:"Test New opportunity";'),
(1023, 9, 1, '2016-01-11 06:58:46', 'Item Viewed', 'ZurmoModule', 'Account', 'a:2:{i:0;s:16:"Test New Account";i:1;s:14:"AccountsModule";}'),
(1024, 16, 1, '2016-01-11 06:59:01', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:20:"Test New opportunity";i:1;s:19:"OpportunitiesModule";}'),
(1025, 10, 1, '2016-01-11 06:59:32', 'Item Created', 'ZurmoModule', 'Contract', 's:17:"Test New contract";'),
(1026, 22, 1, '2016-01-11 06:59:33', 'Item Modified', 'ZurmoModule', 'GameBadge', 'a:4:{i:0;s:16:"CreateContract 3";i:1;a:1:{i:0;s:5:"grade";}i:2;s:1:"2";i:3;i:3;}'),
(1027, 16, 1, '2016-01-11 06:59:33', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:20:"Test New opportunity";i:1;s:19:"OpportunitiesModule";}'),
(1028, NULL, 1, '2016-01-11 16:15:03', 'User Logged In', 'UsersModule', NULL, 'N;'),
(1029, 15, 1, '2016-01-11 16:15:37', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:8:"test opp";i:1;s:19:"OpportunitiesModule";}'),
(1030, 11, 1, '2016-01-11 16:16:15', 'Item Created', 'ZurmoModule', 'Contract', 's:3:"tst";'),
(1031, 15, 1, '2016-01-11 16:16:20', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:8:"test opp";i:1;s:19:"OpportunitiesModule";}'),
(1032, NULL, 1, '2016-01-12 18:04:03', 'User Logged In', 'UsersModule', NULL, 'N;'),
(1033, 9, 1, '2016-01-12 18:04:42', 'Item Viewed', 'ZurmoModule', 'Contract', 'a:2:{i:0;s:4:"asdf";i:1;s:15:"ContractsModule";}'),
(1034, 5, 1, '2016-01-12 18:05:27', 'Item Viewed', 'ZurmoModule', 'Account', 'a:2:{i:0;s:14:"Allied Biscuit";i:1;s:14:"AccountsModule";}'),
(1035, 10, 1, '2016-01-12 18:05:52', 'Item Created', 'ZurmoModule', 'Account', 's:4:"VNYN";'),
(1036, 10, 1, '2016-01-12 18:05:52', 'Item Viewed', 'ZurmoModule', 'Account', 'a:2:{i:0;s:4:"VNYN";i:1;s:14:"AccountsModule";}'),
(1037, 17, 1, '2016-01-12 18:07:01', 'Item Created', 'ZurmoModule', 'Opportunity', 's:4:"Test";'),
(1038, 10, 1, '2016-01-12 18:07:02', 'Item Viewed', 'ZurmoModule', 'Account', 'a:2:{i:0;s:4:"VNYN";i:1;s:14:"AccountsModule";}'),
(1039, 5, 1, '2016-01-12 18:09:16', 'Item Viewed', 'ZurmoModule', 'Account', 'a:2:{i:0;s:14:"Allied Biscuit";i:1;s:14:"AccountsModule";}'),
(1040, 10, 1, '2016-01-12 18:09:53', 'Item Viewed', 'ZurmoModule', 'Account', 'a:2:{i:0;s:4:"VNYN";i:1;s:14:"AccountsModule";}'),
(1041, 17, 1, '2016-01-12 18:10:57', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:4:"Test";i:1;s:19:"OpportunitiesModule";}'),
(1042, 10, 1, '2016-01-12 18:11:07', 'Item Viewed', 'ZurmoModule', 'Account', 'a:2:{i:0;s:4:"VNYN";i:1;s:14:"AccountsModule";}'),
(1043, 10, 1, '2016-01-12 18:12:15', 'Item Viewed', 'ZurmoModule', 'Account', 'a:2:{i:0;s:4:"VNYN";i:1;s:14:"AccountsModule";}'),
(1044, 18, 1, '2016-01-12 18:13:10', 'Item Created', 'ZurmoModule', 'Opportunity', 's:6:"Test 2";'),
(1045, 27, 1, '2016-01-12 18:13:11', 'Item Modified', 'ZurmoModule', 'GameBadge', 'a:4:{i:0;s:19:"CreateOpportunity 2";i:1;a:1:{i:0;s:5:"grade";}i:2;s:1:"1";i:3;i:2;}'),
(1046, 10, 1, '2016-01-12 18:13:11', 'Item Viewed', 'ZurmoModule', 'Account', 'a:2:{i:0;s:4:"VNYN";i:1;s:14:"AccountsModule";}'),
(1047, 17, 1, '2016-01-12 18:13:24', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:4:"Test";i:1;s:19:"OpportunitiesModule";}'),
(1048, 17, 1, '2016-01-12 18:17:33', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:4:"Test";i:1;s:19:"OpportunitiesModule";}'),
(1049, 10, 1, '2016-01-12 18:18:16', 'Item Viewed', 'ZurmoModule', 'Account', 'a:2:{i:0;s:4:"VNYN";i:1;s:14:"AccountsModule";}'),
(1050, 17, 1, '2016-01-12 18:20:18', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:4:"Test";i:1;s:19:"OpportunitiesModule";}'),
(1051, 18, 1, '2016-01-12 18:20:47', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:6:"Test 2";i:1;s:19:"OpportunitiesModule";}'),
(1052, 18, 1, '2016-01-12 18:22:05', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:6:"Test 2";i:1;s:19:"OpportunitiesModule";}'),
(1053, 18, 1, '2016-01-12 18:36:25', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:6:"Test 2";i:1;s:19:"OpportunitiesModule";}'),
(1054, NULL, 1, '2016-01-12 18:39:08', 'User Logged Out', 'UsersModule', NULL, 'N;'),
(1055, NULL, 1, '2016-01-12 18:39:24', 'User Logged In', 'UsersModule', NULL, 'N;'),
(1056, 10, 1, '2016-01-12 18:39:35', 'Item Viewed', 'ZurmoModule', 'Account', 'a:2:{i:0;s:4:"VNYN";i:1;s:14:"AccountsModule";}'),
(1057, 18, 1, '2016-01-12 18:39:41', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:6:"Test 2";i:1;s:19:"OpportunitiesModule";}'),
(1058, 18, 1, '2016-01-12 18:40:24', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:6:"Test 2";i:1;s:19:"OpportunitiesModule";}'),
(1059, 10, 1, '2016-01-12 18:43:34', 'Item Viewed', 'ZurmoModule', 'Account', 'a:2:{i:0;s:4:"VNYN";i:1;s:14:"AccountsModule";}'),
(1060, 18, 1, '2016-01-12 18:44:11', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:6:"Test 2";i:1;s:19:"OpportunitiesModule";}'),
(1061, 18, 1, '2016-01-12 18:44:57', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:6:"Test 2";i:1;s:19:"OpportunitiesModule";}'),
(1062, NULL, 1, '2016-01-12 18:48:40', 'User Logged In', 'UsersModule', NULL, 'N;'),
(1063, 10, 1, '2016-01-12 18:48:52', 'Item Viewed', 'ZurmoModule', 'Account', 'a:2:{i:0;s:4:"VNYN";i:1;s:14:"AccountsModule";}'),
(1064, 17, 1, '2016-01-12 18:49:00', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:4:"Test";i:1;s:19:"OpportunitiesModule";}'),
(1065, NULL, 1, '2016-01-12 18:49:38', 'User Logged In', 'UsersModule', NULL, 'N;'),
(1066, 11, 1, '2016-01-12 18:50:56', 'Item Created', 'ZurmoModule', 'Account', 's:12:"Doral Estate";'),
(1067, 11, 1, '2016-01-12 18:50:56', 'Item Viewed', 'ZurmoModule', 'Account', 'a:2:{i:0;s:12:"Doral Estate";i:1;s:14:"AccountsModule";}'),
(1068, 1, 1, '2016-01-12 18:51:53', 'Item Created', 'ZurmoModule', 'AccountContactAffiliation', 's:27:"Doral Estate - Eric Riveron";'),
(1069, 31, 1, '2016-01-12 18:51:54', 'Item Created', 'ZurmoModule', 'Contact', 's:12:"Eric Riveron";'),
(1070, 21, 1, '2016-01-12 18:51:54', 'Item Created', 'ZurmoModule', 'GameLevel', 's:17:"AccountManagement";'),
(1071, 11, 1, '2016-01-12 18:51:54', 'Item Viewed', 'ZurmoModule', 'Account', 'a:2:{i:0;s:12:"Doral Estate";i:1;s:14:"AccountsModule";}'),
(1072, 18, 1, '2016-01-12 18:52:04', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:6:"Test 2";i:1;s:19:"OpportunitiesModule";}'),
(1073, 19, 1, '2016-01-12 18:53:08', 'Item Created', 'ZurmoModule', 'Opportunity', 's:12:"Tripple Bulk";'),
(1074, 11, 1, '2016-01-12 18:53:08', 'Item Viewed', 'ZurmoModule', 'Account', 'a:2:{i:0;s:12:"Doral Estate";i:1;s:14:"AccountsModule";}'),
(1075, 18, 1, '2016-01-12 18:55:08', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:6:"Test 2";i:1;s:19:"OpportunitiesModule";}'),
(1076, 11, 1, '2016-01-12 18:58:44', 'Item Viewed', 'ZurmoModule', 'Account', 'a:2:{i:0;s:12:"Doral Estate";i:1;s:14:"AccountsModule";}'),
(1077, 19, 1, '2016-01-12 18:58:57', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:12:"Tripple Bulk";i:1;s:19:"OpportunitiesModule";}'),
(1078, 11, 1, '2016-01-12 19:00:20', 'Item Viewed', 'ZurmoModule', 'Account', 'a:2:{i:0;s:12:"Doral Estate";i:1;s:14:"AccountsModule";}'),
(1079, 19, 1, '2016-01-12 19:00:51', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:12:"Tripple Bulk";i:1;s:19:"OpportunitiesModule";}'),
(1080, 2, 1, '2016-01-12 19:01:44', 'Item Viewed', 'ZurmoModule', 'SavedReport', 'a:2:{i:0;s:16:"New Leads Report";i:1;s:13:"ReportsModule";}'),
(1081, 11, 1, '2016-01-12 19:21:42', 'Item Viewed', 'ZurmoModule', 'Account', 'a:2:{i:0;s:12:"Doral Estate";i:1;s:14:"AccountsModule";}'),
(1082, 19, 1, '2016-01-12 19:21:47', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:12:"Tripple Bulk";i:1;s:19:"OpportunitiesModule";}'),
(1083, 11, 1, '2016-01-12 19:24:13', 'Item Viewed', 'ZurmoModule', 'Account', 'a:2:{i:0;s:12:"Doral Estate";i:1;s:14:"AccountsModule";}'),
(1084, 19, 1, '2016-01-12 19:24:16', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:12:"Tripple Bulk";i:1;s:19:"OpportunitiesModule";}'),
(1085, 19, 1, '2016-01-12 19:24:44', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:12:"Tripple Bulk";i:1;s:19:"OpportunitiesModule";}'),
(1086, 19, 1, '2016-01-12 19:25:29', 'Item Modified', 'ZurmoModule', 'Opportunity', 'a:4:{i:0;s:12:"Tripple Bulk";i:1;a:2:{i:0;s:6:"amount";i:1;s:5:"value";}i:2;s:4:"7500";i:3;s:6:"250000";}'),
(1087, 19, 1, '2016-01-12 19:25:29', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:12:"Tripple Bulk";i:1;s:19:"OpportunitiesModule";}'),
(1088, 19, 1, '2016-01-12 19:26:57', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:12:"Tripple Bulk";i:1;s:19:"OpportunitiesModule";}'),
(1089, 19, 1, '2016-01-12 19:30:19', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:12:"Tripple Bulk";i:1;s:19:"OpportunitiesModule";}'),
(1090, 19, 1, '2016-01-12 19:30:42', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:12:"Tripple Bulk";i:1;s:19:"OpportunitiesModule";}'),
(1091, 19, 1, '2016-01-12 19:34:55', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:12:"Tripple Bulk";i:1;s:19:"OpportunitiesModule";}'),
(1092, 19, 1, '2016-01-12 19:37:37', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:12:"Tripple Bulk";i:1;s:19:"OpportunitiesModule";}'),
(1093, 19, 1, '2016-01-12 19:38:03', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:12:"Tripple Bulk";i:1;s:19:"OpportunitiesModule";}'),
(1094, 18, 1, '2016-01-12 19:40:21', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:6:"Test 2";i:1;s:19:"OpportunitiesModule";}'),
(1095, 11, 1, '2016-01-12 20:23:56', 'Item Viewed', 'ZurmoModule', 'Account', 'a:2:{i:0;s:12:"Doral Estate";i:1;s:14:"AccountsModule";}'),
(1096, 19, 1, '2016-01-12 20:24:01', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:12:"Tripple Bulk";i:1;s:19:"OpportunitiesModule";}'),
(1097, 19, 1, '2016-01-13 14:48:06', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:12:"Tripple Bulk";i:1;s:19:"OpportunitiesModule";}'),
(1098, 11, 1, '2016-01-13 14:48:18', 'Item Viewed', 'ZurmoModule', 'Account', 'a:2:{i:0;s:12:"Doral Estate";i:1;s:14:"AccountsModule";}'),
(1099, 19, 1, '2016-01-13 14:48:22', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:12:"Tripple Bulk";i:1;s:19:"OpportunitiesModule";}'),
(1100, 19, 1, '2016-01-13 14:48:31', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:12:"Tripple Bulk";i:1;s:19:"OpportunitiesModule";}'),
(1101, NULL, 1, '2016-01-14 09:42:55', 'User Logged In', 'UsersModule', NULL, 'N;'),
(1102, 10, 1, '2016-01-14 09:43:07', 'Item Viewed', 'ZurmoModule', 'Contract', 'a:2:{i:0;s:17:"Test New contract";i:1;s:15:"ContractsModule";}'),
(1103, 10, 1, '2016-01-14 09:52:35', 'Item Viewed', 'ZurmoModule', 'Contract', 'a:2:{i:0;s:17:"Test New contract";i:1;s:15:"ContractsModule";}'),
(1104, NULL, 1, '2016-01-14 09:54:08', 'User Logged In', 'UsersModule', NULL, 'N;'),
(1105, 10, 1, '2016-01-14 09:54:17', 'Item Viewed', 'ZurmoModule', 'Contract', 'a:2:{i:0;s:17:"Test New contract";i:1;s:15:"ContractsModule";}'),
(1106, 10, 1, '2016-01-14 09:56:12', 'Item Viewed', 'ZurmoModule', 'Contract', 'a:2:{i:0;s:17:"Test New contract";i:1;s:15:"ContractsModule";}'),
(1107, 17, 1, '2016-01-14 09:56:28', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:4:"Test";i:1;s:19:"OpportunitiesModule";}'),
(1108, 12, 1, '2016-01-14 09:56:51', 'Item Created', 'ZurmoModule', 'Contract', 's:7:"test ff";'),
(1109, 17, 1, '2016-01-14 09:56:52', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:4:"Test";i:1;s:19:"OpportunitiesModule";}'),
(1110, NULL, 1, '2016-01-14 15:00:25', 'User Logged In', 'UsersModule', NULL, 'N;'),
(1111, 5, 1, '2016-01-14 15:00:40', 'Item Viewed', 'ZurmoModule', 'Account', 'a:2:{i:0;s:14:"Allied Biscuit";i:1;s:14:"AccountsModule";}'),
(1112, 2, 1, '2016-01-14 15:00:49', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:17:"Training Services";i:1;s:19:"OpportunitiesModule";}'),
(1113, NULL, 1, '2016-01-14 16:04:15', 'User Logged In', 'UsersModule', NULL, 'N;'),
(1114, 17, 1, '2016-01-14 16:06:23', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:4:"Test";i:1;s:19:"OpportunitiesModule";}'),
(1115, 17, 1, '2016-01-14 16:10:32', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:4:"Test";i:1;s:19:"OpportunitiesModule";}'),
(1116, NULL, 1, '2016-01-14 16:20:11', 'User Logged In', 'UsersModule', NULL, 'N;'),
(1117, 17, 1, '2016-01-14 16:20:30', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:4:"Test";i:1;s:19:"OpportunitiesModule";}'),
(1118, 2, 1, '2016-01-14 16:24:57', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:17:"Training Services";i:1;s:19:"OpportunitiesModule";}'),
(1119, NULL, 1, '2016-01-14 16:25:11', 'User Logged In', 'UsersModule', NULL, 'N;'),
(1120, 18, 1, '2016-01-14 16:25:11', 'Item Modified', 'ZurmoModule', 'GameBadge', 'a:4:{i:0;s:11:"LoginUser 4";i:1;a:1:{i:0;s:5:"grade";}i:2;s:1:"3";i:3;i:4;}'),
(1121, 10, 1, '2016-01-14 16:25:19', 'Item Viewed', 'ZurmoModule', 'Account', 'a:2:{i:0;s:4:"VNYN";i:1;s:14:"AccountsModule";}'),
(1122, 18, 1, '2016-01-14 16:25:25', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:6:"Test 2";i:1;s:19:"OpportunitiesModule";}'),
(1123, 18, 1, '2016-01-14 16:27:10', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:6:"Test 2";i:1;s:19:"OpportunitiesModule";}'),
(1124, NULL, 1, '2016-01-14 16:43:17', 'User Logged In', 'UsersModule', NULL, 'N;'),
(1125, 11, 1, '2016-01-14 16:43:33', 'Item Viewed', 'ZurmoModule', 'Account', 'a:2:{i:0;s:12:"Doral Estate";i:1;s:14:"AccountsModule";}'),
(1126, 19, 1, '2016-01-14 16:43:37', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:12:"Tripple Bulk";i:1;s:19:"OpportunitiesModule";}'),
(1127, 19, 1, '2016-01-14 16:44:14', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:12:"Tripple Bulk";i:1;s:19:"OpportunitiesModule";}'),
(1128, 19, 1, '2016-01-14 16:46:11', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:12:"Tripple Bulk";i:1;s:19:"OpportunitiesModule";}'),
(1129, 19, 1, '2016-01-14 16:46:32', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:12:"Tripple Bulk";i:1;s:19:"OpportunitiesModule";}'),
(1130, 11, 1, '2016-01-14 16:50:40', 'Item Viewed', 'ZurmoModule', 'Account', 'a:2:{i:0;s:12:"Doral Estate";i:1;s:14:"AccountsModule";}'),
(1131, 20, 1, '2016-01-14 16:51:21', 'Item Created', 'ZurmoModule', 'Opportunity', 's:11:"Double Bulk";'),
(1132, 11, 1, '2016-01-14 16:51:21', 'Item Viewed', 'ZurmoModule', 'Account', 'a:2:{i:0;s:12:"Doral Estate";i:1;s:14:"AccountsModule";}'),
(1133, 20, 1, '2016-01-14 16:51:26', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:11:"Double Bulk";i:1;s:19:"OpportunitiesModule";}'),
(1134, NULL, 1, '2016-01-14 17:07:10', 'User Logged In', 'UsersModule', NULL, 'N;'),
(1135, 17, 1, '2016-01-14 17:07:41', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:4:"Test";i:1;s:19:"OpportunitiesModule";}'),
(1136, 17, 1, '2016-01-14 17:08:24', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:4:"Test";i:1;s:19:"OpportunitiesModule";}'),
(1137, 3, 1, '2016-01-14 17:09:46', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:19:"Consulting Services";i:1;s:19:"OpportunitiesModule";}'),
(1138, 12, 1, '2016-01-14 17:09:47', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:24:"Cross Country Shipments2";i:1;s:19:"OpportunitiesModule";}'),
(1139, 8, 1, '2016-01-14 17:09:48', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:21:"Design Review Service";i:1;s:19:"OpportunitiesModule";}'),
(1140, 20, 1, '2016-01-14 17:09:50', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:11:"Double Bulk";i:1;s:19:"OpportunitiesModule";}'),
(1141, 6, 1, '2016-01-14 17:09:53', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:19:"Enterprise Software";i:1;s:19:"OpportunitiesModule";}'),
(1142, 4, 1, '2016-01-14 17:10:18', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:22:"Open Source Consulting";i:1;s:19:"OpportunitiesModule";}'),
(1143, 5, 1, '2016-01-14 17:10:19', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:22:"Open Source Consulting";i:1;s:19:"OpportunitiesModule";}'),
(1144, 11, 1, '2016-01-14 17:10:20', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:26:"Expensive Software Product";i:1;s:19:"OpportunitiesModule";}'),
(1145, 10, 1, '2016-01-14 17:10:21', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:26:"Expensive Software Product";i:1;s:19:"OpportunitiesModule";}'),
(1146, 4, 1, '2016-01-14 17:10:24', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:22:"Open Source Consulting";i:1;s:19:"OpportunitiesModule";}'),
(1147, 5, 1, '2016-01-14 17:10:26', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:22:"Open Source Consulting";i:1;s:19:"OpportunitiesModule";}'),
(1148, 18, 1, '2016-01-14 17:11:11', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:6:"Test 2";i:1;s:19:"OpportunitiesModule";}'),
(1149, 16, 1, '2016-01-14 17:11:12', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:20:"Test New opportunity";i:1;s:19:"OpportunitiesModule";}'),
(1150, 15, 1, '2016-01-14 17:11:13', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:8:"test opp";i:1;s:19:"OpportunitiesModule";}'),
(1151, 14, 1, '2016-01-14 17:11:15', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:8:"test sss";i:1;s:19:"OpportunitiesModule";}'),
(1152, 2, 1, '2016-01-14 17:11:16', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:17:"Training Services";i:1;s:19:"OpportunitiesModule";}'),
(1153, 9, 1, '2016-01-14 17:11:17', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:17:"Training Services";i:1;s:19:"OpportunitiesModule";}'),
(1154, 7, 1, '2016-01-14 17:11:18', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:14:"Wonder Widgets";i:1;s:19:"OpportunitiesModule";}'),
(1155, 19, 1, '2016-01-14 17:11:19', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:12:"Tripple Bulk";i:1;s:19:"OpportunitiesModule";}'),
(1156, 13, 1, '2016-01-14 17:11:21', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:14:"Wonder Widgets";i:1;s:19:"OpportunitiesModule";}'),
(1157, 7, 1, '2016-01-14 17:12:33', 'Item Viewed', 'ZurmoModule', 'Account', 'a:2:{i:0;s:17:"Wayne Enterprises";i:1;s:14:"AccountsModule";}'),
(1158, 10, 1, '2016-01-14 17:13:04', 'Item Viewed', 'ZurmoModule', 'Account', 'a:2:{i:0;s:4:"VNYN";i:1;s:14:"AccountsModule";}'),
(1159, 11, 1, '2016-01-14 17:13:34', 'Item Viewed', 'ZurmoModule', 'Account', 'a:2:{i:0;s:12:"Doral Estate";i:1;s:14:"AccountsModule";}'),
(1160, 19, 1, '2016-01-14 19:55:17', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:12:"Tripple Bulk";i:1;s:19:"OpportunitiesModule";}'),
(1161, 19, 1, '2016-01-14 22:40:07', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:12:"Tripple Bulk";i:1;s:19:"OpportunitiesModule";}'),
(1162, 19, 1, '2016-01-14 22:40:11', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:12:"Tripple Bulk";i:1;s:19:"OpportunitiesModule";}'),
(1163, 19, 1, '2016-01-15 13:58:09', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:12:"Tripple Bulk";i:1;s:19:"OpportunitiesModule";}'),
(1164, 10, 1, '2016-01-15 14:00:50', 'Item Viewed', 'ZurmoModule', 'Account', 'a:2:{i:0;s:4:"VNYN";i:1;s:14:"AccountsModule";}'),
(1165, 12, 1, '2016-01-15 14:01:42', 'Item Created', 'ZurmoModule', 'Account', 's:13:"Garden Estate";'),
(1166, 12, 1, '2016-01-15 14:01:42', 'Item Viewed', 'ZurmoModule', 'Account', 'a:2:{i:0;s:13:"Garden Estate";i:1;s:14:"AccountsModule";}'),
(1167, 21, 1, '2016-01-15 14:02:45', 'Item Created', 'ZurmoModule', 'Opportunity', 's:12:"Tripple Bulk";'),
(1168, 12, 1, '2016-01-15 14:02:45', 'Item Viewed', 'ZurmoModule', 'Account', 'a:2:{i:0;s:13:"Garden Estate";i:1;s:14:"AccountsModule";}'),
(1169, 10, 1, '2016-01-15 14:02:59', 'Item Viewed', 'ZurmoModule', 'Account', 'a:2:{i:0;s:4:"VNYN";i:1;s:14:"AccountsModule";}'),
(1170, 10, 1, '2016-01-15 14:03:29', 'Item Viewed', 'ZurmoModule', 'Account', 'a:2:{i:0;s:4:"VNYN";i:1;s:14:"AccountsModule";}'),
(1171, 17, 1, '2016-01-15 14:03:35', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:4:"Test";i:1;s:19:"OpportunitiesModule";}'),
(1172, 21, 1, '2016-01-15 14:03:36', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:12:"Tripple Bulk";i:1;s:19:"OpportunitiesModule";}'),
(1173, 21, 1, '2016-01-15 14:04:40', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:12:"Tripple Bulk";i:1;s:19:"OpportunitiesModule";}'),
(1174, 21, 1, '2016-01-15 14:06:12', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:12:"Tripple Bulk";i:1;s:19:"OpportunitiesModule";}'),
(1175, 21, 1, '2016-01-15 14:07:16', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:12:"Tripple Bulk";i:1;s:19:"OpportunitiesModule";}'),
(1176, 12, 1, '2016-01-15 14:07:39', 'Item Viewed', 'ZurmoModule', 'Account', 'a:2:{i:0;s:13:"Garden Estate";i:1;s:14:"AccountsModule";}'),
(1177, 12, 1, '2016-01-15 14:07:48', 'Item Viewed', 'ZurmoModule', 'Account', 'a:2:{i:0;s:13:"Garden Estate";i:1;s:14:"AccountsModule";}'),
(1178, 21, 1, '2016-01-15 14:07:56', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:12:"Tripple Bulk";i:1;s:19:"OpportunitiesModule";}'),
(1179, 21, 1, '2016-01-15 14:08:22', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:12:"Tripple Bulk";i:1;s:19:"OpportunitiesModule";}'),
(1180, 20, 1, '2016-01-15 14:10:35', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:11:"Double Bulk";i:1;s:19:"OpportunitiesModule";}'),
(1181, 5, 1, '2016-01-15 14:12:12', 'Item Viewed', 'ZurmoModule', 'Account', 'a:2:{i:0;s:14:"Allied Biscuit";i:1;s:14:"AccountsModule";}'),
(1182, NULL, 1, '2016-01-15 15:32:07', 'User Logged In', 'UsersModule', NULL, 'N;'),
(1183, 21, 1, '2016-01-15 15:32:32', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:12:"Tripple Bulk";i:1;s:19:"OpportunitiesModule";}'),
(1184, 19, 1, '2016-01-15 15:32:35', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:12:"Tripple Bulk";i:1;s:19:"OpportunitiesModule";}'),
(1185, 7, 1, '2016-01-15 15:33:03', 'Item Viewed', 'ZurmoModule', 'Account', 'a:2:{i:0;s:17:"Wayne Enterprises";i:1;s:14:"AccountsModule";}'),
(1186, 19, 1, '2016-01-15 15:33:23', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:12:"Tripple Bulk";i:1;s:19:"OpportunitiesModule";}'),
(1187, 11, 1, '2016-01-15 15:33:36', 'Item Viewed', 'ZurmoModule', 'Account', 'a:2:{i:0;s:12:"Doral Estate";i:1;s:14:"AccountsModule";}'),
(1188, 19, 1, '2016-01-15 15:33:50', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:12:"Tripple Bulk";i:1;s:19:"OpportunitiesModule";}'),
(1189, 19, 1, '2016-01-15 15:41:21', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:12:"Tripple Bulk";i:1;s:19:"OpportunitiesModule";}'),
(1190, 19, 1, '2016-01-15 15:41:54', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:12:"Tripple Bulk";i:1;s:19:"OpportunitiesModule";}'),
(1191, NULL, 1, '2016-01-15 15:46:17', 'User Logged In', 'UsersModule', NULL, 'N;'),
(1192, 19, 1, '2016-01-15 15:46:36', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:12:"Tripple Bulk";i:1;s:19:"OpportunitiesModule";}'),
(1193, NULL, 1, '2016-01-15 15:49:26', 'User Logged In', 'UsersModule', NULL, 'N;'),
(1194, 19, 1, '2016-01-15 15:49:49', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:12:"Tripple Bulk";i:1;s:19:"OpportunitiesModule";}'),
(1195, 10, 1, '2016-01-15 16:01:18', 'Item Viewed', 'ZurmoModule', 'Contract', 'a:2:{i:0;s:17:"Test New contract";i:1;s:15:"ContractsModule";}'),
(1196, 19, 1, '2016-01-15 18:41:51', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:12:"Tripple Bulk";i:1;s:19:"OpportunitiesModule";}'),
(1197, NULL, 1, '2016-01-15 18:42:01', 'User Logged In', 'UsersModule', NULL, 'N;'),
(1198, 20, 1, '2016-01-15 18:42:18', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:11:"Double Bulk";i:1;s:19:"OpportunitiesModule";}'),
(1199, 11, 1, '2016-01-15 18:43:27', 'Item Viewed', 'ZurmoModule', 'Account', 'a:2:{i:0;s:12:"Doral Estate";i:1;s:14:"AccountsModule";}'),
(1200, 19, 1, '2016-01-15 18:43:33', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:12:"Tripple Bulk";i:1;s:19:"OpportunitiesModule";}'),
(1201, 1, 1, '2016-01-15 18:48:18', 'Item Created', 'ZurmoModule', 'FileModel', 's:9:"logo1.png";'),
(1202, 2, 1, '2016-01-15 18:48:18', 'Item Created', 'ZurmoModule', 'FileModel', 's:9:"logo1.png";'),
(1203, 4, 1, '2016-01-15 18:51:41', 'Item Viewed', 'ZurmoModule', 'MarketingList', 'a:2:{i:0;s:7:"Clients";i:1;s:20:"MarketingListsModule";}'),
(1204, 3, 1, '2016-01-15 18:52:04', 'Item Viewed', 'ZurmoModule', 'EmailTemplate', 'a:2:{i:0;s:8:"Discount";i:1;s:20:"EmailTemplatesModule";}'),
(1205, 2, 1, '2016-01-15 18:52:31', 'Item Viewed', 'ZurmoModule', 'Campaign', 'a:2:{i:0;s:28:"10% discount for new clients";i:1;s:15:"CampaignsModule";}'),
(1206, NULL, 1, '2016-01-15 19:41:37', 'User Logged In', 'UsersModule', NULL, 'N;'),
(1207, 5, 1, '2016-01-15 19:41:58', 'Item Deleted', 'ZurmoModule', 'Account', 's:14:"Allied Biscuit";'),
(1208, 3, 1, '2016-01-15 19:41:58', 'Item Deleted', 'ZurmoModule', 'Account', 's:23:"Big T Burgers and Fries";'),
(1209, 11, 1, '2016-01-15 19:41:58', 'Item Deleted', 'ZurmoModule', 'Account', 's:12:"Doral Estate";'),
(1210, 12, 1, '2016-01-15 19:41:58', 'Item Deleted', 'ZurmoModule', 'Account', 's:13:"Garden Estate";'),
(1211, 6, 1, '2016-01-15 19:41:58', 'Item Deleted', 'ZurmoModule', 'Account', 's:10:"Globo-Chem";'),
(1212, 7, 1, '2016-01-15 19:42:00', 'Item Deleted', 'ZurmoModule', 'Account', 's:17:"Wayne Enterprises";'),
(1213, 2, 1, '2016-01-15 19:42:01', 'Item Deleted', 'ZurmoModule', 'Account', 's:9:"Gringotts";'),
(1214, 4, 1, '2016-01-15 19:42:01', 'Item Deleted', 'ZurmoModule', 'Account', 's:12:"Sample, Inc.";'),
(1215, 8, 1, '2016-01-15 19:42:01', 'Item Deleted', 'ZurmoModule', 'Account', 's:12:"Test account";'),
(1216, 9, 1, '2016-01-15 19:42:01', 'Item Deleted', 'ZurmoModule', 'Account', 's:16:"Test New Account";'),
(1217, 10, 1, '2016-01-15 19:42:01', 'Item Deleted', 'ZurmoModule', 'Account', 's:4:"VNYN";'),
(1218, 1, 1, '2016-01-15 19:42:22', 'Item Created', 'ZurmoModule', 'Import', 's:9:"(Unnamed)";'),
(1219, 13, 1, '2016-01-15 19:44:43', 'Item Created', 'ZurmoModule', 'Account', 's:18:"Strada 315 (Video)";'),
(1220, 14, 1, '2016-01-15 19:44:43', 'Item Created', 'ZurmoModule', 'Account', 's:17:"Strada 315 (Data)";'),
(1221, 15, 1, '2016-01-15 19:44:43', 'Item Created', 'ZurmoModule', 'Account', 's:17:"Sunset Bay (Data)";'),
(1222, 16, 1, '2016-01-15 19:44:43', 'Item Created', 'ZurmoModule', 'Account', 's:18:"Sunset Bay (Video)";'),
(1223, 17, 1, '2016-01-15 19:44:43', 'Item Created', 'ZurmoModule', 'Account', 's:14:"Cypress Trails";'),
(1224, 18, 1, '2016-01-15 19:44:43', 'Item Created', 'ZurmoModule', 'Account', 's:18:"Isles at Grand Bay";'),
(1225, 19, 1, '2016-01-15 19:44:43', 'Item Created', 'ZurmoModule', 'Account', 's:16:"The Summit (Net)";'),
(1226, 20, 1, '2016-01-15 19:44:43', 'Item Created', 'ZurmoModule', 'Account', 's:9:"Key Largo";'),
(1227, 21, 1, '2016-01-15 19:44:43', 'Item Created', 'ZurmoModule', 'Account', 's:20:"Garden Estates (Net)";'),
(1228, 22, 1, '2016-01-15 19:44:43', 'Item Created', 'ZurmoModule', 'Account', 's:6:"Aventi";'),
(1229, 23, 1, '2016-01-15 19:44:43', 'Item Created', 'ZurmoModule', 'Account', 's:16:"Kenilworth (Net)";'),
(1230, 24, 1, '2016-01-15 19:44:43', 'Item Created', 'ZurmoModule', 'Account', 's:22:"400 Association (Data)";'),
(1231, 25, 1, '2016-01-15 19:44:43', 'Item Created', 'ZurmoModule', 'Account', 's:20:"Marina Village (Net)";'),
(1232, 26, 1, '2016-01-15 19:44:43', 'Item Created', 'ZurmoModule', 'Account', 's:13:"Tropic Harbor";'),
(1233, 27, 1, '2016-01-15 19:44:43', 'Item Created', 'ZurmoModule', 'Account', 's:13:"Midtown Doral";'),
(1234, 28, 1, '2016-01-15 19:44:43', 'Item Created', 'ZurmoModule', 'Account', 's:14:"Midtown Retail";'),
(1235, 29, 1, '2016-01-15 19:44:43', 'Item Created', 'ZurmoModule', 'Account', 's:15:"Meadowbrook # 4";'),
(1236, 30, 1, '2016-01-15 19:44:43', 'Item Created', 'ZurmoModule', 'Account', 's:12:"Parker Plaza";'),
(1237, 31, 1, '2016-01-15 19:44:43', 'Item Created', 'ZurmoModule', 'Account', 's:11:"Topaz North";'),
(1238, 32, 1, '2016-01-15 19:44:43', 'Item Created', 'ZurmoModule', 'Account', 's:19:"Northern Star (Net)";'),
(1239, 33, 1, '2016-01-15 19:44:43', 'Item Created', 'ZurmoModule', 'Account', 's:13:"Emerald (Net)";'),
(1240, 34, 1, '2016-01-15 19:44:44', 'Item Created', 'ZurmoModule', 'Account', 's:15:"Cloisters (Net)";'),
(1241, 35, 1, '2016-01-15 19:44:44', 'Item Created', 'ZurmoModule', 'Account', 's:10:"3360 Condo";'),
(1242, 36, 1, '2016-01-15 19:44:44', 'Item Created', 'ZurmoModule', 'Account', 's:17:"Lake Worth Towers";'),
(1243, 37, 1, '2016-01-15 19:44:44', 'Item Created', 'ZurmoModule', 'Account', 's:16:"Point East Condo";'),
(1244, 38, 1, '2016-01-15 19:44:44', 'Item Created', 'ZurmoModule', 'Account', 's:16:"Pine Ridge Condo";'),
(1245, 39, 1, '2016-01-15 19:44:44', 'Item Created', 'ZurmoModule', 'Account', 's:17:"Christopher House";'),
(1246, 40, 1, '2016-01-15 19:44:44', 'Item Created', 'ZurmoModule', 'Account', 's:48:"The Residences on Hollywood Beach Proposal (Net)";'),
(1247, 41, 1, '2016-01-15 19:44:44', 'Item Created', 'ZurmoModule', 'Account', 's:20:"Pinehurst Club (Net)";'),
(1248, 42, 1, '2016-01-15 19:44:44', 'Item Created', 'ZurmoModule', 'Account', 's:13:"Harbour House";'),
(1249, 43, 1, '2016-01-15 19:44:44', 'Item Created', 'ZurmoModule', 'Account', 's:12:"Mystic Point";'),
(1250, 44, 1, '2016-01-15 19:44:44', 'Item Created', 'ZurmoModule', 'Account', 's:25:"Glades Country Club (Net)";'),
(1251, 45, 1, '2016-01-15 19:44:44', 'Item Created', 'ZurmoModule', 'Account', 's:14:"9 Island (Net)";'),
(1252, 46, 1, '2016-01-15 19:44:44', 'Item Created', 'ZurmoModule', 'Account', 's:13:"Seamark (Net)";'),
(1253, 47, 1, '2016-01-15 19:44:44', 'Item Created', 'ZurmoModule', 'Account', 's:14:"Balmoral Condo";'),
(1254, 48, 1, '2016-01-15 19:44:44', 'Item Created', 'ZurmoModule', 'Account', 's:7:"Artesia";'),
(1255, 49, 1, '2016-01-15 19:44:44', 'Item Created', 'ZurmoModule', 'Account', 's:19:"Mayfair House Condo";'),
(1256, 50, 1, '2016-01-15 19:44:44', 'Item Created', 'ZurmoModule', 'Account', 's:15:"OceanView Place";'),
(1257, 51, 1, '2016-01-15 19:44:44', 'Item Created', 'ZurmoModule', 'Account', 's:12:"River Bridge";'),
(1258, 52, 1, '2016-01-15 19:44:44', 'Item Created', 'ZurmoModule', 'Account', 's:11:"Ocean Place";'),
(1259, 53, 1, '2016-01-15 19:44:44', 'Item Created', 'ZurmoModule', 'Account', 's:29:"The Tides @ Bridgeside Square";'),
(1260, 54, 1, '2016-01-15 19:44:44', 'Item Created', 'ZurmoModule', 'Account', 's:9:"OakBridge";'),
(1261, 55, 1, '2016-01-15 19:44:44', 'Item Created', 'ZurmoModule', 'Account', 's:30:"Sand Pebble Beach Condominiums";'),
(1262, 56, 1, '2016-01-15 19:44:44', 'Item Created', 'ZurmoModule', 'Account', 's:11:"The Atriums";'),
(1263, 57, 1, '2016-01-15 19:44:45', 'Item Created', 'ZurmoModule', 'Account', 's:20:"Plaza of Bal Harbour";'),
(1264, 58, 1, '2016-01-15 19:44:45', 'Item Created', 'ZurmoModule', 'Account', 's:14:"Nirvana Condos";'),
(1265, 59, 1, '2016-01-15 19:44:45', 'Item Created', 'ZurmoModule', 'Account', 's:15:"Commodore Plaza";'),
(1266, 60, 1, '2016-01-15 19:44:45', 'Item Created', 'ZurmoModule', 'Account', 's:19:"Fairways of Tamarac";'),
(1267, 61, 1, '2016-01-15 19:44:45', 'Item Created', 'ZurmoModule', 'Account', 's:29:"Patrician of the Palm Beaches";'),
(1268, 62, 1, '2016-01-15 19:44:45', 'Item Created', 'ZurmoModule', 'Account', 's:21:"Alexander Hotel/Condo";'),
(1269, 63, 1, '2016-01-15 19:44:46', 'Item Created', 'ZurmoModule', 'Account', 's:10:"Las Verdes";'),
(1270, 64, 1, '2016-01-15 19:44:46', 'Item Created', 'ZurmoModule', 'Account', 's:17:"Lakes of Savannah";'),
(1271, 65, 1, '2016-01-15 19:44:46', 'Item Created', 'ZurmoModule', 'Account', 's:18:"East Pointe Towers";'),
(1272, 66, 1, '2016-01-15 19:44:46', 'Item Created', 'ZurmoModule', 'Account', 's:15:"Bravura 1 Condo";'),
(1273, 67, 1, '2016-01-15 19:44:46', 'Item Created', 'ZurmoModule', 'Account', 's:22:"TOWERS OF KENDAL LAKES";'),
(1274, 68, 1, '2016-01-15 19:44:46', 'Item Created', 'ZurmoModule', 'Account', 's:20:"Commodore Club South";'),
(1275, 69, 1, '2016-01-15 19:44:46', 'Item Created', 'ZurmoModule', 'Account', 's:16:"Oceanfront Plaza";'),
(1276, 70, 1, '2016-01-15 19:44:46', 'Item Created', 'ZurmoModule', 'Account', 's:14:"Hillsboro Cove";'),
(1277, 35, 1, '2016-01-15 19:44:47', 'Item Created', 'ZurmoModule', 'GameScore', 's:13:"ImportAccount";'),
(1278, 36, 1, '2016-01-15 19:46:00', 'Item Created', 'ZurmoModule', 'GameScore', 's:13:"SearchAccount";'),
(1279, 28, 1, '2016-01-15 19:46:00', 'Item Created', 'ZurmoModule', 'GameBadge', 's:16:"SearchAccounts 1";'),
(1280, 3, 1, '2016-01-15 19:46:44', 'Item Deleted', 'ZurmoModule', 'Opportunity', 's:19:"Consulting Services";'),
(1281, 12, 1, '2016-01-15 19:46:44', 'Item Deleted', 'ZurmoModule', 'Opportunity', 's:24:"Cross Country Shipments2";'),
(1282, 8, 1, '2016-01-15 19:46:44', 'Item Deleted', 'ZurmoModule', 'Opportunity', 's:21:"Design Review Service";'),
(1283, 20, 1, '2016-01-15 19:46:44', 'Item Deleted', 'ZurmoModule', 'Opportunity', 's:11:"Double Bulk";'),
(1284, 6, 1, '2016-01-15 19:46:44', 'Item Deleted', 'ZurmoModule', 'Opportunity', 's:19:"Enterprise Software";'),
(1285, 18, 1, '2016-01-15 19:46:46', 'Item Deleted', 'ZurmoModule', 'Opportunity', 's:6:"Test 2";'),
(1286, 16, 1, '2016-01-15 19:46:46', 'Item Deleted', 'ZurmoModule', 'Opportunity', 's:20:"Test New opportunity";'),
(1287, 15, 1, '2016-01-15 19:46:46', 'Item Deleted', 'ZurmoModule', 'Opportunity', 's:8:"test opp";'),
(1288, 14, 1, '2016-01-15 19:46:46', 'Item Deleted', 'ZurmoModule', 'Opportunity', 's:8:"test sss";'),
(1289, 2, 1, '2016-01-15 19:46:46', 'Item Deleted', 'ZurmoModule', 'Opportunity', 's:17:"Training Services";'),
(1290, 9, 1, '2016-01-15 19:46:48', 'Item Deleted', 'ZurmoModule', 'Opportunity', 's:17:"Training Services";'),
(1291, 19, 1, '2016-01-15 19:46:48', 'Item Deleted', 'ZurmoModule', 'Opportunity', 's:12:"Tripple Bulk";'),
(1292, 21, 1, '2016-01-15 19:46:48', 'Item Deleted', 'ZurmoModule', 'Opportunity', 's:12:"Tripple Bulk";'),
(1293, 7, 1, '2016-01-15 19:46:48', 'Item Deleted', 'ZurmoModule', 'Opportunity', 's:14:"Wonder Widgets";'),
(1294, 13, 1, '2016-01-15 19:46:48', 'Item Deleted', 'ZurmoModule', 'Opportunity', 's:14:"Wonder Widgets";'),
(1295, 10, 1, '2016-01-15 19:46:49', 'Item Deleted', 'ZurmoModule', 'Opportunity', 's:26:"Expensive Software Product";'),
(1296, 11, 1, '2016-01-15 19:46:49', 'Item Deleted', 'ZurmoModule', 'Opportunity', 's:26:"Expensive Software Product";'),
(1297, 4, 1, '2016-01-15 19:46:49', 'Item Deleted', 'ZurmoModule', 'Opportunity', 's:22:"Open Source Consulting";'),
(1298, 5, 1, '2016-01-15 19:46:49', 'Item Deleted', 'ZurmoModule', 'Opportunity', 's:22:"Open Source Consulting";'),
(1299, 17, 1, '2016-01-15 19:46:49', 'Item Deleted', 'ZurmoModule', 'Opportunity', 's:4:"Test";'),
(1300, NULL, 1, '2016-01-15 21:01:28', 'User Logged In', 'UsersModule', NULL, 'N;'),
(1301, 22, 1, '2016-01-15 21:01:50', 'Item Viewed', 'ZurmoModule', 'Account', 'a:2:{i:0;s:6:"Aventi";i:1;s:14:"AccountsModule";}'),
(1302, 3, 1, '2016-01-15 21:02:49', 'Item Viewed', 'ZurmoModule', 'SavedReport', 'a:2:{i:0;s:26:"Active Customer Email List";i:1;s:13:"ReportsModule";}'),
(1303, 69, 1, '2016-01-15 21:09:57', 'Item Viewed', 'ZurmoModule', 'Account', 'a:2:{i:0;s:16:"Oceanfront Plaza";i:1;s:14:"AccountsModule";}'),
(1304, 35, 1, '2016-01-15 21:40:09', 'Item Viewed', 'ZurmoModule', 'Account', 'a:2:{i:0;s:10:"3360 Condo";i:1;s:14:"AccountsModule";}'),
(1305, 22, 1, '2016-01-15 21:47:31', 'Item Created', 'ZurmoModule', 'Opportunity', 's:10:"3360 Condo";'),
(1306, 35, 1, '2016-01-15 21:47:32', 'Item Viewed', 'ZurmoModule', 'Account', 'a:2:{i:0;s:10:"3360 Condo";i:1;s:14:"AccountsModule";}'),
(1307, 22, 1, '2016-01-15 21:49:51', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:10:"3360 Condo";i:1;s:19:"OpportunitiesModule";}'),
(1308, 22, 1, '2016-01-15 21:50:10', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:10:"3360 Condo";i:1;s:19:"OpportunitiesModule";}'),
(1309, 22, 1, '2016-01-15 21:52:38', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:10:"3360 Condo";i:1;s:19:"OpportunitiesModule";}'),
(1310, 2, 1, '2016-01-15 21:56:55', 'Item Created', 'ZurmoModule', 'Import', 's:9:"(Unnamed)";'),
(1311, 24, 1, '2016-01-15 22:13:23', 'Item Viewed', 'ZurmoModule', 'Account', 'a:2:{i:0;s:22:"400 Association (Data)";i:1;s:14:"AccountsModule";}'),
(1312, 23, 1, '2016-01-15 22:13:58', 'Item Created', 'ZurmoModule', 'Opportunity', 's:22:"400 Association (Data)";'),
(1313, 24, 1, '2016-01-15 22:13:58', 'Item Created', 'ZurmoModule', 'Opportunity', 's:14:"9 Island (Net)";'),
(1314, 25, 1, '2016-01-15 22:13:58', 'Item Created', 'ZurmoModule', 'Opportunity', 's:21:"Alexander Hotel/Condo";'),
(1315, 26, 1, '2016-01-15 22:13:58', 'Item Created', 'ZurmoModule', 'Opportunity', 's:7:"Artesia";'),
(1316, 27, 1, '2016-01-15 22:13:58', 'Item Created', 'ZurmoModule', 'Opportunity', 's:6:"Aventi";'),
(1317, 28, 1, '2016-01-15 22:13:58', 'Item Created', 'ZurmoModule', 'Opportunity', 's:14:"Balmoral Condo";'),
(1318, 29, 1, '2016-01-15 22:13:58', 'Item Created', 'ZurmoModule', 'Opportunity', 's:15:"Bravura 1 Condo";'),
(1319, 30, 1, '2016-01-15 22:13:58', 'Item Created', 'ZurmoModule', 'Opportunity', 's:17:"Christopher House";'),
(1320, 31, 1, '2016-01-15 22:13:58', 'Item Created', 'ZurmoModule', 'Opportunity', 's:15:"Cloisters (Net)";'),
(1321, 32, 1, '2016-01-15 22:13:58', 'Item Created', 'ZurmoModule', 'Opportunity', 's:20:"Commodore Club South";'),
(1322, 33, 1, '2016-01-15 22:13:58', 'Item Created', 'ZurmoModule', 'Opportunity', 's:15:"Commodore Plaza";'),
(1323, 34, 1, '2016-01-15 22:13:58', 'Item Created', 'ZurmoModule', 'Opportunity', 's:14:"Cypress Trails";'),
(1324, 35, 1, '2016-01-15 22:13:58', 'Item Created', 'ZurmoModule', 'Opportunity', 's:18:"East Pointe Towers";'),
(1325, 36, 1, '2016-01-15 22:13:58', 'Item Created', 'ZurmoModule', 'Opportunity', 's:13:"Emerald (Net)";'),
(1326, 37, 1, '2016-01-15 22:13:58', 'Item Created', 'ZurmoModule', 'Opportunity', 's:19:"Fairways of Tamarac";'),
(1327, 38, 1, '2016-01-15 22:13:59', 'Item Created', 'ZurmoModule', 'Opportunity', 's:20:"Garden Estates (Net)";'),
(1328, 39, 1, '2016-01-15 22:13:59', 'Item Created', 'ZurmoModule', 'Opportunity', 's:25:"Glades Country Club (Net)";'),
(1329, 40, 1, '2016-01-15 22:13:59', 'Item Created', 'ZurmoModule', 'Opportunity', 's:13:"Harbour House";'),
(1330, 41, 1, '2016-01-15 22:13:59', 'Item Created', 'ZurmoModule', 'Opportunity', 's:14:"Hillsboro Cove";');
INSERT INTO `auditevent` (`id`, `modelid`, `_user_id`, `datetime`, `eventname`, `modulename`, `modelclassname`, `serializeddata`) VALUES
(1331, 42, 1, '2016-01-15 22:13:59', 'Item Created', 'ZurmoModule', 'Opportunity', 's:18:"Isles at Grand Bay";'),
(1332, 43, 1, '2016-01-15 22:13:59', 'Item Created', 'ZurmoModule', 'Opportunity', 's:16:"Kenilworth (Net)";'),
(1333, 44, 1, '2016-01-15 22:13:59', 'Item Created', 'ZurmoModule', 'Opportunity', 's:9:"Key Largo";'),
(1334, 45, 1, '2016-01-15 22:13:59', 'Item Created', 'ZurmoModule', 'Opportunity', 's:17:"Lake Worth Towers";'),
(1335, 46, 1, '2016-01-15 22:13:59', 'Item Created', 'ZurmoModule', 'Opportunity', 's:17:"Lakes of Savannah";'),
(1336, 47, 1, '2016-01-15 22:13:59', 'Item Created', 'ZurmoModule', 'Opportunity', 's:10:"Las Verdes";'),
(1337, 48, 1, '2016-01-15 22:13:59', 'Item Created', 'ZurmoModule', 'Opportunity', 's:20:"Marina Village (Net)";'),
(1338, 49, 1, '2016-01-15 22:13:59', 'Item Created', 'ZurmoModule', 'Opportunity', 's:19:"Mayfair House Condo";'),
(1339, 50, 1, '2016-01-15 22:13:59', 'Item Created', 'ZurmoModule', 'Opportunity', 's:15:"Meadowbrook # 4";'),
(1340, 51, 1, '2016-01-15 22:13:59', 'Item Created', 'ZurmoModule', 'Opportunity', 's:13:"Midtown Doral";'),
(1341, 52, 1, '2016-01-15 22:13:59', 'Item Created', 'ZurmoModule', 'Opportunity', 's:14:"Midtown Retail";'),
(1342, 53, 1, '2016-01-15 22:14:00', 'Item Created', 'ZurmoModule', 'Opportunity', 's:12:"Mystic Point";'),
(1343, 54, 1, '2016-01-15 22:14:00', 'Item Created', 'ZurmoModule', 'Opportunity', 's:14:"Nirvana Condos";'),
(1344, 55, 1, '2016-01-15 22:14:00', 'Item Created', 'ZurmoModule', 'Opportunity', 's:19:"Northern Star (Net)";'),
(1345, 56, 1, '2016-01-15 22:14:00', 'Item Created', 'ZurmoModule', 'Opportunity', 's:9:"OakBridge";'),
(1346, 57, 1, '2016-01-15 22:14:00', 'Item Created', 'ZurmoModule', 'Opportunity', 's:11:"Ocean Place";'),
(1347, 58, 1, '2016-01-15 22:14:00', 'Item Created', 'ZurmoModule', 'Opportunity', 's:16:"Oceanfront Plaza";'),
(1348, 59, 1, '2016-01-15 22:14:00', 'Item Created', 'ZurmoModule', 'Opportunity', 's:15:"OceanView Place";'),
(1349, 60, 1, '2016-01-15 22:14:00', 'Item Created', 'ZurmoModule', 'Opportunity', 's:12:"Parker Plaza";'),
(1350, 61, 1, '2016-01-15 22:14:00', 'Item Created', 'ZurmoModule', 'Opportunity', 's:29:"Patrician of the Palm Beaches";'),
(1351, 62, 1, '2016-01-15 22:14:00', 'Item Created', 'ZurmoModule', 'Opportunity', 's:16:"Pine Ridge Condo";'),
(1352, 63, 1, '2016-01-15 22:14:00', 'Item Created', 'ZurmoModule', 'Opportunity', 's:20:"Pinehurst Club (Net)";'),
(1353, 64, 1, '2016-01-15 22:14:00', 'Item Created', 'ZurmoModule', 'Opportunity', 's:20:"Plaza of Bal Harbour";'),
(1354, 65, 1, '2016-01-15 22:14:00', 'Item Created', 'ZurmoModule', 'Opportunity', 's:16:"Point East Condo";'),
(1355, 66, 1, '2016-01-15 22:14:00', 'Item Created', 'ZurmoModule', 'Opportunity', 's:12:"River Bridge";'),
(1356, 67, 1, '2016-01-15 22:14:01', 'Item Created', 'ZurmoModule', 'Opportunity', 's:30:"Sand Pebble Beach Condominiums";'),
(1357, 68, 1, '2016-01-15 22:14:01', 'Item Created', 'ZurmoModule', 'Opportunity', 's:13:"Seamark (Net)";'),
(1358, 69, 1, '2016-01-15 22:14:01', 'Item Created', 'ZurmoModule', 'Opportunity', 's:17:"Strada 315 (Data)";'),
(1359, 70, 1, '2016-01-15 22:14:01', 'Item Created', 'ZurmoModule', 'Opportunity', 's:18:"Strada 315 (Video)";'),
(1360, 71, 1, '2016-01-15 22:14:01', 'Item Created', 'ZurmoModule', 'Opportunity', 's:17:"Sunset Bay (Data)";'),
(1361, 72, 1, '2016-01-15 22:14:01', 'Item Created', 'ZurmoModule', 'Opportunity', 's:18:"Sunset Bay (Video)";'),
(1362, 73, 1, '2016-01-15 22:14:02', 'Item Created', 'ZurmoModule', 'Opportunity', 's:11:"The Atriums";'),
(1363, 74, 1, '2016-01-15 22:14:02', 'Item Created', 'ZurmoModule', 'Opportunity', 's:48:"The Residences on Hollywood Beach Proposal (Net)";'),
(1364, 75, 1, '2016-01-15 22:14:02', 'Item Created', 'ZurmoModule', 'Opportunity', 's:16:"The Summit (Net)";'),
(1365, 76, 1, '2016-01-15 22:14:02', 'Item Created', 'ZurmoModule', 'Opportunity', 's:29:"The Tides @ Bridgeside Square";'),
(1366, 77, 1, '2016-01-15 22:14:02', 'Item Created', 'ZurmoModule', 'Opportunity', 's:11:"Topaz North";'),
(1367, 78, 1, '2016-01-15 22:14:02', 'Item Created', 'ZurmoModule', 'Opportunity', 's:22:"TOWERS OF KENDAL LAKES";'),
(1368, 79, 1, '2016-01-15 22:14:02', 'Item Created', 'ZurmoModule', 'Opportunity', 's:13:"Tropic Harbor";'),
(1369, 37, 1, '2016-01-15 22:14:03', 'Item Created', 'ZurmoModule', 'GameScore', 's:17:"ImportOpportunity";'),
(1370, 1, 1, '2016-01-15 22:14:37', 'Item Created', 'ZurmoModule', 'GameCollection', 's:7:"Fitness";'),
(1371, 23, 1, '2016-01-15 22:14:56', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:22:"400 Association (Data)";i:1;s:19:"OpportunitiesModule";}'),
(1372, 22, 1, '2016-01-15 22:15:47', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:10:"3360 Condo";i:1;s:19:"OpportunitiesModule";}'),
(1373, 22, 1, '2016-01-15 22:15:56', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:10:"3360 Condo";i:1;s:19:"OpportunitiesModule";}'),
(1374, 9, 1, '2016-01-15 22:16:55', 'Item Deleted', 'ZurmoModule', 'Contract', 's:4:"asdf";'),
(1375, 12, 1, '2016-01-15 22:16:55', 'Item Deleted', 'ZurmoModule', 'Contract', 's:7:"test ff";'),
(1376, 10, 1, '2016-01-15 22:16:55', 'Item Deleted', 'ZurmoModule', 'Contract', 's:17:"Test New contract";'),
(1377, 11, 1, '2016-01-15 22:16:55', 'Item Deleted', 'ZurmoModule', 'Contract', 's:3:"tst";'),
(1378, 8, 1, '2016-01-15 22:16:55', 'Item Deleted', 'ZurmoModule', 'Contract', 's:3:"wer";'),
(1379, 3, 1, '2016-01-15 22:20:11', 'Item Created', 'ZurmoModule', 'Import', 's:9:"(Unnamed)";'),
(1380, 13, 1, '2016-01-15 22:27:05', 'Item Created', 'ZurmoModule', 'Contract', 's:27:"Midtown Retail-New Contract";'),
(1381, 38, 1, '2016-01-15 22:27:07', 'Item Created', 'ZurmoModule', 'GameScore', 's:14:"ImportContract";'),
(1382, 4, 1, '2016-01-15 22:27:47', 'Item Created', 'ZurmoModule', 'Import', 's:9:"(Unnamed)";'),
(1383, 14, 1, '2016-01-15 22:31:19', 'Item Created', 'ZurmoModule', 'Contract', 's:23:"3360 Condo-New Contract";'),
(1384, 15, 1, '2016-01-15 22:31:20', 'Item Created', 'ZurmoModule', 'Contract', 's:39:"400 Association (Data)-Renewal Contract";'),
(1385, 16, 1, '2016-01-15 22:31:20', 'Item Created', 'ZurmoModule', 'Contract', 's:31:"9 Island (Net)-Renewal Contract";'),
(1386, 17, 1, '2016-01-15 22:31:20', 'Item Created', 'ZurmoModule', 'Contract', 's:34:"Alexander Hotel/Condo-New Contract";'),
(1387, 18, 1, '2016-01-15 22:31:20', 'Item Created', 'ZurmoModule', 'Contract', 's:20:"Artesia-New Contract";'),
(1388, 19, 1, '2016-01-15 22:31:20', 'Item Created', 'ZurmoModule', 'Contract', 's:19:"Aventi-New Contract";'),
(1389, 20, 1, '2016-01-15 22:31:20', 'Item Created', 'ZurmoModule', 'Contract', 's:27:"Balmoral Condo-New Contract";'),
(1390, 21, 1, '2016-01-15 22:31:20', 'Item Created', 'ZurmoModule', 'Contract', 's:28:"Bravura 1 Condo-New Contract";'),
(1391, 22, 1, '2016-01-15 22:31:20', 'Item Created', 'ZurmoModule', 'Contract', 's:30:"Christopher House-New Contract";'),
(1392, 23, 1, '2016-01-15 22:31:20', 'Item Created', 'ZurmoModule', 'Contract', 's:32:"Cloisters (Net)-Renewal Contract";'),
(1393, 24, 1, '2016-01-15 22:31:20', 'Item Created', 'ZurmoModule', 'Contract', 's:33:"Commodore Club South-New Contract";'),
(1394, 25, 1, '2016-01-15 22:31:20', 'Item Created', 'ZurmoModule', 'Contract', 's:28:"Commodore Plaza-New Contract";'),
(1395, 26, 1, '2016-01-15 22:31:20', 'Item Created', 'ZurmoModule', 'Contract', 's:27:"Cypress Trails-New Contract";'),
(1396, 27, 1, '2016-01-15 22:31:20', 'Item Created', 'ZurmoModule', 'Contract', 's:31:"East Pointe Towers-New Contract";'),
(1397, 28, 1, '2016-01-15 22:31:20', 'Item Created', 'ZurmoModule', 'Contract', 's:30:"Emerald (Net)-Renewal Contract";'),
(1398, 29, 1, '2016-01-15 22:31:20', 'Item Created', 'ZurmoModule', 'Contract', 's:32:"Fairways of Tamarac-New Contract";'),
(1399, 30, 1, '2016-01-15 22:31:20', 'Item Created', 'ZurmoModule', 'Contract', 's:37:"Garden Estates (Net)-Renewal Contract";'),
(1400, 31, 1, '2016-01-15 22:31:21', 'Item Created', 'ZurmoModule', 'Contract', 's:42:"Glades Country Club (Net)-Renewal Contract";'),
(1401, 32, 1, '2016-01-15 22:31:21', 'Item Created', 'ZurmoModule', 'Contract', 's:26:"Harbour House-New Contract";'),
(1402, 33, 1, '2016-01-15 22:31:21', 'Item Created', 'ZurmoModule', 'Contract', 's:27:"Hillsboro Cove-New Contract";'),
(1403, 34, 1, '2016-01-15 22:31:21', 'Item Created', 'ZurmoModule', 'Contract', 's:31:"Isles at Grand Bay-New Contract";'),
(1404, 35, 1, '2016-01-15 22:31:21', 'Item Created', 'ZurmoModule', 'Contract', 's:33:"Kenilworth (Net)-Renewal Contract";'),
(1405, 36, 1, '2016-01-15 22:31:21', 'Item Created', 'ZurmoModule', 'Contract', 's:22:"Key Largo-New Contract";'),
(1406, 37, 1, '2016-01-15 22:31:21', 'Item Created', 'ZurmoModule', 'Contract', 's:34:"Lake Worth Towers-Renewal Contract";'),
(1407, 38, 1, '2016-01-15 22:31:21', 'Item Created', 'ZurmoModule', 'Contract', 's:31:"Lakes of Savannah -New Contract";'),
(1408, 39, 1, '2016-01-15 22:31:21', 'Item Created', 'ZurmoModule', 'Contract', 's:23:"Las Verdes-New Contract";'),
(1409, 40, 1, '2016-01-15 22:31:21', 'Item Created', 'ZurmoModule', 'Contract', 's:37:"Marina Village (Net)-Renewal Contract";'),
(1410, 41, 1, '2016-01-15 22:31:21', 'Item Created', 'ZurmoModule', 'Contract', 's:32:"Mayfair House Condo-New Contract";'),
(1411, 42, 1, '2016-01-15 22:31:21', 'Item Created', 'ZurmoModule', 'Contract', 's:28:"Meadowbrook # 4-New Contract";'),
(1412, 43, 1, '2016-01-15 22:31:21', 'Item Created', 'ZurmoModule', 'Contract', 's:26:"Midtown Doral-New Contract";'),
(1413, 44, 1, '2016-01-15 22:31:21', 'Item Created', 'ZurmoModule', 'Contract', 's:27:"Midtown Retail-New Contract";'),
(1414, 45, 1, '2016-01-15 22:31:21', 'Item Created', 'ZurmoModule', 'Contract', 's:25:"Mystic Point-New Contract";'),
(1415, 46, 1, '2016-01-15 22:31:22', 'Item Created', 'ZurmoModule', 'Contract', 's:28:"Nirvana Condos -New Contract";'),
(1416, 47, 1, '2016-01-15 22:31:22', 'Item Created', 'ZurmoModule', 'Contract', 's:36:"Northern Star (Net)-Renewal Contract";'),
(1417, 48, 1, '2016-01-15 22:31:22', 'Item Created', 'ZurmoModule', 'Contract', 's:22:"OakBridge-New Contract";'),
(1418, 49, 1, '2016-01-15 22:31:22', 'Item Created', 'ZurmoModule', 'Contract', 's:24:"Ocean Place-New Contract";'),
(1419, 50, 1, '2016-01-15 22:31:22', 'Item Created', 'ZurmoModule', 'Contract', 's:29:"Oceanfront Plaza-New Contract";'),
(1420, 51, 1, '2016-01-15 22:31:22', 'Item Created', 'ZurmoModule', 'Contract', 's:28:"OceanView Place-New Contract";'),
(1421, 52, 1, '2016-01-15 22:31:22', 'Item Created', 'ZurmoModule', 'Contract', 's:25:"Parker Plaza-New Contract";'),
(1422, 53, 1, '2016-01-15 22:31:22', 'Item Created', 'ZurmoModule', 'Contract', 's:42:"Patrician of the Palm Beaches-New Contract";'),
(1423, 54, 1, '2016-01-15 22:31:22', 'Item Created', 'ZurmoModule', 'Contract', 's:29:"Pine Ridge Condo-New Contract";'),
(1424, 55, 1, '2016-01-15 22:31:22', 'Item Created', 'ZurmoModule', 'Contract', 's:37:"Pinehurst Club (Net)-Renewal Contract";'),
(1425, 56, 1, '2016-01-15 22:31:22', 'Item Created', 'ZurmoModule', 'Contract', 's:33:"Plaza of Bal Harbour-New Contract";'),
(1426, 57, 1, '2016-01-15 22:31:22', 'Item Created', 'ZurmoModule', 'Contract', 's:29:"Point East Condo-New Contract";'),
(1427, 58, 1, '2016-01-15 22:31:22', 'Item Created', 'ZurmoModule', 'Contract', 's:25:"River Bridge-New Contract";'),
(1428, 59, 1, '2016-01-15 22:31:22', 'Item Created', 'ZurmoModule', 'Contract', 's:43:"Sand Pebble Beach Condominiums-New Contract";'),
(1429, 60, 1, '2016-01-15 22:31:22', 'Item Created', 'ZurmoModule', 'Contract', 's:30:"Seamark (Net)-Renewal Contract";'),
(1430, 61, 1, '2016-01-15 22:31:22', 'Item Created', 'ZurmoModule', 'Contract', 's:30:"Strada 315 (Data)-New Contract";'),
(1431, 62, 1, '2016-01-15 22:31:23', 'Item Created', 'ZurmoModule', 'Contract', 's:31:"Strada 315 (Video)-New Contract";'),
(1432, 63, 1, '2016-01-15 22:31:23', 'Item Created', 'ZurmoModule', 'Contract', 's:30:"Sunset Bay (Data)-New Contract";'),
(1433, 64, 1, '2016-01-15 22:31:23', 'Item Created', 'ZurmoModule', 'Contract', 's:31:"Sunset Bay (Video)-New Contract";'),
(1434, 65, 1, '2016-01-15 22:31:23', 'Item Created', 'ZurmoModule', 'Contract', 's:24:"The Atriums-New Contract";'),
(1435, 66, 1, '2016-01-15 22:31:23', 'Item Created', 'ZurmoModule', 'Contract', 's:64:"The Residences on Hollywood Beach Proposal (Net)-Renewal Contrac";'),
(1436, 67, 1, '2016-01-15 22:31:24', 'Item Created', 'ZurmoModule', 'Contract', 's:33:"The Summit (Net)-Renewal Contract";'),
(1437, 68, 1, '2016-01-15 22:31:24', 'Item Created', 'ZurmoModule', 'Contract', 's:42:"The Tides @ Bridgeside Square-New Contract";'),
(1438, 69, 1, '2016-01-15 22:31:24', 'Item Created', 'ZurmoModule', 'Contract', 's:24:"Topaz North-New Contract";'),
(1439, 70, 1, '2016-01-15 22:31:24', 'Item Created', 'ZurmoModule', 'Contract', 's:35:"TOWERS OF KENDAL LAKES-New Contract";'),
(1440, 71, 1, '2016-01-15 22:31:24', 'Item Created', 'ZurmoModule', 'Contract', 's:26:"Tropic Harbor-New Contract";'),
(1441, NULL, 1, '2016-01-17 06:26:07', 'User Logged In', 'UsersModule', NULL, 'N;'),
(1442, 35, 1, '2016-01-17 06:26:34', 'Item Viewed', 'ZurmoModule', 'Account', 'a:2:{i:0;s:10:"3360 Condo";i:1;s:14:"AccountsModule";}'),
(1443, 22, 1, '2016-01-17 06:26:40', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:10:"3360 Condo";i:1;s:19:"OpportunitiesModule";}'),
(1444, 14, 1, '2016-01-17 06:27:01', 'Item Viewed', 'ZurmoModule', 'Contract', 'a:2:{i:0;s:23:"3360 Condo-New Contract";i:1;s:15:"ContractsModule";}'),
(1445, 2, 1, '2016-01-17 06:27:19', 'Item Viewed', 'ZurmoModule', 'SavedReport', 'a:2:{i:0;s:16:"New Leads Report";i:1;s:13:"ReportsModule";}'),
(1446, 6, 1, '2016-01-17 06:27:23', 'Item Viewed', 'ZurmoModule', 'SavedReport', 'a:2:{i:0;s:22:"Opportunities by Stage";i:1;s:13:"ReportsModule";}'),
(1447, 25, 1, '2016-01-18 00:59:14', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:21:"Alexander Hotel/Condo";i:1;s:19:"OpportunitiesModule";}'),
(1448, 23, 1, '2016-01-18 00:59:29', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:22:"400 Association (Data)";i:1;s:19:"OpportunitiesModule";}'),
(1449, NULL, 1, '2016-01-18 14:15:16', 'User Logged In', 'UsersModule', NULL, 'N;'),
(1450, 24, 1, '2016-01-18 14:23:46', 'Item Viewed', 'ZurmoModule', 'Account', 'a:2:{i:0;s:22:"400 Association (Data)";i:1;s:14:"AccountsModule";}'),
(1451, 29, 1, '2016-01-18 14:25:22', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:15:"Bravura 1 Condo";i:1;s:19:"OpportunitiesModule";}'),
(1452, 16, 1, '2016-01-18 14:25:47', 'Item Viewed', 'ZurmoModule', 'Contract', 'a:2:{i:0;s:31:"9 Island (Net)-Renewal Contract";i:1;s:15:"ContractsModule";}'),
(1453, 16, 1, '2016-01-18 15:43:14', 'Item Viewed', 'ZurmoModule', 'Contract', 'a:2:{i:0;s:31:"9 Island (Net)-Renewal Contract";i:1;s:15:"ContractsModule";}'),
(1454, NULL, 1, '2016-01-18 16:00:00', 'User Logged In', 'UsersModule', NULL, 'N;'),
(1455, 45, 1, '2016-01-18 16:02:41', 'Item Viewed', 'ZurmoModule', 'Contract', 'a:2:{i:0;s:25:"Mystic Point-New Contract";i:1;s:15:"ContractsModule";}'),
(1456, 35, 1, '2016-01-18 16:06:34', 'Item Viewed', 'ZurmoModule', 'Account', 'a:2:{i:0;s:10:"3360 Condo";i:1;s:14:"AccountsModule";}'),
(1457, 22, 1, '2016-01-18 16:06:41', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:10:"3360 Condo";i:1;s:19:"OpportunitiesModule";}'),
(1458, 36, 1, '2016-01-18 16:12:00', 'Item Viewed', 'ZurmoModule', 'Contract', 'a:2:{i:0;s:22:"Key Largo-New Contract";i:1;s:15:"ContractsModule";}'),
(1459, 35, 1, '2016-01-18 16:16:56', 'Item Viewed', 'ZurmoModule', 'Account', 'a:2:{i:0;s:10:"3360 Condo";i:1;s:14:"AccountsModule";}'),
(1460, 4, 1, '2016-01-18 16:19:22', 'Item Viewed', 'ZurmoModule', 'Conversation', 'a:2:{i:0;s:25:"Vacation time in December";i:1;s:19:"ConversationsModule";}'),
(1461, 35, 1, '2016-01-18 16:46:19', 'Item Viewed', 'ZurmoModule', 'Account', 'a:2:{i:0;s:10:"3360 Condo";i:1;s:14:"AccountsModule";}'),
(1462, 22, 1, '2016-01-18 16:46:40', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:10:"3360 Condo";i:1;s:19:"OpportunitiesModule";}'),
(1463, 14, 1, '2016-01-18 16:49:41', 'Item Viewed', 'ZurmoModule', 'Contract', 'a:2:{i:0;s:23:"3360 Condo-New Contract";i:1;s:15:"ContractsModule";}'),
(1464, 14, 1, '2016-01-18 16:50:05', 'Item Viewed', 'ZurmoModule', 'Contract', 'a:2:{i:0;s:23:"3360 Condo-New Contract";i:1;s:15:"ContractsModule";}'),
(1465, 14, 1, '2016-01-18 16:50:36', 'Item Viewed', 'ZurmoModule', 'Contract', 'a:2:{i:0;s:23:"3360 Condo-New Contract";i:1;s:15:"ContractsModule";}'),
(1466, 14, 1, '2016-01-18 16:58:26', 'Item Viewed', 'ZurmoModule', 'Contract', 'a:2:{i:0;s:23:"3360 Condo-New Contract";i:1;s:15:"ContractsModule";}'),
(1467, 14, 1, '2016-01-18 16:58:55', 'Item Viewed', 'ZurmoModule', 'Contract', 'a:2:{i:0;s:23:"3360 Condo-New Contract";i:1;s:15:"ContractsModule";}'),
(1468, 22, 1, '2016-01-18 16:59:24', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:10:"3360 Condo";i:1;s:19:"OpportunitiesModule";}'),
(1469, 22, 1, '2016-01-18 17:01:27', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:10:"3360 Condo";i:1;s:19:"OpportunitiesModule";}'),
(1470, 14, 1, '2016-01-18 17:02:05', 'Item Viewed', 'ZurmoModule', 'Contract', 'a:2:{i:0;s:23:"3360 Condo-New Contract";i:1;s:15:"ContractsModule";}'),
(1471, 14, 1, '2016-01-18 17:02:08', 'Item Viewed', 'ZurmoModule', 'Contract', 'a:2:{i:0;s:23:"3360 Condo-New Contract";i:1;s:15:"ContractsModule";}'),
(1472, 14, 1, '2016-01-18 17:02:09', 'Item Viewed', 'ZurmoModule', 'Contract', 'a:2:{i:0;s:23:"3360 Condo-New Contract";i:1;s:15:"ContractsModule";}'),
(1473, 23, 1, '2016-01-18 17:21:06', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:22:"400 Association (Data)";i:1;s:19:"OpportunitiesModule";}'),
(1474, 23, 1, '2016-01-18 17:21:27', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:22:"400 Association (Data)";i:1;s:19:"OpportunitiesModule";}'),
(1475, 24, 1, '2016-01-18 17:21:52', 'Item Viewed', 'ZurmoModule', 'Account', 'a:2:{i:0;s:22:"400 Association (Data)";i:1;s:14:"AccountsModule";}'),
(1476, 24, 1, '2016-01-18 17:22:00', 'Item Viewed', 'ZurmoModule', 'Account', 'a:2:{i:0;s:22:"400 Association (Data)";i:1;s:14:"AccountsModule";}'),
(1477, 22, 1, '2016-01-18 17:22:06', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:10:"3360 Condo";i:1;s:19:"OpportunitiesModule";}'),
(1478, 22, 1, '2016-01-18 17:22:13', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:10:"3360 Condo";i:1;s:19:"OpportunitiesModule";}'),
(1479, 22, 1, '2016-01-18 17:23:23', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:10:"3360 Condo";i:1;s:19:"OpportunitiesModule";}'),
(1480, 24, 1, '2016-01-18 17:25:11', 'Item Viewed', 'ZurmoModule', 'Account', 'a:2:{i:0;s:22:"400 Association (Data)";i:1;s:14:"AccountsModule";}'),
(1481, 45, 1, '2016-01-18 17:25:25', 'Item Viewed', 'ZurmoModule', 'Account', 'a:2:{i:0;s:14:"9 Island (Net)";i:1;s:14:"AccountsModule";}'),
(1482, 62, 1, '2016-01-18 17:25:40', 'Item Viewed', 'ZurmoModule', 'Account', 'a:2:{i:0;s:21:"Alexander Hotel/Condo";i:1;s:14:"AccountsModule";}'),
(1483, 48, 1, '2016-01-18 17:26:08', 'Item Viewed', 'ZurmoModule', 'Account', 'a:2:{i:0;s:7:"Artesia";i:1;s:14:"AccountsModule";}'),
(1484, 22, 1, '2016-01-18 17:26:14', 'Item Viewed', 'ZurmoModule', 'Account', 'a:2:{i:0;s:6:"Aventi";i:1;s:14:"AccountsModule";}'),
(1485, 47, 1, '2016-01-18 17:26:23', 'Item Viewed', 'ZurmoModule', 'Account', 'a:2:{i:0;s:14:"Balmoral Condo";i:1;s:14:"AccountsModule";}'),
(1486, 66, 1, '2016-01-18 17:26:29', 'Item Viewed', 'ZurmoModule', 'Account', 'a:2:{i:0;s:15:"Bravura 1 Condo";i:1;s:14:"AccountsModule";}'),
(1487, 39, 1, '2016-01-18 17:26:35', 'Item Viewed', 'ZurmoModule', 'Account', 'a:2:{i:0;s:17:"Christopher House";i:1;s:14:"AccountsModule";}'),
(1488, 34, 1, '2016-01-18 17:26:40', 'Item Viewed', 'ZurmoModule', 'Account', 'a:2:{i:0;s:15:"Cloisters (Net)";i:1;s:14:"AccountsModule";}'),
(1489, 68, 1, '2016-01-18 17:26:45', 'Item Viewed', 'ZurmoModule', 'Account', 'a:2:{i:0;s:20:"Commodore Club South";i:1;s:14:"AccountsModule";}'),
(1490, 59, 1, '2016-01-18 17:26:51', 'Item Viewed', 'ZurmoModule', 'Account', 'a:2:{i:0;s:15:"Commodore Plaza";i:1;s:14:"AccountsModule";}'),
(1491, 17, 1, '2016-01-18 17:26:56', 'Item Viewed', 'ZurmoModule', 'Account', 'a:2:{i:0;s:14:"Cypress Trails";i:1;s:14:"AccountsModule";}'),
(1492, 65, 1, '2016-01-18 17:27:01', 'Item Viewed', 'ZurmoModule', 'Account', 'a:2:{i:0;s:18:"East Pointe Towers";i:1;s:14:"AccountsModule";}'),
(1493, 33, 1, '2016-01-18 17:27:06', 'Item Viewed', 'ZurmoModule', 'Account', 'a:2:{i:0;s:13:"Emerald (Net)";i:1;s:14:"AccountsModule";}'),
(1494, 60, 1, '2016-01-18 17:27:12', 'Item Viewed', 'ZurmoModule', 'Account', 'a:2:{i:0;s:19:"Fairways of Tamarac";i:1;s:14:"AccountsModule";}'),
(1495, 21, 1, '2016-01-18 17:27:16', 'Item Viewed', 'ZurmoModule', 'Account', 'a:2:{i:0;s:20:"Garden Estates (Net)";i:1;s:14:"AccountsModule";}'),
(1496, 44, 1, '2016-01-18 17:27:21', 'Item Viewed', 'ZurmoModule', 'Account', 'a:2:{i:0;s:25:"Glades Country Club (Net)";i:1;s:14:"AccountsModule";}'),
(1497, 42, 1, '2016-01-18 17:27:26', 'Item Viewed', 'ZurmoModule', 'Account', 'a:2:{i:0;s:13:"Harbour House";i:1;s:14:"AccountsModule";}'),
(1498, 70, 1, '2016-01-18 17:27:31', 'Item Viewed', 'ZurmoModule', 'Account', 'a:2:{i:0;s:14:"Hillsboro Cove";i:1;s:14:"AccountsModule";}'),
(1499, 18, 1, '2016-01-18 17:27:36', 'Item Viewed', 'ZurmoModule', 'Account', 'a:2:{i:0;s:18:"Isles at Grand Bay";i:1;s:14:"AccountsModule";}'),
(1500, 23, 1, '2016-01-18 17:27:42', 'Item Viewed', 'ZurmoModule', 'Account', 'a:2:{i:0;s:16:"Kenilworth (Net)";i:1;s:14:"AccountsModule";}'),
(1501, 20, 1, '2016-01-18 17:27:48', 'Item Viewed', 'ZurmoModule', 'Account', 'a:2:{i:0;s:9:"Key Largo";i:1;s:14:"AccountsModule";}'),
(1502, 36, 1, '2016-01-18 17:27:52', 'Item Viewed', 'ZurmoModule', 'Account', 'a:2:{i:0;s:17:"Lake Worth Towers";i:1;s:14:"AccountsModule";}'),
(1503, 64, 1, '2016-01-18 17:27:58', 'Item Viewed', 'ZurmoModule', 'Account', 'a:2:{i:0;s:17:"Lakes of Savannah";i:1;s:14:"AccountsModule";}'),
(1504, 63, 1, '2016-01-18 17:28:04', 'Item Viewed', 'ZurmoModule', 'Account', 'a:2:{i:0;s:10:"Las Verdes";i:1;s:14:"AccountsModule";}'),
(1505, 25, 1, '2016-01-18 17:28:10', 'Item Viewed', 'ZurmoModule', 'Account', 'a:2:{i:0;s:20:"Marina Village (Net)";i:1;s:14:"AccountsModule";}'),
(1506, 49, 1, '2016-01-18 17:28:16', 'Item Viewed', 'ZurmoModule', 'Account', 'a:2:{i:0;s:19:"Mayfair House Condo";i:1;s:14:"AccountsModule";}'),
(1507, 29, 1, '2016-01-18 17:28:25', 'Item Viewed', 'ZurmoModule', 'Account', 'a:2:{i:0;s:15:"Meadowbrook # 4";i:1;s:14:"AccountsModule";}'),
(1508, 27, 1, '2016-01-18 17:28:31', 'Item Viewed', 'ZurmoModule', 'Account', 'a:2:{i:0;s:13:"Midtown Doral";i:1;s:14:"AccountsModule";}'),
(1509, 28, 1, '2016-01-18 17:28:36', 'Item Viewed', 'ZurmoModule', 'Account', 'a:2:{i:0;s:14:"Midtown Retail";i:1;s:14:"AccountsModule";}'),
(1510, 43, 1, '2016-01-18 17:28:41', 'Item Viewed', 'ZurmoModule', 'Account', 'a:2:{i:0;s:12:"Mystic Point";i:1;s:14:"AccountsModule";}'),
(1511, 58, 1, '2016-01-18 17:28:53', 'Item Viewed', 'ZurmoModule', 'Account', 'a:2:{i:0;s:14:"Nirvana Condos";i:1;s:14:"AccountsModule";}'),
(1512, 32, 1, '2016-01-18 17:28:59', 'Item Viewed', 'ZurmoModule', 'Account', 'a:2:{i:0;s:19:"Northern Star (Net)";i:1;s:14:"AccountsModule";}'),
(1513, 54, 1, '2016-01-18 17:29:04', 'Item Viewed', 'ZurmoModule', 'Account', 'a:2:{i:0;s:9:"OakBridge";i:1;s:14:"AccountsModule";}'),
(1514, 52, 1, '2016-01-18 17:29:09', 'Item Viewed', 'ZurmoModule', 'Account', 'a:2:{i:0;s:11:"Ocean Place";i:1;s:14:"AccountsModule";}'),
(1515, 69, 1, '2016-01-18 17:29:14', 'Item Viewed', 'ZurmoModule', 'Account', 'a:2:{i:0;s:16:"Oceanfront Plaza";i:1;s:14:"AccountsModule";}'),
(1516, 50, 1, '2016-01-18 17:29:19', 'Item Viewed', 'ZurmoModule', 'Account', 'a:2:{i:0;s:15:"OceanView Place";i:1;s:14:"AccountsModule";}'),
(1517, 30, 1, '2016-01-18 17:29:46', 'Item Viewed', 'ZurmoModule', 'Account', 'a:2:{i:0;s:12:"Parker Plaza";i:1;s:14:"AccountsModule";}'),
(1518, 61, 1, '2016-01-18 17:30:28', 'Item Viewed', 'ZurmoModule', 'Account', 'a:2:{i:0;s:29:"Patrician of the Palm Beaches";i:1;s:14:"AccountsModule";}'),
(1519, 38, 1, '2016-01-18 17:30:37', 'Item Viewed', 'ZurmoModule', 'Account', 'a:2:{i:0;s:16:"Pine Ridge Condo";i:1;s:14:"AccountsModule";}'),
(1520, 41, 1, '2016-01-18 17:30:44', 'Item Viewed', 'ZurmoModule', 'Account', 'a:2:{i:0;s:20:"Pinehurst Club (Net)";i:1;s:14:"AccountsModule";}'),
(1521, 57, 1, '2016-01-18 17:30:50', 'Item Viewed', 'ZurmoModule', 'Account', 'a:2:{i:0;s:20:"Plaza of Bal Harbour";i:1;s:14:"AccountsModule";}'),
(1522, 37, 1, '2016-01-18 17:30:56', 'Item Viewed', 'ZurmoModule', 'Account', 'a:2:{i:0;s:16:"Point East Condo";i:1;s:14:"AccountsModule";}'),
(1523, 51, 1, '2016-01-18 17:31:02', 'Item Viewed', 'ZurmoModule', 'Account', 'a:2:{i:0;s:12:"River Bridge";i:1;s:14:"AccountsModule";}'),
(1524, 55, 1, '2016-01-18 17:31:07', 'Item Viewed', 'ZurmoModule', 'Account', 'a:2:{i:0;s:30:"Sand Pebble Beach Condominiums";i:1;s:14:"AccountsModule";}'),
(1525, 46, 1, '2016-01-18 17:31:13', 'Item Viewed', 'ZurmoModule', 'Account', 'a:2:{i:0;s:13:"Seamark (Net)";i:1;s:14:"AccountsModule";}'),
(1526, 14, 1, '2016-01-18 17:31:18', 'Item Viewed', 'ZurmoModule', 'Account', 'a:2:{i:0;s:17:"Strada 315 (Data)";i:1;s:14:"AccountsModule";}'),
(1527, 13, 1, '2016-01-18 17:31:25', 'Item Viewed', 'ZurmoModule', 'Account', 'a:2:{i:0;s:18:"Strada 315 (Video)";i:1;s:14:"AccountsModule";}'),
(1528, 15, 1, '2016-01-18 17:31:32', 'Item Viewed', 'ZurmoModule', 'Account', 'a:2:{i:0;s:17:"Sunset Bay (Data)";i:1;s:14:"AccountsModule";}'),
(1529, 16, 1, '2016-01-18 17:31:37', 'Item Viewed', 'ZurmoModule', 'Account', 'a:2:{i:0;s:18:"Sunset Bay (Video)";i:1;s:14:"AccountsModule";}'),
(1530, 56, 1, '2016-01-18 17:31:42', 'Item Viewed', 'ZurmoModule', 'Account', 'a:2:{i:0;s:11:"The Atriums";i:1;s:14:"AccountsModule";}'),
(1531, 40, 1, '2016-01-18 17:31:47', 'Item Viewed', 'ZurmoModule', 'Account', 'a:2:{i:0;s:48:"The Residences on Hollywood Beach Proposal (Net)";i:1;s:14:"AccountsModule";}'),
(1532, 19, 1, '2016-01-18 17:31:54', 'Item Viewed', 'ZurmoModule', 'Account', 'a:2:{i:0;s:16:"The Summit (Net)";i:1;s:14:"AccountsModule";}'),
(1533, 53, 1, '2016-01-18 17:32:01', 'Item Viewed', 'ZurmoModule', 'Account', 'a:2:{i:0;s:29:"The Tides @ Bridgeside Square";i:1;s:14:"AccountsModule";}'),
(1534, 31, 1, '2016-01-18 17:32:06', 'Item Viewed', 'ZurmoModule', 'Account', 'a:2:{i:0;s:11:"Topaz North";i:1;s:14:"AccountsModule";}'),
(1535, 67, 1, '2016-01-18 17:32:10', 'Item Viewed', 'ZurmoModule', 'Account', 'a:2:{i:0;s:22:"TOWERS OF KENDAL LAKES";i:1;s:14:"AccountsModule";}'),
(1536, 26, 1, '2016-01-18 17:32:35', 'Item Viewed', 'ZurmoModule', 'Account', 'a:2:{i:0;s:13:"Tropic Harbor";i:1;s:14:"AccountsModule";}'),
(1537, 22, 1, '2016-01-18 17:33:01', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:10:"3360 Condo";i:1;s:19:"OpportunitiesModule";}'),
(1538, 14, 1, '2016-01-18 17:34:10', 'Item Viewed', 'ZurmoModule', 'Contract', 'a:2:{i:0;s:23:"3360 Condo-New Contract";i:1;s:15:"ContractsModule";}'),
(1539, 15, 1, '2016-01-18 17:34:21', 'Item Viewed', 'ZurmoModule', 'Contract', 'a:2:{i:0;s:39:"400 Association (Data)-Renewal Contract";i:1;s:15:"ContractsModule";}'),
(1540, 23, 1, '2016-01-18 17:34:24', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:22:"400 Association (Data)";i:1;s:19:"OpportunitiesModule";}'),
(1541, 24, 1, '2016-01-18 17:34:31', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:14:"9 Island (Net)";i:1;s:19:"OpportunitiesModule";}'),
(1542, 16, 1, '2016-01-18 17:34:36', 'Item Viewed', 'ZurmoModule', 'Contract', 'a:2:{i:0;s:31:"9 Island (Net)-Renewal Contract";i:1;s:15:"ContractsModule";}'),
(1543, 22, 1, '2016-01-18 17:36:52', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:10:"3360 Condo";i:1;s:19:"OpportunitiesModule";}'),
(1544, 23, 1, '2016-01-18 17:37:03', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:22:"400 Association (Data)";i:1;s:19:"OpportunitiesModule";}'),
(1545, 23, 1, '2016-01-18 17:38:22', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:22:"400 Association (Data)";i:1;s:19:"OpportunitiesModule";}'),
(1546, 41, 1, '2016-01-18 17:43:06', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:14:"Hillsboro Cove";i:1;s:19:"OpportunitiesModule";}'),
(1547, 40, 1, '2016-01-18 17:43:18', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:13:"Harbour House";i:1;s:19:"OpportunitiesModule";}'),
(1548, 61, 1, '2016-01-18 17:43:42', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:29:"Patrician of the Palm Beaches";i:1;s:19:"OpportunitiesModule";}'),
(1549, 68, 1, '2016-01-18 17:43:51', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:13:"Seamark (Net)";i:1;s:19:"OpportunitiesModule";}'),
(1550, 70, 1, '2016-01-18 17:44:07', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:18:"Strada 315 (Video)";i:1;s:19:"OpportunitiesModule";}'),
(1551, 75, 1, '2016-01-18 17:44:15', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:16:"The Summit (Net)";i:1;s:19:"OpportunitiesModule";}'),
(1552, 78, 1, '2016-01-18 17:44:23', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:22:"TOWERS OF KENDAL LAKES";i:1;s:19:"OpportunitiesModule";}'),
(1553, 79, 1, '2016-01-18 17:44:29', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:13:"Tropic Harbor";i:1;s:19:"OpportunitiesModule";}'),
(1554, 26, 1, '2016-01-18 17:48:35', 'Item Viewed', 'ZurmoModule', 'Account', 'a:2:{i:0;s:13:"Tropic Harbor";i:1;s:14:"AccountsModule";}'),
(1555, 79, 1, '2016-01-18 17:48:46', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:13:"Tropic Harbor";i:1;s:19:"OpportunitiesModule";}'),
(1556, 71, 1, '2016-01-18 17:48:52', 'Item Viewed', 'ZurmoModule', 'Contract', 'a:2:{i:0;s:26:"Tropic Harbor-New Contract";i:1;s:15:"ContractsModule";}'),
(1557, 14, 1, '2016-01-18 17:58:14', 'Item Viewed', 'ZurmoModule', 'Contract', 'a:2:{i:0;s:23:"3360 Condo-New Contract";i:1;s:15:"ContractsModule";}'),
(1558, 14, 1, '2016-01-18 17:58:39', 'Item Viewed', 'ZurmoModule', 'Contract', 'a:2:{i:0;s:23:"3360 Condo-New Contract";i:1;s:15:"ContractsModule";}'),
(1559, NULL, 1, '2016-01-18 18:03:44', 'User Logged In', 'UsersModule', NULL, 'N;'),
(1560, 35, 1, '2016-01-18 18:04:05', 'Item Viewed', 'ZurmoModule', 'Account', 'a:2:{i:0;s:10:"3360 Condo";i:1;s:14:"AccountsModule";}'),
(1561, 22, 1, '2016-01-18 18:04:26', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:10:"3360 Condo";i:1;s:19:"OpportunitiesModule";}'),
(1562, 23, 1, '2016-01-18 18:06:40', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:22:"400 Association (Data)";i:1;s:19:"OpportunitiesModule";}'),
(1563, 15, 1, '2016-01-18 18:06:53', 'Item Viewed', 'ZurmoModule', 'Contract', 'a:2:{i:0;s:39:"400 Association (Data)-Renewal Contract";i:1;s:15:"ContractsModule";}'),
(1564, 35, 1, '2016-01-18 18:07:30', 'Item Viewed', 'ZurmoModule', 'Account', 'a:2:{i:0;s:10:"3360 Condo";i:1;s:14:"AccountsModule";}'),
(1565, 35, 1, '2016-01-18 18:08:51', 'Item Viewed', 'ZurmoModule', 'Account', 'a:2:{i:0;s:10:"3360 Condo";i:1;s:14:"AccountsModule";}'),
(1566, 22, 1, '2016-01-18 18:21:17', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:10:"3360 Condo";i:1;s:19:"OpportunitiesModule";}'),
(1567, 14, 1, '2016-01-18 18:23:54', 'Item Viewed', 'ZurmoModule', 'Contract', 'a:2:{i:0;s:23:"3360 Condo-New Contract";i:1;s:15:"ContractsModule";}'),
(1568, 35, 1, '2016-01-18 18:53:58', 'Item Viewed', 'ZurmoModule', 'Account', 'a:2:{i:0;s:10:"3360 Condo";i:1;s:14:"AccountsModule";}'),
(1569, 35, 1, '2016-01-18 18:56:18', 'Item Viewed', 'ZurmoModule', 'Account', 'a:2:{i:0;s:10:"3360 Condo";i:1;s:14:"AccountsModule";}'),
(1570, 14, 1, '2016-01-18 19:03:26', 'Item Viewed', 'ZurmoModule', 'Contract', 'a:2:{i:0;s:23:"3360 Condo-New Contract";i:1;s:15:"ContractsModule";}'),
(1571, 35, 1, '2016-01-18 19:17:34', 'Item Viewed', 'ZurmoModule', 'Account', 'a:2:{i:0;s:10:"3360 Condo";i:1;s:14:"AccountsModule";}'),
(1572, 22, 1, '2016-01-18 21:10:04', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:10:"3360 Condo";i:1;s:19:"OpportunitiesModule";}'),
(1573, 35, 1, '2016-01-18 21:14:09', 'Item Viewed', 'ZurmoModule', 'Account', 'a:2:{i:0;s:10:"3360 Condo";i:1;s:14:"AccountsModule";}'),
(1574, 22, 1, '2016-01-18 21:14:18', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:10:"3360 Condo";i:1;s:19:"OpportunitiesModule";}'),
(1575, 14, 1, '2016-01-18 21:14:27', 'Item Viewed', 'ZurmoModule', 'Contract', 'a:2:{i:0;s:23:"3360 Condo-New Contract";i:1;s:15:"ContractsModule";}'),
(1576, NULL, 1, '2016-01-19 07:47:13', 'User Logged In', 'UsersModule', NULL, 'N;'),
(1577, 20, 1, '2016-01-19 07:47:14', 'Item Modified', 'ZurmoModule', 'GameBadge', 'a:4:{i:0;s:10:"NightOwl 2";i:1;a:1:{i:0;s:5:"grade";}i:2;s:1:"1";i:3;i:2;}'),
(1578, NULL, 1, '2016-01-19 09:15:30', 'User Logged In', 'UsersModule', NULL, 'N;'),
(1579, NULL, 1, '2016-01-19 09:27:01', 'User Logged In', 'UsersModule', NULL, 'N;'),
(1580, 22, 1, '2016-01-19 09:40:14', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:10:"3360 Condo";i:1;s:19:"OpportunitiesModule";}'),
(1581, 22, 1, '2016-01-19 09:40:45', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:10:"3360 Condo";i:1;s:19:"OpportunitiesModule";}'),
(1582, 23, 1, '2016-01-19 09:41:13', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:22:"400 Association (Data)";i:1;s:19:"OpportunitiesModule";}'),
(1583, 23, 1, '2016-01-19 09:41:24', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:22:"400 Association (Data)";i:1;s:19:"OpportunitiesModule";}'),
(1584, 23, 1, '2016-01-19 09:41:36', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:22:"400 Association (Data)";i:1;s:19:"OpportunitiesModule";}'),
(1585, 23, 1, '2016-01-19 09:41:47', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:22:"400 Association (Data)";i:1;s:19:"OpportunitiesModule";}'),
(1586, 23, 1, '2016-01-19 09:48:22', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:22:"400 Association (Data)";i:1;s:19:"OpportunitiesModule";}'),
(1587, 23, 1, '2016-01-19 09:48:32', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:22:"400 Association (Data)";i:1;s:19:"OpportunitiesModule";}'),
(1588, 23, 1, '2016-01-19 09:48:41', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:22:"400 Association (Data)";i:1;s:19:"OpportunitiesModule";}'),
(1589, 23, 1, '2016-01-19 09:48:51', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:22:"400 Association (Data)";i:1;s:19:"OpportunitiesModule";}'),
(1590, 22, 1, '2016-01-19 10:15:01', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:10:"3360 Condo";i:1;s:19:"OpportunitiesModule";}'),
(1591, 25, 1, '2016-01-19 10:15:34', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:21:"Alexander Hotel/Condo";i:1;s:19:"OpportunitiesModule";}'),
(1592, NULL, 1, '2016-01-19 13:42:13', 'User Logged In', 'UsersModule', NULL, 'N;'),
(1593, 21, 1, '2016-01-19 13:42:13', 'Item Modified', 'ZurmoModule', 'GameBadge', 'a:4:{i:0;s:11:"EarlyBird 2";i:1;a:1:{i:0;s:5:"grade";}i:2;s:1:"1";i:3;i:2;}'),
(1594, 24, 1, '2016-01-19 13:45:53', 'Item Viewed', 'ZurmoModule', 'Account', 'a:2:{i:0;s:22:"400 Association (Data)";i:1;s:14:"AccountsModule";}'),
(1595, NULL, 1, '2016-01-19 13:50:04', 'User Logged In', 'UsersModule', NULL, 'N;'),
(1596, 22, 1, '2016-01-19 13:50:35', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:10:"3360 Condo";i:1;s:19:"OpportunitiesModule";}'),
(1597, 22, 1, '2016-01-19 13:50:55', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:10:"3360 Condo";i:1;s:19:"OpportunitiesModule";}'),
(1598, 14, 1, '2016-01-19 14:02:37', 'Item Deleted', 'ZurmoModule', 'Account', 's:10:"Strada 315";'),
(1599, 16, 1, '2016-01-19 14:02:37', 'Item Deleted', 'ZurmoModule', 'Account', 's:10:"Sunset Bay";'),
(1600, 69, 1, '2016-01-19 14:03:38', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:17:"Strada 315 (Data)";i:1;s:19:"OpportunitiesModule";}'),
(1601, 72, 1, '2016-01-19 14:03:47', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:18:"Sunset Bay (Video)";i:1;s:19:"OpportunitiesModule";}'),
(1602, 72, 1, '2016-01-19 14:05:40', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:18:"Sunset Bay (Video)";i:1;s:19:"OpportunitiesModule";}'),
(1603, 35, 1, '2016-01-19 14:13:10', 'Item Viewed', 'ZurmoModule', 'Account', 'a:2:{i:0;s:10:"3360 Condo";i:1;s:14:"AccountsModule";}'),
(1604, 14, 1, '2016-01-19 14:13:22', 'Item Viewed', 'ZurmoModule', 'Contract', 'a:2:{i:0;s:23:"3360 Condo-New Contract";i:1;s:15:"ContractsModule";}'),
(1605, 14, 1, '2016-01-19 14:14:51', 'Item Viewed', 'ZurmoModule', 'Contract', 'a:2:{i:0;s:23:"3360 Condo-New Contract";i:1;s:15:"ContractsModule";}'),
(1606, 39, 1, '2016-01-19 14:17:01', 'Item Created', 'ZurmoModule', 'GameScore', 's:16:"MassEditContract";'),
(1607, 14, 1, '2016-01-19 14:17:01', 'Item Modified', 'ZurmoModule', 'Contract', 'a:4:{i:0;s:23:"3360 Condo-New Contract";i:1;a:2:{i:0;s:16:"contractTypeCstm";i:1;s:5:"value";}i:2;N;i:3;s:3:"New";}'),
(1608, 18, 1, '2016-01-19 14:17:01', 'Item Modified', 'ZurmoModule', 'Contract', 'a:4:{i:0;s:20:"Artesia-New Contract";i:1;a:2:{i:0;s:16:"contractTypeCstm";i:1;s:5:"value";}i:2;N;i:3;s:3:"New";}'),
(1609, 17, 1, '2016-01-19 14:17:01', 'Item Modified', 'ZurmoModule', 'Contract', 'a:4:{i:0;s:34:"Alexander Hotel/Condo-New Contract";i:1;a:2:{i:0;s:16:"contractTypeCstm";i:1;s:5:"value";}i:2;N;i:3;s:3:"New";}'),
(1610, 19, 1, '2016-01-19 14:17:01', 'Item Modified', 'ZurmoModule', 'Contract', 'a:4:{i:0;s:19:"Aventi-New Contract";i:1;a:2:{i:0;s:16:"contractTypeCstm";i:1;s:5:"value";}i:2;N;i:3;s:3:"New";}'),
(1611, 20, 1, '2016-01-19 14:17:01', 'Item Modified', 'ZurmoModule', 'Contract', 'a:4:{i:0;s:27:"Balmoral Condo-New Contract";i:1;a:2:{i:0;s:16:"contractTypeCstm";i:1;s:5:"value";}i:2;N;i:3;s:3:"New";}'),
(1612, 29, 1, '2016-01-19 14:17:01', 'Item Created', 'ZurmoModule', 'GameBadge', 's:19:"MassEditContracts 1";'),
(1613, 22, 1, '2016-01-19 14:17:02', 'Item Modified', 'ZurmoModule', 'Contract', 'a:4:{i:0;s:30:"Christopher House-New Contract";i:1;a:2:{i:0;s:16:"contractTypeCstm";i:1;s:5:"value";}i:2;N;i:3;s:3:"New";}'),
(1614, 21, 1, '2016-01-19 14:17:02', 'Item Modified', 'ZurmoModule', 'Contract', 'a:4:{i:0;s:28:"Bravura 1 Condo-New Contract";i:1;a:2:{i:0;s:16:"contractTypeCstm";i:1;s:5:"value";}i:2;N;i:3;s:3:"New";}'),
(1615, 24, 1, '2016-01-19 14:19:42', 'Item Modified', 'ZurmoModule', 'Contract', 'a:4:{i:0;s:33:"Commodore Club South-New Contract";i:1;a:2:{i:0;s:16:"contractTypeCstm";i:1;s:5:"value";}i:2;N;i:3;s:3:"New";}'),
(1616, 25, 1, '2016-01-19 14:19:42', 'Item Modified', 'ZurmoModule', 'Contract', 'a:4:{i:0;s:28:"Commodore Plaza-New Contract";i:1;a:2:{i:0;s:16:"contractTypeCstm";i:1;s:5:"value";}i:2;N;i:3;s:3:"New";}'),
(1617, 26, 1, '2016-01-19 14:19:42', 'Item Modified', 'ZurmoModule', 'Contract', 'a:4:{i:0;s:27:"Cypress Trails-New Contract";i:1;a:2:{i:0;s:16:"contractTypeCstm";i:1;s:5:"value";}i:2;N;i:3;s:3:"New";}'),
(1618, 27, 1, '2016-01-19 14:19:42', 'Item Modified', 'ZurmoModule', 'Contract', 'a:4:{i:0;s:31:"East Pointe Towers-New Contract";i:1;a:2:{i:0;s:16:"contractTypeCstm";i:1;s:5:"value";}i:2;N;i:3;s:3:"New";}'),
(1619, 29, 1, '2016-01-19 14:19:42', 'Item Modified', 'ZurmoModule', 'Contract', 'a:4:{i:0;s:32:"Fairways of Tamarac-New Contract";i:1;a:2:{i:0;s:16:"contractTypeCstm";i:1;s:5:"value";}i:2;N;i:3;s:3:"New";}'),
(1620, 32, 1, '2016-01-19 14:19:44', 'Item Modified', 'ZurmoModule', 'Contract', 'a:4:{i:0;s:26:"Harbour House-New Contract";i:1;a:2:{i:0;s:16:"contractTypeCstm";i:1;s:5:"value";}i:2;N;i:3;s:3:"New";}'),
(1621, 33, 1, '2016-01-19 14:19:44', 'Item Modified', 'ZurmoModule', 'Contract', 'a:4:{i:0;s:27:"Hillsboro Cove-New Contract";i:1;a:2:{i:0;s:16:"contractTypeCstm";i:1;s:5:"value";}i:2;N;i:3;s:3:"New";}'),
(1622, 34, 1, '2016-01-19 14:19:44', 'Item Modified', 'ZurmoModule', 'Contract', 'a:4:{i:0;s:31:"Isles at Grand Bay-New Contract";i:1;a:2:{i:0;s:16:"contractTypeCstm";i:1;s:5:"value";}i:2;N;i:3;s:3:"New";}'),
(1623, 36, 1, '2016-01-19 14:19:44', 'Item Modified', 'ZurmoModule', 'Contract', 'a:4:{i:0;s:22:"Key Largo-New Contract";i:1;a:2:{i:0;s:16:"contractTypeCstm";i:1;s:5:"value";}i:2;N;i:3;s:3:"New";}'),
(1624, 38, 1, '2016-01-19 14:19:44', 'Item Modified', 'ZurmoModule', 'Contract', 'a:4:{i:0;s:31:"Lakes of Savannah -New Contract";i:1;a:2:{i:0;s:16:"contractTypeCstm";i:1;s:5:"value";}i:2;N;i:3;s:3:"New";}'),
(1625, 39, 1, '2016-01-19 14:19:45', 'Item Modified', 'ZurmoModule', 'Contract', 'a:4:{i:0;s:23:"Las Verdes-New Contract";i:1;a:2:{i:0;s:16:"contractTypeCstm";i:1;s:5:"value";}i:2;N;i:3;s:3:"New";}'),
(1626, 41, 1, '2016-01-19 14:19:45', 'Item Modified', 'ZurmoModule', 'Contract', 'a:4:{i:0;s:32:"Mayfair House Condo-New Contract";i:1;a:2:{i:0;s:16:"contractTypeCstm";i:1;s:5:"value";}i:2;N;i:3;s:3:"New";}'),
(1627, 42, 1, '2016-01-19 14:19:45', 'Item Modified', 'ZurmoModule', 'Contract', 'a:4:{i:0;s:28:"Meadowbrook # 4-New Contract";i:1;a:2:{i:0;s:16:"contractTypeCstm";i:1;s:5:"value";}i:2;N;i:3;s:3:"New";}'),
(1628, 43, 1, '2016-01-19 14:19:45', 'Item Modified', 'ZurmoModule', 'Contract', 'a:4:{i:0;s:26:"Midtown Doral-New Contract";i:1;a:2:{i:0;s:16:"contractTypeCstm";i:1;s:5:"value";}i:2;N;i:3;s:3:"New";}'),
(1629, 13, 1, '2016-01-19 14:19:45', 'Item Modified', 'ZurmoModule', 'Contract', 'a:4:{i:0;s:27:"Midtown Retail-New Contract";i:1;a:2:{i:0;s:16:"contractTypeCstm";i:1;s:5:"value";}i:2;N;i:3;s:3:"New";}'),
(1630, 44, 1, '2016-01-19 14:19:46', 'Item Modified', 'ZurmoModule', 'Contract', 'a:4:{i:0;s:27:"Midtown Retail-New Contract";i:1;a:2:{i:0;s:16:"contractTypeCstm";i:1;s:5:"value";}i:2;N;i:3;s:3:"New";}'),
(1631, 45, 1, '2016-01-19 14:19:46', 'Item Modified', 'ZurmoModule', 'Contract', 'a:4:{i:0;s:25:"Mystic Point-New Contract";i:1;a:2:{i:0;s:16:"contractTypeCstm";i:1;s:5:"value";}i:2;N;i:3;s:3:"New";}'),
(1632, 46, 1, '2016-01-19 14:19:46', 'Item Modified', 'ZurmoModule', 'Contract', 'a:4:{i:0;s:28:"Nirvana Condos -New Contract";i:1;a:2:{i:0;s:16:"contractTypeCstm";i:1;s:5:"value";}i:2;N;i:3;s:3:"New";}'),
(1633, 48, 1, '2016-01-19 14:19:46', 'Item Modified', 'ZurmoModule', 'Contract', 'a:4:{i:0;s:22:"OakBridge-New Contract";i:1;a:2:{i:0;s:16:"contractTypeCstm";i:1;s:5:"value";}i:2;N;i:3;s:3:"New";}'),
(1634, 49, 1, '2016-01-19 14:19:46', 'Item Modified', 'ZurmoModule', 'Contract', 'a:4:{i:0;s:24:"Ocean Place-New Contract";i:1;a:2:{i:0;s:16:"contractTypeCstm";i:1;s:5:"value";}i:2;N;i:3;s:3:"New";}'),
(1635, 52, 1, '2016-01-19 14:19:47', 'Item Modified', 'ZurmoModule', 'Contract', 'a:4:{i:0;s:25:"Parker Plaza-New Contract";i:1;a:2:{i:0;s:16:"contractTypeCstm";i:1;s:5:"value";}i:2;N;i:3;s:3:"New";}'),
(1636, 53, 1, '2016-01-19 14:19:48', 'Item Modified', 'ZurmoModule', 'Contract', 'a:4:{i:0;s:42:"Patrician of the Palm Beaches-New Contract";i:1;a:2:{i:0;s:16:"contractTypeCstm";i:1;s:5:"value";}i:2;N;i:3;s:3:"New";}'),
(1637, 54, 1, '2016-01-19 14:19:48', 'Item Modified', 'ZurmoModule', 'Contract', 'a:4:{i:0;s:29:"Pine Ridge Condo-New Contract";i:1;a:2:{i:0;s:16:"contractTypeCstm";i:1;s:5:"value";}i:2;N;i:3;s:3:"New";}'),
(1638, 56, 1, '2016-01-19 14:19:48', 'Item Modified', 'ZurmoModule', 'Contract', 'a:4:{i:0;s:33:"Plaza of Bal Harbour-New Contract";i:1;a:2:{i:0;s:16:"contractTypeCstm";i:1;s:5:"value";}i:2;N;i:3;s:3:"New";}'),
(1639, 57, 1, '2016-01-19 14:19:48', 'Item Modified', 'ZurmoModule', 'Contract', 'a:4:{i:0;s:29:"Point East Condo-New Contract";i:1;a:2:{i:0;s:16:"contractTypeCstm";i:1;s:5:"value";}i:2;N;i:3;s:3:"New";}'),
(1640, 58, 1, '2016-01-19 14:19:48', 'Item Modified', 'ZurmoModule', 'Contract', 'a:4:{i:0;s:25:"River Bridge-New Contract";i:1;a:2:{i:0;s:16:"contractTypeCstm";i:1;s:5:"value";}i:2;N;i:3;s:3:"New";}'),
(1641, 59, 1, '2016-01-19 14:19:48', 'Item Modified', 'ZurmoModule', 'Contract', 'a:4:{i:0;s:43:"Sand Pebble Beach Condominiums-New Contract";i:1;a:2:{i:0;s:16:"contractTypeCstm";i:1;s:5:"value";}i:2;N;i:3;s:3:"New";}'),
(1642, 61, 1, '2016-01-19 14:19:48', 'Item Modified', 'ZurmoModule', 'Contract', 'a:4:{i:0;s:30:"Strada 315 (Data)-New Contract";i:1;a:2:{i:0;s:16:"contractTypeCstm";i:1;s:5:"value";}i:2;N;i:3;s:3:"New";}'),
(1643, 62, 1, '2016-01-19 14:19:48', 'Item Modified', 'ZurmoModule', 'Contract', 'a:4:{i:0;s:31:"Strada 315 (Video)-New Contract";i:1;a:2:{i:0;s:16:"contractTypeCstm";i:1;s:5:"value";}i:2;N;i:3;s:3:"New";}'),
(1644, 63, 1, '2016-01-19 14:19:48', 'Item Modified', 'ZurmoModule', 'Contract', 'a:4:{i:0;s:30:"Sunset Bay (Data)-New Contract";i:1;a:2:{i:0;s:16:"contractTypeCstm";i:1;s:5:"value";}i:2;N;i:3;s:3:"New";}'),
(1645, 64, 1, '2016-01-19 14:19:49', 'Item Modified', 'ZurmoModule', 'Contract', 'a:4:{i:0;s:31:"Sunset Bay (Video)-New Contract";i:1;a:2:{i:0;s:16:"contractTypeCstm";i:1;s:5:"value";}i:2;N;i:3;s:3:"New";}'),
(1646, 68, 1, '2016-01-19 14:19:49', 'Item Modified', 'ZurmoModule', 'Contract', 'a:4:{i:0;s:42:"The Tides @ Bridgeside Square-New Contract";i:1;a:2:{i:0;s:16:"contractTypeCstm";i:1;s:5:"value";}i:2;N;i:3;s:3:"New";}'),
(1647, 65, 1, '2016-01-19 14:19:49', 'Item Modified', 'ZurmoModule', 'Contract', 'a:4:{i:0;s:24:"The Atriums-New Contract";i:1;a:2:{i:0;s:16:"contractTypeCstm";i:1;s:5:"value";}i:2;N;i:3;s:3:"New";}'),
(1648, 69, 1, '2016-01-19 14:19:49', 'Item Modified', 'ZurmoModule', 'Contract', 'a:4:{i:0;s:24:"Topaz North-New Contract";i:1;a:2:{i:0;s:16:"contractTypeCstm";i:1;s:5:"value";}i:2;N;i:3;s:3:"New";}'),
(1649, 70, 1, '2016-01-19 14:19:49', 'Item Modified', 'ZurmoModule', 'Contract', 'a:4:{i:0;s:35:"TOWERS OF KENDAL LAKES-New Contract";i:1;a:2:{i:0;s:16:"contractTypeCstm";i:1;s:5:"value";}i:2;N;i:3;s:3:"New";}'),
(1650, 71, 1, '2016-01-19 14:19:50', 'Item Modified', 'ZurmoModule', 'Contract', 'a:4:{i:0;s:26:"Tropic Harbor-New Contract";i:1;a:2:{i:0;s:16:"contractTypeCstm";i:1;s:5:"value";}i:2;N;i:3;s:3:"New";}'),
(1651, 40, 1, '2016-01-19 14:20:42', 'Item Created', 'ZurmoModule', 'GameScore', 's:14:"SearchContract";'),
(1652, 30, 1, '2016-01-19 14:20:42', 'Item Created', 'ZurmoModule', 'GameBadge', 's:17:"SearchContracts 1";'),
(1653, 22, 1, '2016-01-19 14:22:20', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:10:"3360 Condo";i:1;s:19:"OpportunitiesModule";}'),
(1654, 15, 1, '2016-01-19 14:24:03', 'Item Modified', 'ZurmoModule', 'Contract', 'a:4:{i:0;s:39:"400 Association (Data)-Renewal Contract";i:1;a:2:{i:0;s:16:"contractTypeCstm";i:1;s:5:"value";}i:2;N;i:3;s:7:"Renewal";}'),
(1655, 16, 1, '2016-01-19 14:24:03', 'Item Modified', 'ZurmoModule', 'Contract', 'a:4:{i:0;s:31:"9 Island (Net)-Renewal Contract";i:1;a:2:{i:0;s:16:"contractTypeCstm";i:1;s:5:"value";}i:2;N;i:3;s:7:"Renewal";}'),
(1656, 23, 1, '2016-01-19 14:24:03', 'Item Modified', 'ZurmoModule', 'Contract', 'a:4:{i:0;s:32:"Cloisters (Net)-Renewal Contract";i:1;a:2:{i:0;s:16:"contractTypeCstm";i:1;s:5:"value";}i:2;N;i:3;s:7:"Renewal";}'),
(1657, 28, 1, '2016-01-19 14:24:03', 'Item Modified', 'ZurmoModule', 'Contract', 'a:4:{i:0;s:30:"Emerald (Net)-Renewal Contract";i:1;a:2:{i:0;s:16:"contractTypeCstm";i:1;s:5:"value";}i:2;N;i:3;s:7:"Renewal";}'),
(1658, 30, 1, '2016-01-19 14:24:03', 'Item Modified', 'ZurmoModule', 'Contract', 'a:4:{i:0;s:37:"Garden Estates (Net)-Renewal Contract";i:1;a:2:{i:0;s:16:"contractTypeCstm";i:1;s:5:"value";}i:2;N;i:3;s:7:"Renewal";}'),
(1659, 31, 1, '2016-01-19 14:24:05', 'Item Modified', 'ZurmoModule', 'Contract', 'a:4:{i:0;s:42:"Glades Country Club (Net)-Renewal Contract";i:1;a:2:{i:0;s:16:"contractTypeCstm";i:1;s:5:"value";}i:2;N;i:3;s:7:"Renewal";}'),
(1660, 35, 1, '2016-01-19 14:24:05', 'Item Modified', 'ZurmoModule', 'Contract', 'a:4:{i:0;s:33:"Kenilworth (Net)-Renewal Contract";i:1;a:2:{i:0;s:16:"contractTypeCstm";i:1;s:5:"value";}i:2;N;i:3;s:7:"Renewal";}'),
(1661, 37, 1, '2016-01-19 14:24:05', 'Item Modified', 'ZurmoModule', 'Contract', 'a:4:{i:0;s:34:"Lake Worth Towers-Renewal Contract";i:1;a:2:{i:0;s:16:"contractTypeCstm";i:1;s:5:"value";}i:2;N;i:3;s:7:"Renewal";}'),
(1662, 40, 1, '2016-01-19 14:24:05', 'Item Modified', 'ZurmoModule', 'Contract', 'a:4:{i:0;s:37:"Marina Village (Net)-Renewal Contract";i:1;a:2:{i:0;s:16:"contractTypeCstm";i:1;s:5:"value";}i:2;N;i:3;s:7:"Renewal";}'),
(1663, 47, 1, '2016-01-19 14:24:05', 'Item Modified', 'ZurmoModule', 'Contract', 'a:4:{i:0;s:36:"Northern Star (Net)-Renewal Contract";i:1;a:2:{i:0;s:16:"contractTypeCstm";i:1;s:5:"value";}i:2;N;i:3;s:7:"Renewal";}'),
(1664, 55, 1, '2016-01-19 14:24:06', 'Item Modified', 'ZurmoModule', 'Contract', 'a:4:{i:0;s:37:"Pinehurst Club (Net)-Renewal Contract";i:1;a:2:{i:0;s:16:"contractTypeCstm";i:1;s:5:"value";}i:2;N;i:3;s:7:"Renewal";}'),
(1665, 60, 1, '2016-01-19 14:24:06', 'Item Modified', 'ZurmoModule', 'Contract', 'a:4:{i:0;s:30:"Seamark (Net)-Renewal Contract";i:1;a:2:{i:0;s:16:"contractTypeCstm";i:1;s:5:"value";}i:2;N;i:3;s:7:"Renewal";}'),
(1666, 66, 1, '2016-01-19 14:24:06', 'Item Modified', 'ZurmoModule', 'Contract', 'a:4:{i:0;s:64:"The Residences on Hollywood Beach Proposal (Net)-Renewal Contrac";i:1;a:2:{i:0;s:16:"contractTypeCstm";i:1;s:5:"value";}i:2;N;i:3;s:7:"Renewal";}'),
(1667, 67, 1, '2016-01-19 14:24:06', 'Item Modified', 'ZurmoModule', 'Contract', 'a:4:{i:0;s:33:"The Summit (Net)-Renewal Contract";i:1;a:2:{i:0;s:16:"contractTypeCstm";i:1;s:5:"value";}i:2;N;i:3;s:7:"Renewal";}'),
(1668, 14, 1, '2016-01-19 18:05:58', 'Item Viewed', 'ZurmoModule', 'Contract', 'a:2:{i:0;s:23:"3360 Condo-New Contract";i:1;s:15:"ContractsModule";}'),
(1669, 22, 1, '2016-01-19 18:06:28', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:10:"3360 Condo";i:1;s:19:"OpportunitiesModule";}'),
(1670, 22, 1, '2016-01-19 18:08:42', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:10:"3360 Condo";i:1;s:19:"OpportunitiesModule";}'),
(1671, 41, 1, '2016-01-19 18:14:09', 'Item Created', 'ZurmoModule', 'GameScore', 's:17:"SearchOpportunity";'),
(1672, 31, 1, '2016-01-19 18:14:09', 'Item Created', 'ZurmoModule', 'GameBadge', 's:21:"SearchOpportunities 1";'),
(1673, 75, 1, '2016-01-19 18:14:20', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:16:"The Summit (Net)";i:1;s:19:"OpportunitiesModule";}'),
(1674, 42, 1, '2016-01-19 18:45:59', 'Item Created', 'ZurmoModule', 'GameScore', 's:19:"MassEditOpportunity";'),
(1675, 42, 1, '2016-01-19 18:45:59', 'Item Modified', 'ZurmoModule', 'Opportunity', 'a:4:{i:0;s:18:"Isles at Grand Bay";i:1;a:1:{i:0;s:9:"closeDate";}i:2;s:10:"2016-01-01";i:3;s:10:"2016-09-30";}');
INSERT INTO `auditevent` (`id`, `modelid`, `_user_id`, `datetime`, `eventname`, `modulename`, `modelclassname`, `serializeddata`) VALUES
(1676, 75, 1, '2016-01-19 18:45:59', 'Item Modified', 'ZurmoModule', 'Opportunity', 'a:4:{i:0;s:16:"The Summit (Net)";i:1;a:1:{i:0;s:9:"closeDate";}i:2;s:10:"2016-01-01";i:3;s:10:"2016-09-30";}'),
(1677, 32, 1, '2016-01-19 18:45:59', 'Item Created', 'ZurmoModule', 'GameBadge', 's:23:"MassEditOpportunities 1";'),
(1678, 22, 1, '2016-01-19 18:49:32', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:10:"3360 Condo";i:1;s:19:"OpportunitiesModule";}'),
(1679, 23, 1, '2016-01-19 18:49:35', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:22:"400 Association (Data)";i:1;s:19:"OpportunitiesModule";}'),
(1680, 24, 1, '2016-01-19 18:49:37', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:14:"9 Island (Net)";i:1;s:19:"OpportunitiesModule";}'),
(1681, 25, 1, '2016-01-19 18:49:39', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:21:"Alexander Hotel/Condo";i:1;s:19:"OpportunitiesModule";}'),
(1682, 26, 1, '2016-01-19 18:49:40', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:7:"Artesia";i:1;s:19:"OpportunitiesModule";}'),
(1683, 27, 1, '2016-01-19 18:49:43', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:6:"Aventi";i:1;s:19:"OpportunitiesModule";}'),
(1684, 28, 1, '2016-01-19 18:49:44', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:14:"Balmoral Condo";i:1;s:19:"OpportunitiesModule";}'),
(1685, 29, 1, '2016-01-19 18:49:46', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:15:"Bravura 1 Condo";i:1;s:19:"OpportunitiesModule";}'),
(1686, 30, 1, '2016-01-19 18:49:47', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:17:"Christopher House";i:1;s:19:"OpportunitiesModule";}'),
(1687, 31, 1, '2016-01-19 18:49:50', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:15:"Cloisters (Net)";i:1;s:19:"OpportunitiesModule";}'),
(1688, 32, 1, '2016-01-19 18:49:52', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:20:"Commodore Club South";i:1;s:19:"OpportunitiesModule";}'),
(1689, 33, 1, '2016-01-19 18:49:53', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:15:"Commodore Plaza";i:1;s:19:"OpportunitiesModule";}'),
(1690, 22, 1, '2016-01-19 18:52:31', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:10:"3360 Condo";i:1;s:19:"OpportunitiesModule";}'),
(1691, 22, 1, '2016-01-19 18:52:54', 'Item Modified', 'ZurmoModule', 'Opportunity', 'a:4:{i:0;s:10:"3360 Condo";i:1;a:1:{i:0;s:9:"closeDate";}i:2;s:10:"2015-11-01";i:3;s:10:"2015-12-31";}'),
(1692, 22, 1, '2016-01-19 18:52:55', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:10:"3360 Condo";i:1;s:19:"OpportunitiesModule";}'),
(1693, 23, 1, '2016-01-19 18:53:35', 'Item Modified', 'ZurmoModule', 'Opportunity', 'a:4:{i:0;s:22:"400 Association (Data)";i:1;a:1:{i:0;s:9:"closeDate";}i:2;s:10:"2016-01-01";i:3;s:10:"2015-03-31";}'),
(1694, 23, 1, '2016-01-19 18:53:36', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:22:"400 Association (Data)";i:1;s:19:"OpportunitiesModule";}'),
(1695, 14, 1, '2016-01-19 18:54:18', 'Item Viewed', 'ZurmoModule', 'Contract', 'a:2:{i:0;s:23:"3360 Condo-New Contract";i:1;s:15:"ContractsModule";}'),
(1696, 14, 1, '2016-01-19 19:18:30', 'Item Modified', 'ZurmoModule', 'Contract', 'a:4:{i:0;s:23:"3360 Condo-New Contract";i:1;a:1:{i:0;s:9:"closeDate";}i:2;s:10:"2016-01-01";i:3;s:10:"2020-01-01";}'),
(1697, 15, 1, '2016-01-19 19:18:30', 'Item Modified', 'ZurmoModule', 'Contract', 'a:4:{i:0;s:39:"400 Association (Data)-Renewal Contract";i:1;a:1:{i:0;s:9:"closeDate";}i:2;s:10:"2016-01-01";i:3;s:10:"2020-01-01";}'),
(1698, 16, 1, '2016-01-19 19:18:30', 'Item Modified', 'ZurmoModule', 'Contract', 'a:4:{i:0;s:31:"9 Island (Net)-Renewal Contract";i:1;a:1:{i:0;s:9:"closeDate";}i:2;s:10:"2016-01-01";i:3;s:10:"2020-01-01";}'),
(1699, 17, 1, '2016-01-19 19:18:30', 'Item Modified', 'ZurmoModule', 'Contract', 'a:4:{i:0;s:34:"Alexander Hotel/Condo-New Contract";i:1;a:1:{i:0;s:9:"closeDate";}i:2;s:10:"2016-01-01";i:3;s:10:"2020-01-01";}'),
(1700, 18, 1, '2016-01-19 19:18:30', 'Item Modified', 'ZurmoModule', 'Contract', 'a:4:{i:0;s:20:"Artesia-New Contract";i:1;a:1:{i:0;s:9:"closeDate";}i:2;s:10:"2016-01-01";i:3;s:10:"2020-01-01";}'),
(1701, 19, 1, '2016-01-19 19:18:31', 'Item Modified', 'ZurmoModule', 'Contract', 'a:4:{i:0;s:19:"Aventi-New Contract";i:1;a:1:{i:0;s:9:"closeDate";}i:2;s:10:"2016-01-01";i:3;s:10:"2020-01-01";}'),
(1702, 20, 1, '2016-01-19 19:18:31', 'Item Modified', 'ZurmoModule', 'Contract', 'a:4:{i:0;s:27:"Balmoral Condo-New Contract";i:1;a:1:{i:0;s:9:"closeDate";}i:2;s:10:"2016-01-01";i:3;s:10:"2020-01-01";}'),
(1703, 21, 1, '2016-01-19 19:18:31', 'Item Modified', 'ZurmoModule', 'Contract', 'a:4:{i:0;s:28:"Bravura 1 Condo-New Contract";i:1;a:1:{i:0;s:9:"closeDate";}i:2;s:10:"2016-01-01";i:3;s:10:"2020-01-01";}'),
(1704, 22, 1, '2016-01-19 19:18:31', 'Item Modified', 'ZurmoModule', 'Contract', 'a:4:{i:0;s:30:"Christopher House-New Contract";i:1;a:1:{i:0;s:9:"closeDate";}i:2;s:10:"2016-01-01";i:3;s:10:"2020-01-01";}'),
(1705, 23, 1, '2016-01-19 19:18:31', 'Item Modified', 'ZurmoModule', 'Contract', 'a:4:{i:0;s:32:"Cloisters (Net)-Renewal Contract";i:1;a:1:{i:0;s:9:"closeDate";}i:2;s:10:"2016-01-01";i:3;s:10:"2020-01-01";}'),
(1706, 24, 1, '2016-01-19 19:18:32', 'Item Modified', 'ZurmoModule', 'Contract', 'a:4:{i:0;s:33:"Commodore Club South-New Contract";i:1;a:1:{i:0;s:9:"closeDate";}i:2;s:10:"2016-01-01";i:3;s:10:"2020-01-01";}'),
(1707, 25, 1, '2016-01-19 19:18:32', 'Item Modified', 'ZurmoModule', 'Contract', 'a:4:{i:0;s:28:"Commodore Plaza-New Contract";i:1;a:1:{i:0;s:9:"closeDate";}i:2;s:10:"2016-01-01";i:3;s:10:"2020-01-01";}'),
(1708, 26, 1, '2016-01-19 19:18:32', 'Item Modified', 'ZurmoModule', 'Contract', 'a:4:{i:0;s:27:"Cypress Trails-New Contract";i:1;a:1:{i:0;s:9:"closeDate";}i:2;s:10:"2016-01-01";i:3;s:10:"2020-01-01";}'),
(1709, 27, 1, '2016-01-19 19:18:32', 'Item Modified', 'ZurmoModule', 'Contract', 'a:4:{i:0;s:31:"East Pointe Towers-New Contract";i:1;a:1:{i:0;s:9:"closeDate";}i:2;s:10:"2016-01-01";i:3;s:10:"2020-01-01";}'),
(1710, 28, 1, '2016-01-19 19:18:32', 'Item Modified', 'ZurmoModule', 'Contract', 'a:4:{i:0;s:30:"Emerald (Net)-Renewal Contract";i:1;a:1:{i:0;s:9:"closeDate";}i:2;s:10:"2016-01-01";i:3;s:10:"2020-01-01";}'),
(1711, 29, 1, '2016-01-19 19:18:32', 'Item Modified', 'ZurmoModule', 'Contract', 'a:4:{i:0;s:32:"Fairways of Tamarac-New Contract";i:1;a:1:{i:0;s:9:"closeDate";}i:2;s:10:"2016-01-01";i:3;s:10:"2020-01-01";}'),
(1712, 30, 1, '2016-01-19 19:18:33', 'Item Modified', 'ZurmoModule', 'Contract', 'a:4:{i:0;s:37:"Garden Estates (Net)-Renewal Contract";i:1;a:1:{i:0;s:9:"closeDate";}i:2;s:10:"2016-01-01";i:3;s:10:"2020-01-01";}'),
(1713, 31, 1, '2016-01-19 19:18:33', 'Item Modified', 'ZurmoModule', 'Contract', 'a:4:{i:0;s:42:"Glades Country Club (Net)-Renewal Contract";i:1;a:1:{i:0;s:9:"closeDate";}i:2;s:10:"2016-01-01";i:3;s:10:"2020-01-01";}'),
(1714, 32, 1, '2016-01-19 19:18:33', 'Item Modified', 'ZurmoModule', 'Contract', 'a:4:{i:0;s:26:"Harbour House-New Contract";i:1;a:1:{i:0;s:9:"closeDate";}i:2;s:10:"2016-01-01";i:3;s:10:"2020-01-01";}'),
(1715, 33, 1, '2016-01-19 19:18:33', 'Item Modified', 'ZurmoModule', 'Contract', 'a:4:{i:0;s:27:"Hillsboro Cove-New Contract";i:1;a:1:{i:0;s:9:"closeDate";}i:2;s:10:"2016-01-01";i:3;s:10:"2020-01-01";}'),
(1716, 34, 1, '2016-01-19 19:18:33', 'Item Modified', 'ZurmoModule', 'Contract', 'a:4:{i:0;s:31:"Isles at Grand Bay-New Contract";i:1;a:1:{i:0;s:9:"closeDate";}i:2;s:10:"2016-01-01";i:3;s:10:"2020-01-01";}'),
(1717, 35, 1, '2016-01-19 19:18:33', 'Item Modified', 'ZurmoModule', 'Contract', 'a:4:{i:0;s:33:"Kenilworth (Net)-Renewal Contract";i:1;a:1:{i:0;s:9:"closeDate";}i:2;s:10:"2016-01-01";i:3;s:10:"2020-01-01";}'),
(1718, 36, 1, '2016-01-19 19:18:33', 'Item Modified', 'ZurmoModule', 'Contract', 'a:4:{i:0;s:22:"Key Largo-New Contract";i:1;a:1:{i:0;s:9:"closeDate";}i:2;s:10:"2016-01-01";i:3;s:10:"2020-01-01";}'),
(1719, 37, 1, '2016-01-19 19:18:33', 'Item Modified', 'ZurmoModule', 'Contract', 'a:4:{i:0;s:34:"Lake Worth Towers-Renewal Contract";i:1;a:1:{i:0;s:9:"closeDate";}i:2;s:10:"2016-01-01";i:3;s:10:"2020-01-01";}'),
(1720, 38, 1, '2016-01-19 19:18:33', 'Item Modified', 'ZurmoModule', 'Contract', 'a:4:{i:0;s:31:"Lakes of Savannah -New Contract";i:1;a:1:{i:0;s:9:"closeDate";}i:2;s:10:"2016-01-01";i:3;s:10:"2020-01-01";}'),
(1721, 39, 1, '2016-01-19 19:18:34', 'Item Modified', 'ZurmoModule', 'Contract', 'a:4:{i:0;s:23:"Las Verdes-New Contract";i:1;a:1:{i:0;s:9:"closeDate";}i:2;s:10:"2016-01-01";i:3;s:10:"2020-01-01";}'),
(1722, 40, 1, '2016-01-19 19:18:34', 'Item Modified', 'ZurmoModule', 'Contract', 'a:4:{i:0;s:37:"Marina Village (Net)-Renewal Contract";i:1;a:1:{i:0;s:9:"closeDate";}i:2;s:10:"2016-01-01";i:3;s:10:"2020-01-01";}'),
(1723, 41, 1, '2016-01-19 19:18:34', 'Item Modified', 'ZurmoModule', 'Contract', 'a:4:{i:0;s:32:"Mayfair House Condo-New Contract";i:1;a:1:{i:0;s:9:"closeDate";}i:2;s:10:"2016-01-01";i:3;s:10:"2020-01-01";}'),
(1724, 42, 1, '2016-01-19 19:18:34', 'Item Modified', 'ZurmoModule', 'Contract', 'a:4:{i:0;s:28:"Meadowbrook # 4-New Contract";i:1;a:1:{i:0;s:9:"closeDate";}i:2;s:10:"2016-01-01";i:3;s:10:"2020-01-01";}'),
(1725, 43, 1, '2016-01-19 19:18:34', 'Item Modified', 'ZurmoModule', 'Contract', 'a:4:{i:0;s:26:"Midtown Doral-New Contract";i:1;a:1:{i:0;s:9:"closeDate";}i:2;s:10:"2016-01-01";i:3;s:10:"2020-01-01";}'),
(1726, 13, 1, '2016-01-19 19:18:35', 'Item Modified', 'ZurmoModule', 'Contract', 'a:4:{i:0;s:27:"Midtown Retail-New Contract";i:1;a:1:{i:0;s:9:"closeDate";}i:2;s:10:"2016-01-01";i:3;s:10:"2020-01-01";}'),
(1727, 44, 1, '2016-01-19 19:18:35', 'Item Modified', 'ZurmoModule', 'Contract', 'a:4:{i:0;s:27:"Midtown Retail-New Contract";i:1;a:1:{i:0;s:9:"closeDate";}i:2;s:10:"2016-01-01";i:3;s:10:"2020-01-01";}'),
(1728, 45, 1, '2016-01-19 19:18:35', 'Item Modified', 'ZurmoModule', 'Contract', 'a:4:{i:0;s:25:"Mystic Point-New Contract";i:1;a:1:{i:0;s:9:"closeDate";}i:2;s:10:"2016-01-01";i:3;s:10:"2020-01-01";}'),
(1729, 46, 1, '2016-01-19 19:18:35', 'Item Modified', 'ZurmoModule', 'Contract', 'a:4:{i:0;s:28:"Nirvana Condos -New Contract";i:1;a:1:{i:0;s:9:"closeDate";}i:2;s:10:"2016-01-01";i:3;s:10:"2020-01-01";}'),
(1730, 47, 1, '2016-01-19 19:18:35', 'Item Modified', 'ZurmoModule', 'Contract', 'a:4:{i:0;s:36:"Northern Star (Net)-Renewal Contract";i:1;a:1:{i:0;s:9:"closeDate";}i:2;s:10:"2016-01-01";i:3;s:10:"2020-01-01";}'),
(1731, 48, 1, '2016-01-19 19:18:36', 'Item Modified', 'ZurmoModule', 'Contract', 'a:4:{i:0;s:22:"OakBridge-New Contract";i:1;a:1:{i:0;s:9:"closeDate";}i:2;s:10:"2016-01-01";i:3;s:10:"2020-01-01";}'),
(1732, 49, 1, '2016-01-19 19:18:36', 'Item Modified', 'ZurmoModule', 'Contract', 'a:4:{i:0;s:24:"Ocean Place-New Contract";i:1;a:1:{i:0;s:9:"closeDate";}i:2;s:10:"2016-01-01";i:3;s:10:"2020-01-01";}'),
(1733, 50, 1, '2016-01-19 19:18:36', 'Item Modified', 'ZurmoModule', 'Contract', 'a:4:{i:0;s:29:"Oceanfront Plaza-New Contract";i:1;a:1:{i:0;s:9:"closeDate";}i:2;s:10:"2016-01-01";i:3;s:10:"2020-01-01";}'),
(1734, 51, 1, '2016-01-19 19:18:36', 'Item Modified', 'ZurmoModule', 'Contract', 'a:4:{i:0;s:28:"OceanView Place-New Contract";i:1;a:1:{i:0;s:9:"closeDate";}i:2;s:10:"2016-01-01";i:3;s:10:"2020-01-01";}'),
(1735, 52, 1, '2016-01-19 19:18:36', 'Item Modified', 'ZurmoModule', 'Contract', 'a:4:{i:0;s:25:"Parker Plaza-New Contract";i:1;a:1:{i:0;s:9:"closeDate";}i:2;s:10:"2016-01-01";i:3;s:10:"2020-01-01";}'),
(1736, 53, 1, '2016-01-19 19:18:36', 'Item Modified', 'ZurmoModule', 'Contract', 'a:4:{i:0;s:42:"Patrician of the Palm Beaches-New Contract";i:1;a:1:{i:0;s:9:"closeDate";}i:2;s:10:"2016-01-01";i:3;s:10:"2020-01-01";}'),
(1737, 54, 1, '2016-01-19 19:18:36', 'Item Modified', 'ZurmoModule', 'Contract', 'a:4:{i:0;s:29:"Pine Ridge Condo-New Contract";i:1;a:1:{i:0;s:9:"closeDate";}i:2;s:10:"2016-01-01";i:3;s:10:"2020-01-01";}'),
(1738, 55, 1, '2016-01-19 19:18:36', 'Item Modified', 'ZurmoModule', 'Contract', 'a:4:{i:0;s:37:"Pinehurst Club (Net)-Renewal Contract";i:1;a:1:{i:0;s:9:"closeDate";}i:2;s:10:"2016-01-01";i:3;s:10:"2020-01-01";}'),
(1739, 56, 1, '2016-01-19 19:18:36', 'Item Modified', 'ZurmoModule', 'Contract', 'a:4:{i:0;s:33:"Plaza of Bal Harbour-New Contract";i:1;a:1:{i:0;s:9:"closeDate";}i:2;s:10:"2016-01-01";i:3;s:10:"2020-01-01";}'),
(1740, 57, 1, '2016-01-19 19:18:36', 'Item Modified', 'ZurmoModule', 'Contract', 'a:4:{i:0;s:29:"Point East Condo-New Contract";i:1;a:1:{i:0;s:9:"closeDate";}i:2;s:10:"2016-01-01";i:3;s:10:"2020-01-01";}'),
(1741, 58, 1, '2016-01-19 19:18:37', 'Item Modified', 'ZurmoModule', 'Contract', 'a:4:{i:0;s:25:"River Bridge-New Contract";i:1;a:1:{i:0;s:9:"closeDate";}i:2;s:10:"2016-01-01";i:3;s:10:"2020-01-01";}'),
(1742, 59, 1, '2016-01-19 19:18:37', 'Item Modified', 'ZurmoModule', 'Contract', 'a:4:{i:0;s:43:"Sand Pebble Beach Condominiums-New Contract";i:1;a:1:{i:0;s:9:"closeDate";}i:2;s:10:"2016-01-01";i:3;s:10:"2020-01-01";}'),
(1743, 60, 1, '2016-01-19 19:18:37', 'Item Modified', 'ZurmoModule', 'Contract', 'a:4:{i:0;s:30:"Seamark (Net)-Renewal Contract";i:1;a:1:{i:0;s:9:"closeDate";}i:2;s:10:"2016-01-01";i:3;s:10:"2020-01-01";}'),
(1744, 61, 1, '2016-01-19 19:18:37', 'Item Modified', 'ZurmoModule', 'Contract', 'a:4:{i:0;s:30:"Strada 315 (Data)-New Contract";i:1;a:1:{i:0;s:9:"closeDate";}i:2;s:10:"2016-01-01";i:3;s:10:"2020-01-01";}'),
(1745, 62, 1, '2016-01-19 19:18:37', 'Item Modified', 'ZurmoModule', 'Contract', 'a:4:{i:0;s:31:"Strada 315 (Video)-New Contract";i:1;a:1:{i:0;s:9:"closeDate";}i:2;s:10:"2016-01-01";i:3;s:10:"2020-01-01";}'),
(1746, 63, 1, '2016-01-19 19:18:38', 'Item Modified', 'ZurmoModule', 'Contract', 'a:4:{i:0;s:30:"Sunset Bay (Data)-New Contract";i:1;a:1:{i:0;s:9:"closeDate";}i:2;s:10:"2016-01-01";i:3;s:10:"2020-01-01";}'),
(1747, 64, 1, '2016-01-19 19:18:38', 'Item Modified', 'ZurmoModule', 'Contract', 'a:4:{i:0;s:31:"Sunset Bay (Video)-New Contract";i:1;a:1:{i:0;s:9:"closeDate";}i:2;s:10:"2016-01-01";i:3;s:10:"2020-01-01";}'),
(1748, 65, 1, '2016-01-19 19:18:38', 'Item Modified', 'ZurmoModule', 'Contract', 'a:4:{i:0;s:24:"The Atriums-New Contract";i:1;a:1:{i:0;s:9:"closeDate";}i:2;s:10:"2016-01-01";i:3;s:10:"2020-01-01";}'),
(1749, 66, 1, '2016-01-19 19:18:38', 'Item Modified', 'ZurmoModule', 'Contract', 'a:4:{i:0;s:64:"The Residences on Hollywood Beach Proposal (Net)-Renewal Contrac";i:1;a:1:{i:0;s:9:"closeDate";}i:2;s:10:"2016-01-01";i:3;s:10:"2020-01-01";}'),
(1750, 67, 1, '2016-01-19 19:18:38', 'Item Modified', 'ZurmoModule', 'Contract', 'a:4:{i:0;s:33:"The Summit (Net)-Renewal Contract";i:1;a:1:{i:0;s:9:"closeDate";}i:2;s:10:"2016-01-01";i:3;s:10:"2020-01-01";}'),
(1751, 68, 1, '2016-01-19 19:18:39', 'Item Modified', 'ZurmoModule', 'Contract', 'a:4:{i:0;s:42:"The Tides @ Bridgeside Square-New Contract";i:1;a:1:{i:0;s:9:"closeDate";}i:2;s:10:"2016-01-01";i:3;s:10:"2020-01-01";}'),
(1752, 69, 1, '2016-01-19 19:18:39', 'Item Modified', 'ZurmoModule', 'Contract', 'a:4:{i:0;s:24:"Topaz North-New Contract";i:1;a:1:{i:0;s:9:"closeDate";}i:2;s:10:"2016-01-01";i:3;s:10:"2020-01-01";}'),
(1753, 70, 1, '2016-01-19 19:18:39', 'Item Modified', 'ZurmoModule', 'Contract', 'a:4:{i:0;s:35:"TOWERS OF KENDAL LAKES-New Contract";i:1;a:1:{i:0;s:9:"closeDate";}i:2;s:10:"2016-01-01";i:3;s:10:"2020-01-01";}'),
(1754, 71, 1, '2016-01-19 19:18:39', 'Item Modified', 'ZurmoModule', 'Contract', 'a:4:{i:0;s:26:"Tropic Harbor-New Contract";i:1;a:1:{i:0;s:9:"closeDate";}i:2;s:10:"2016-01-01";i:3;s:10:"2020-01-01";}'),
(1755, NULL, 1, '2016-01-19 19:19:21', 'User Logged Out', 'UsersModule', NULL, 'N;'),
(1756, NULL, 1, '2016-01-19 19:19:28', 'User Logged In', 'UsersModule', NULL, 'N;'),
(1757, 14, 1, '2016-01-19 19:28:38', 'Item Viewed', 'ZurmoModule', 'Contract', 'a:2:{i:0;s:23:"3360 Condo-New Contract";i:1;s:15:"ContractsModule";}'),
(1758, 22, 1, '2016-01-19 19:28:51', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:10:"3360 Condo";i:1;s:19:"OpportunitiesModule";}'),
(1759, 14, 1, '2016-01-19 19:29:02', 'Item Viewed', 'ZurmoModule', 'Contract', 'a:2:{i:0;s:23:"3360 Condo-New Contract";i:1;s:15:"ContractsModule";}'),
(1760, 22, 1, '2016-01-19 19:29:42', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:10:"3360 Condo";i:1;s:19:"OpportunitiesModule";}'),
(1761, 14, 1, '2016-01-19 19:29:47', 'Item Viewed', 'ZurmoModule', 'Contract', 'a:2:{i:0;s:23:"3360 Condo-New Contract";i:1;s:15:"ContractsModule";}'),
(1762, 22, 1, '2016-01-19 19:30:10', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:10:"3360 Condo";i:1;s:19:"OpportunitiesModule";}'),
(1763, 14, 1, '2016-01-19 19:30:21', 'Item Viewed', 'ZurmoModule', 'Contract', 'a:2:{i:0;s:23:"3360 Condo-New Contract";i:1;s:15:"ContractsModule";}'),
(1764, 22, 1, '2016-01-19 19:31:25', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:10:"3360 Condo";i:1;s:19:"OpportunitiesModule";}'),
(1765, 14, 1, '2016-01-19 19:31:59', 'Item Viewed', 'ZurmoModule', 'Contract', 'a:2:{i:0;s:23:"3360 Condo-New Contract";i:1;s:15:"ContractsModule";}'),
(1766, 14, 1, '2016-01-19 19:32:22', 'Item Viewed', 'ZurmoModule', 'Contract', 'a:2:{i:0;s:23:"3360 Condo-New Contract";i:1;s:15:"ContractsModule";}'),
(1767, 22, 1, '2016-01-19 19:32:37', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:10:"3360 Condo";i:1;s:19:"OpportunitiesModule";}'),
(1768, 14, 1, '2016-01-19 19:32:48', 'Item Viewed', 'ZurmoModule', 'Contract', 'a:2:{i:0;s:23:"3360 Condo-New Contract";i:1;s:15:"ContractsModule";}'),
(1769, NULL, 1, '2016-01-19 19:38:19', 'User Logged In', 'UsersModule', NULL, 'N;'),
(1770, 35, 1, '2016-01-19 19:38:28', 'Item Viewed', 'ZurmoModule', 'Account', 'a:2:{i:0;s:10:"3360 Condo";i:1;s:14:"AccountsModule";}'),
(1771, 22, 1, '2016-01-19 19:38:35', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:10:"3360 Condo";i:1;s:19:"OpportunitiesModule";}'),
(1772, 22, 1, '2016-01-19 19:39:13', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:10:"3360 Condo";i:1;s:19:"OpportunitiesModule";}'),
(1773, 14, 1, '2016-01-19 19:39:19', 'Item Viewed', 'ZurmoModule', 'Contract', 'a:2:{i:0;s:23:"3360 Condo-New Contract";i:1;s:15:"ContractsModule";}'),
(1774, 22, 1, '2016-01-19 19:39:39', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:10:"3360 Condo";i:1;s:19:"OpportunitiesModule";}'),
(1775, 22, 1, '2016-01-19 19:41:44', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:10:"3360 Condo";i:1;s:19:"OpportunitiesModule";}'),
(1776, 22, 1, '2016-01-19 19:43:04', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:10:"3360 Condo";i:1;s:19:"OpportunitiesModule";}'),
(1777, 22, 1, '2016-01-19 19:43:42', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:10:"3360 Condo";i:1;s:19:"OpportunitiesModule";}'),
(1778, 71, 1, '2016-01-19 19:43:58', 'Item Created', 'ZurmoModule', 'Account', 's:3:"JEM";'),
(1779, 71, 1, '2016-01-19 19:43:58', 'Item Viewed', 'ZurmoModule', 'Account', 'a:2:{i:0;s:3:"JEM";i:1;s:14:"AccountsModule";}'),
(1780, 35, 1, '2016-01-19 19:45:05', 'Item Viewed', 'ZurmoModule', 'Account', 'a:2:{i:0;s:10:"3360 Condo";i:1;s:14:"AccountsModule";}'),
(1781, 22, 1, '2016-01-19 19:45:14', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:10:"3360 Condo";i:1;s:19:"OpportunitiesModule";}'),
(1782, 22, 1, '2016-01-19 19:45:35', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:10:"3360 Condo";i:1;s:19:"OpportunitiesModule";}'),
(1783, NULL, 1, '2016-01-19 19:49:02', 'User Logged In', 'UsersModule', NULL, 'N;'),
(1784, 35, 1, '2016-01-19 19:49:07', 'Item Viewed', 'ZurmoModule', 'Account', 'a:2:{i:0;s:10:"3360 Condo";i:1;s:14:"AccountsModule";}'),
(1785, 22, 1, '2016-01-19 19:49:11', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:10:"3360 Condo";i:1;s:19:"OpportunitiesModule";}'),
(1786, 22, 1, '2016-01-19 19:49:30', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:10:"3360 Condo";i:1;s:19:"OpportunitiesModule";}'),
(1787, 14, 1, '2016-01-19 19:49:37', 'Item Viewed', 'ZurmoModule', 'Contract', 'a:2:{i:0;s:23:"3360 Condo-New Contract";i:1;s:15:"ContractsModule";}'),
(1788, 22, 1, '2016-01-19 19:49:51', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:10:"3360 Condo";i:1;s:19:"OpportunitiesModule";}'),
(1789, 22, 1, '2016-01-19 19:50:14', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:10:"3360 Condo";i:1;s:19:"OpportunitiesModule";}'),
(1790, 14, 1, '2016-01-19 19:50:19', 'Item Viewed', 'ZurmoModule', 'Contract', 'a:2:{i:0;s:23:"3360 Condo-New Contract";i:1;s:15:"ContractsModule";}'),
(1791, 22, 1, '2016-01-19 19:51:08', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:10:"3360 Condo";i:1;s:19:"OpportunitiesModule";}'),
(1792, 14, 1, '2016-01-19 19:51:14', 'Item Viewed', 'ZurmoModule', 'Contract', 'a:2:{i:0;s:23:"3360 Condo-New Contract";i:1;s:15:"ContractsModule";}'),
(1793, NULL, 1, '2016-01-19 19:51:49', 'User Logged In', 'UsersModule', NULL, 'N;'),
(1794, 35, 1, '2016-01-19 19:52:31', 'Item Viewed', 'ZurmoModule', 'Account', 'a:2:{i:0;s:10:"3360 Condo";i:1;s:14:"AccountsModule";}'),
(1795, 22, 1, '2016-01-19 19:52:36', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:10:"3360 Condo";i:1;s:19:"OpportunitiesModule";}'),
(1796, 22, 1, '2016-01-19 19:52:42', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:10:"3360 Condo";i:1;s:19:"OpportunitiesModule";}'),
(1797, NULL, 1, '2016-01-19 19:54:06', 'User Logged In', 'UsersModule', NULL, 'N;'),
(1798, 35, 1, '2016-01-19 19:54:12', 'Item Viewed', 'ZurmoModule', 'Account', 'a:2:{i:0;s:10:"3360 Condo";i:1;s:14:"AccountsModule";}'),
(1799, 22, 1, '2016-01-19 19:54:17', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:10:"3360 Condo";i:1;s:19:"OpportunitiesModule";}'),
(1800, 22, 1, '2016-01-19 19:54:32', 'Item Modified', 'ZurmoModule', 'Opportunity', 'a:4:{i:0;s:10:"3360 Condo";i:1;a:2:{i:0;s:6:"amount";i:1;s:5:"value";}i:2;s:5:"22500";i:3;s:6:"210960";}'),
(1801, 22, 1, '2016-01-19 19:54:32', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:10:"3360 Condo";i:1;s:19:"OpportunitiesModule";}'),
(1802, 22, 1, '2016-01-19 19:54:39', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:10:"3360 Condo";i:1;s:19:"OpportunitiesModule";}'),
(1803, 14, 1, '2016-01-19 19:54:58', 'Item Viewed', 'ZurmoModule', 'Contract', 'a:2:{i:0;s:23:"3360 Condo-New Contract";i:1;s:15:"ContractsModule";}'),
(1804, 22, 1, '2016-01-19 19:55:07', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:10:"3360 Condo";i:1;s:19:"OpportunitiesModule";}'),
(1805, 14, 1, '2016-01-19 19:55:22', 'Item Modified', 'ZurmoModule', 'Contract', 'a:4:{i:0;s:23:"3360 Condo-New Contract";i:1;a:2:{i:0;s:6:"amount";i:1;s:5:"value";}i:2;s:2:"10";i:3;s:5:"22500";}'),
(1806, 14, 1, '2016-01-19 19:55:23', 'Item Viewed', 'ZurmoModule', 'Contract', 'a:2:{i:0;s:23:"3360 Condo-New Contract";i:1;s:15:"ContractsModule";}'),
(1807, 22, 1, '2016-01-19 19:55:33', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:10:"3360 Condo";i:1;s:19:"OpportunitiesModule";}'),
(1808, 23, 1, '2016-01-19 19:55:54', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:22:"400 Association (Data)";i:1;s:19:"OpportunitiesModule";}'),
(1809, 23, 1, '2016-01-19 19:56:13', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:22:"400 Association (Data)";i:1;s:19:"OpportunitiesModule";}'),
(1810, 23, 1, '2016-01-19 19:56:32', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:22:"400 Association (Data)";i:1;s:19:"OpportunitiesModule";}'),
(1811, 14, 1, '2016-01-19 19:59:32', 'Item Viewed', 'ZurmoModule', 'Contract', 'a:2:{i:0;s:23:"3360 Condo-New Contract";i:1;s:15:"ContractsModule";}'),
(1812, 35, 1, '2016-01-19 19:59:40', 'Item Viewed', 'ZurmoModule', 'Account', 'a:2:{i:0;s:10:"3360 Condo";i:1;s:14:"AccountsModule";}'),
(1813, 35, 1, '2016-01-19 20:04:20', 'Item Viewed', 'ZurmoModule', 'Account', 'a:2:{i:0;s:10:"3360 Condo";i:1;s:14:"AccountsModule";}'),
(1814, 22, 1, '2016-01-19 20:04:24', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:10:"3360 Condo";i:1;s:19:"OpportunitiesModule";}'),
(1815, 22, 1, '2016-01-19 20:05:27', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:10:"3360 Condo";i:1;s:19:"OpportunitiesModule";}'),
(1816, 2, 1, '2016-01-19 20:19:22', 'Item Created', 'ZurmoModule', 'GameCollection', 's:7:"Airport";'),
(1817, 3, 1, '2016-01-19 20:19:22', 'Item Created', 'ZurmoModule', 'GameCollection', 's:10:"Basketball";'),
(1818, 4, 1, '2016-01-19 20:19:22', 'Item Created', 'ZurmoModule', 'GameCollection', 's:7:"Bicycle";'),
(1819, 5, 1, '2016-01-19 20:19:22', 'Item Created', 'ZurmoModule', 'GameCollection', 's:9:"Breakfast";'),
(1820, 6, 1, '2016-01-19 20:19:22', 'Item Created', 'ZurmoModule', 'GameCollection', 's:8:"Business";'),
(1821, 7, 1, '2016-01-19 20:19:22', 'Item Created', 'ZurmoModule', 'GameCollection', 's:8:"Camping2";'),
(1822, 8, 1, '2016-01-19 20:19:22', 'Item Created', 'ZurmoModule', 'GameCollection', 's:7:"Camping";'),
(1823, 9, 1, '2016-01-19 20:19:22', 'Item Created', 'ZurmoModule', 'GameCollection', 's:8:"CarParts";'),
(1824, 10, 1, '2016-01-19 20:19:22', 'Item Created', 'ZurmoModule', 'GameCollection', 's:21:"ChildrenPlayEquipment";'),
(1825, 11, 1, '2016-01-19 20:19:22', 'Item Created', 'ZurmoModule', 'GameCollection', 's:6:"Circus";'),
(1826, 12, 1, '2016-01-19 20:19:22', 'Item Created', 'ZurmoModule', 'GameCollection', 's:7:"Cooking";'),
(1827, 13, 1, '2016-01-19 20:19:22', 'Item Created', 'ZurmoModule', 'GameCollection', 's:6:"Drinks";'),
(1828, 14, 1, '2016-01-19 20:19:22', 'Item Created', 'ZurmoModule', 'GameCollection', 's:9:"Education";'),
(1829, 15, 1, '2016-01-19 20:19:22', 'Item Created', 'ZurmoModule', 'GameCollection', 's:7:"Finance";'),
(1830, 16, 1, '2016-01-19 20:19:22', 'Item Created', 'ZurmoModule', 'GameCollection', 's:4:"Food";'),
(1831, 17, 1, '2016-01-19 20:19:22', 'Item Created', 'ZurmoModule', 'GameCollection', 's:4:"Golf";'),
(1832, 18, 1, '2016-01-19 20:19:22', 'Item Created', 'ZurmoModule', 'GameCollection', 's:6:"Health";'),
(1833, 19, 1, '2016-01-19 20:19:22', 'Item Created', 'ZurmoModule', 'GameCollection', 's:4:"Home";'),
(1834, 20, 1, '2016-01-19 20:19:22', 'Item Created', 'ZurmoModule', 'GameCollection', 's:5:"Hotel";'),
(1835, 21, 1, '2016-01-19 20:19:22', 'Item Created', 'ZurmoModule', 'GameCollection', 's:6:"Office";'),
(1836, 22, 1, '2016-01-19 20:19:22', 'Item Created', 'ZurmoModule', 'GameCollection', 's:6:"Racing";'),
(1837, 23, 1, '2016-01-19 20:19:22', 'Item Created', 'ZurmoModule', 'GameCollection', 's:7:"Science";'),
(1838, 24, 1, '2016-01-19 20:19:22', 'Item Created', 'ZurmoModule', 'GameCollection', 's:6:"Soccer";'),
(1839, 25, 1, '2016-01-19 20:19:22', 'Item Created', 'ZurmoModule', 'GameCollection', 's:11:"SocialMedia";'),
(1840, 26, 1, '2016-01-19 20:19:22', 'Item Created', 'ZurmoModule', 'GameCollection', 's:12:"SummerBeach2";'),
(1841, 27, 1, '2016-01-19 20:19:22', 'Item Created', 'ZurmoModule', 'GameCollection', 's:12:"SummerBeach3";'),
(1842, 28, 1, '2016-01-19 20:19:22', 'Item Created', 'ZurmoModule', 'GameCollection', 's:11:"SummerBeach";'),
(1843, 29, 1, '2016-01-19 20:19:22', 'Item Created', 'ZurmoModule', 'GameCollection', 's:7:"Traffic";'),
(1844, 30, 1, '2016-01-19 20:19:22', 'Item Created', 'ZurmoModule', 'GameCollection', 's:14:"Transportation";'),
(1845, 31, 1, '2016-01-19 20:19:22', 'Item Created', 'ZurmoModule', 'GameCollection', 's:13:"TravelHoliday";'),
(1846, NULL, 1, '2016-01-19 20:20:52', 'User Logged Out', 'UsersModule', NULL, 'N;'),
(1847, NULL, 1, '2016-01-19 20:20:59', 'User Logged In', 'UsersModule', NULL, 'N;'),
(1848, 35, 1, '2016-01-19 20:25:13', 'Item Viewed', 'ZurmoModule', 'Account', 'a:2:{i:0;s:10:"3360 Condo";i:1;s:14:"AccountsModule";}'),
(1849, NULL, 1, '2016-01-19 20:32:02', 'User Logged In', 'UsersModule', NULL, 'N;'),
(1850, 35, 1, '2016-01-19 20:35:12', 'Item Viewed', 'ZurmoModule', 'Account', 'a:2:{i:0;s:10:"3360 Condo";i:1;s:14:"AccountsModule";}'),
(1851, 22, 1, '2016-01-19 20:35:21', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:10:"3360 Condo";i:1;s:19:"OpportunitiesModule";}'),
(1852, 22, 1, '2016-01-19 20:35:39', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:10:"3360 Condo";i:1;s:19:"OpportunitiesModule";}'),
(1853, 3, 1, '2016-01-20 03:55:49', 'Item Modified', 'ZurmoModule', 'Role', 'a:4:{i:0;s:14:"Sales Director";i:1;a:1:{i:0;s:4:"name";}i:2;s:7:"Manager";i:3;s:14:"Sales Director";}'),
(1854, 4, 1, '2016-01-20 03:56:50', 'Item Modified', 'ZurmoModule', 'Role', 'a:4:{i:0;s:13:"Sales Manager";i:1;a:1:{i:0;s:4:"name";}i:2;s:9:"Associate";i:3;s:13:"Sales Manager";}'),
(1855, 23, 1, '2016-01-20 11:59:48', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:22:"400 Association (Data)";i:1;s:19:"OpportunitiesModule";}'),
(1856, 23, 1, '2016-01-20 12:02:09', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:22:"400 Association (Data)";i:1;s:19:"OpportunitiesModule";}'),
(1857, 23, 1, '2016-01-20 12:02:42', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:22:"400 Association (Data)";i:1;s:19:"OpportunitiesModule";}'),
(1858, 23, 1, '2016-01-20 12:38:19', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:22:"400 Association (Data)";i:1;s:19:"OpportunitiesModule";}'),
(1859, 23, 1, '2016-01-20 12:38:33', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:22:"400 Association (Data)";i:1;s:19:"OpportunitiesModule";}'),
(1860, 24, 1, '2016-01-20 12:42:34', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:14:"9 Island (Net)";i:1;s:19:"OpportunitiesModule";}'),
(1861, 24, 1, '2016-01-20 12:43:00', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:14:"9 Island (Net)";i:1;s:19:"OpportunitiesModule";}'),
(1862, 22, 1, '2016-01-20 15:33:47', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:10:"3360 Condo";i:1;s:19:"OpportunitiesModule";}'),
(1863, 1, 1, '2016-01-20 15:43:45', 'Item Viewed', 'ZurmoModule', 'User', 'a:2:{i:0;s:10:"Super User";i:1;s:11:"UsersModule";}'),
(1864, 1, 1, '2016-01-20 15:47:07', 'Item Viewed', 'ZurmoModule', 'User', 'a:2:{i:0;s:10:"Super User";i:1;s:11:"UsersModule";}'),
(1865, 24, 1, '2016-01-20 18:05:27', 'Item Viewed', 'ZurmoModule', 'Opportunity', 'a:2:{i:0;s:14:"9 Island (Net)";i:1;s:19:"OpportunitiesModule";}'),
(1866, 14, 1, '2016-01-20 18:28:51', 'Item Viewed', 'ZurmoModule', 'Contract', 'a:2:{i:0;s:23:"3360 Condo-New Contract";i:1;s:15:"ContractsModule";}');

-- --------------------------------------------------------

--
-- Table structure for table `autoresponder`
--

CREATE TABLE IF NOT EXISTS `autoresponder` (
`id` int(11) unsigned NOT NULL,
  `item_id` int(11) unsigned DEFAULT NULL,
  `subject` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `htmlcontent` text COLLATE utf8_unicode_ci,
  `textcontent` text COLLATE utf8_unicode_ci,
  `enabletracking` tinyint(3) unsigned DEFAULT NULL,
  `secondsfromoperation` int(11) unsigned DEFAULT NULL,
  `operationtype` int(11) DEFAULT NULL,
  `marketinglist_id` int(11) unsigned DEFAULT NULL,
  `fromoperationdurationinterval` int(11) DEFAULT NULL,
  `fromoperationdurationtype` text COLLATE utf8_unicode_ci
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

--
-- Dumping data for table `autoresponder`
--

INSERT INTO `autoresponder` (`id`, `item_id`, `subject`, `htmlcontent`, `textcontent`, `enabletracking`, `secondsfromoperation`, `operationtype`, `marketinglist_id`, `fromoperationdurationinterval`, `fromoperationdurationtype`) VALUES
(2, 95, 'You are now subscribed.', '<p>Thanks for <i>subscribing</i>. You are not gonna <strong>regret</strong> this.</p>', 'Thanks for subscribing. You are not gonna regret this.', 1, 3600, 1, 6, NULL, NULL),
(3, 96, 'You subscribed today.', '<p>So you like <i>our</i> emails so far?</p>', 'So you like our emails so far?', 0, 86400, 1, 4, NULL, NULL),
(4, 97, 'You are now unsubscribed', '<p><strong>You are now unsubscribed. Its really sad to see you go but you can always subscribe</strong></p>', 'You are now unsubscribed. Its really sad to see you go but you can always subscribe', 0, 3600, 2, 6, NULL, NULL),
(5, 98, 'Your unsubscription triggered the next big bang', '<p>So you are <strong>not</strong> coming back?</p>', 'So you are not coming back?', 1, 14400, 2, 5, NULL, NULL);

-- --------------------------------------------------------

--
-- Table structure for table `autoresponderitem`
--

CREATE TABLE IF NOT EXISTS `autoresponderitem` (
`id` int(11) unsigned NOT NULL,
  `contact_id` int(11) unsigned DEFAULT NULL,
  `emailmessage_id` int(11) unsigned DEFAULT NULL,
  `processdatetime` datetime DEFAULT NULL,
  `processed` tinyint(3) unsigned DEFAULT NULL,
  `autoresponder_id` int(11) unsigned DEFAULT NULL
) ENGINE=InnoDB AUTO_INCREMENT=20 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

--
-- Dumping data for table `autoresponderitem`
--

INSERT INTO `autoresponderitem` (`id`, `contact_id`, `emailmessage_id`, `processdatetime`, `processed`, `autoresponder_id`) VALUES
(2, 5, 2, '2013-06-25 11:48:46', 1, 2),
(3, 5, 3, '2013-06-25 14:04:24', 0, 5),
(4, 13, 4, '2013-06-25 11:22:35', 1, 4),
(5, 2, 5, '2013-06-25 11:01:32', 1, 5),
(6, 4, 6, '2013-06-25 13:26:55', 0, 5),
(7, 13, 7, '2013-06-25 12:08:40', 1, 2),
(8, 6, 8, '2013-06-25 10:53:22', 1, 3),
(9, 5, 9, '2013-06-25 10:57:31', 1, 5),
(10, 5, 10, '2013-06-25 13:38:15', 0, 2),
(11, 3, 11, '2013-06-25 11:48:57', 1, 2),
(12, 10, 12, '2013-06-25 11:34:55', 1, 4),
(13, 6, 13, '2013-06-25 11:23:51', 1, 2),
(14, 9, 14, '2013-06-25 12:01:06', 1, 2),
(15, 3, 15, '2013-06-25 13:54:45', 0, 2),
(16, 4, 16, '2013-06-25 11:36:06', 1, 3),
(17, 9, 17, '2013-06-25 13:44:53', 0, 3),
(18, 5, 18, '2013-06-25 13:34:43', 0, 3),
(19, 5, 19, '2013-06-25 12:49:37', 0, 3);

-- --------------------------------------------------------

--
-- Table structure for table `autoresponderitemactivity`
--

CREATE TABLE IF NOT EXISTS `autoresponderitemactivity` (
`id` int(11) unsigned NOT NULL,
  `emailmessageactivity_id` int(11) unsigned DEFAULT NULL,
  `autoresponderitem_id` int(11) unsigned DEFAULT NULL
) ENGINE=InnoDB AUTO_INCREMENT=20 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

--
-- Dumping data for table `autoresponderitemactivity`
--

INSERT INTO `autoresponderitemactivity` (`id`, `emailmessageactivity_id`, `autoresponderitem_id`) VALUES
(2, 4, 7),
(3, 5, 3),
(4, 6, 7),
(5, 7, 4),
(6, 8, 4),
(7, 9, 5),
(8, 10, 18),
(9, 11, 19),
(10, 12, 19),
(11, 13, 19),
(12, 14, 7),
(13, 15, 11),
(14, 16, 6),
(15, 17, 16),
(16, 18, 13),
(17, 19, 19),
(18, 20, 9),
(19, 21, 14);

-- --------------------------------------------------------

--
-- Table structure for table `basecustomfield`
--

CREATE TABLE IF NOT EXISTS `basecustomfield` (
`id` int(11) unsigned NOT NULL,
  `data_customfielddata_id` int(11) unsigned DEFAULT NULL
) ENGINE=InnoDB AUTO_INCREMENT=538 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

--
-- Dumping data for table `basecustomfield`
--

INSERT INTO `basecustomfield` (`id`, `data_customfielddata_id`) VALUES
(2, 8),
(3, 8),
(4, 8),
(5, 8),
(6, 8),
(7, 8),
(8, 8),
(9, 8),
(22, 8),
(23, 2),
(24, 4),
(25, 8),
(26, 2),
(27, 4),
(28, 8),
(29, 2),
(30, 4),
(31, 8),
(32, 2),
(33, 4),
(34, 8),
(35, 2),
(36, 4),
(37, 8),
(38, 2),
(39, 4),
(40, 8),
(41, 2),
(42, 4),
(43, 8),
(44, 2),
(45, 4),
(46, 8),
(47, 2),
(48, 4),
(49, 8),
(50, 2),
(51, 4),
(52, 8),
(53, 2),
(54, 4),
(55, 8),
(56, 2),
(57, 4),
(58, 8),
(59, 2),
(60, 4),
(61, 8),
(62, 2),
(63, 4),
(64, 8),
(65, 2),
(66, 4),
(67, 8),
(68, 2),
(69, 4),
(70, 8),
(71, 2),
(72, 4),
(73, 8),
(74, 2),
(75, 4),
(76, 8),
(77, 2),
(78, 4),
(79, 8),
(80, 2),
(81, 4),
(82, 8),
(83, 2),
(84, 4),
(85, 8),
(86, 2),
(87, 4),
(88, 8),
(89, 2),
(90, 4),
(91, 8),
(92, 2),
(93, 4),
(118, 5),
(119, 5),
(120, 5),
(121, 5),
(122, 5),
(123, 5),
(124, 5),
(125, 5),
(126, 5),
(127, 5),
(128, 5),
(129, 5),
(130, 5),
(131, 5),
(132, 5),
(133, 5),
(134, 5),
(135, 5),
(136, 5),
(137, 5),
(138, 5),
(139, 5),
(140, 5),
(141, 5),
(142, 5),
(143, 5),
(144, 5),
(145, 5),
(146, 5),
(147, 5),
(148, 5),
(149, 5),
(150, 5),
(151, 5),
(152, 5),
(153, 5),
(154, 7),
(155, 7),
(156, 7),
(157, 7),
(158, 7),
(159, 7),
(160, 7),
(161, 7),
(162, 7),
(163, 7),
(164, 7),
(165, 7),
(166, 7),
(167, 7),
(168, 7),
(169, 7),
(170, 7),
(171, 7),
(172, 7),
(173, 7),
(174, 7),
(175, 7),
(176, 7),
(177, 7),
(178, 7),
(179, 7),
(180, 7),
(181, 7),
(182, 7),
(183, 7),
(184, 7),
(185, 7),
(186, 7),
(187, 7),
(188, 7),
(189, 7),
(190, 7),
(191, 7),
(192, 7),
(193, 7),
(194, 7),
(195, 7),
(196, 7),
(197, 7),
(198, 7),
(199, 7),
(200, 7),
(201, 7),
(202, 7),
(203, 7),
(204, 7),
(205, 7),
(206, 7),
(207, 7),
(208, 7),
(209, 7),
(210, 7),
(211, 7),
(212, 7),
(213, 6),
(214, 4),
(215, 6),
(216, 4),
(217, 6),
(218, 4),
(219, 6),
(220, 4),
(221, 6),
(222, 4),
(223, 6),
(224, 4),
(225, 8),
(226, 4),
(227, 5),
(228, 10),
(233, 6),
(234, 14),
(265, 8),
(266, 4),
(282, 10),
(284, 10),
(286, 10),
(287, 10),
(288, 10),
(289, 10),
(290, 10),
(291, 10),
(292, 10),
(293, 10),
(294, 10),
(295, 10),
(296, 10),
(297, 10),
(298, 10),
(299, 10),
(300, 10),
(301, 10),
(302, 10),
(303, 10),
(304, 10),
(305, 10),
(306, 10),
(307, 10),
(308, 10),
(309, 10),
(310, 10),
(311, 10),
(312, 10),
(313, 10),
(314, 10),
(315, 10),
(316, 10),
(317, 10),
(318, 10),
(319, 10),
(320, 10),
(321, 10),
(322, 10),
(323, 10),
(324, 10),
(325, 10),
(326, 10),
(327, 10),
(328, 10),
(329, 10),
(330, 10),
(331, 10),
(332, 10),
(333, 10),
(334, 10),
(335, 10),
(336, 10),
(337, 10),
(338, 10),
(339, 10),
(340, 6),
(341, 11),
(342, 12),
(343, 13),
(344, 6),
(345, 6),
(346, 6),
(347, 6),
(348, 6),
(349, 6),
(350, 6),
(351, 6),
(352, 6),
(353, 6),
(354, 6),
(355, 6),
(356, 6),
(357, 6),
(358, 6),
(359, 6),
(360, 6),
(361, 6),
(362, 6),
(363, 6),
(364, 6),
(365, 6),
(366, 6),
(367, 6),
(368, 6),
(369, 6),
(370, 6),
(371, 6),
(372, 6),
(373, 6),
(374, 6),
(375, 6),
(376, 6),
(377, 6),
(378, 6),
(379, 6),
(380, 6),
(381, 6),
(382, 6),
(383, 6),
(384, 6),
(385, 6),
(386, 6),
(387, 6),
(388, 6),
(389, 6),
(390, 6),
(391, 6),
(392, 6),
(393, 6),
(394, 6),
(395, 6),
(396, 6),
(397, 6),
(398, 6),
(399, 6),
(400, 6),
(401, 6),
(402, 6),
(403, 6),
(404, 6),
(405, 6),
(406, 6),
(407, 6),
(408, 6),
(409, 6),
(410, 6),
(411, 6),
(412, 6),
(413, 6),
(414, 6),
(415, 6),
(416, 6),
(417, 6),
(418, 6),
(419, 6),
(420, 6),
(421, 6),
(422, 6),
(423, 6),
(424, 6),
(425, 6),
(426, 6),
(427, 6),
(428, 6),
(429, 6),
(430, 6),
(431, 6),
(432, 6),
(433, 6),
(434, 6),
(435, 6),
(436, 6),
(437, 6),
(438, 6),
(439, 6),
(440, 6),
(441, 6),
(442, 6),
(443, 6),
(444, 6),
(445, 6),
(446, 6),
(447, 6),
(448, 6),
(449, 6),
(450, 6),
(451, 6),
(452, 6),
(453, 6),
(454, 6),
(455, 6),
(456, 6),
(457, 6),
(458, 6),
(459, 6),
(460, 12),
(461, 13),
(462, 16),
(463, 16),
(464, 17),
(465, 17),
(466, 17),
(467, 17),
(468, 17),
(469, 17),
(470, 17),
(471, 17),
(472, 17),
(473, 17),
(474, 17),
(475, 17),
(476, 17),
(477, 17),
(478, 17),
(479, 17),
(480, 17),
(481, 17),
(482, 17),
(483, 17),
(484, 17),
(485, 17),
(486, 17),
(487, 17),
(488, 17),
(489, 17),
(490, 17),
(491, 17),
(492, 17),
(493, 17),
(494, 17),
(495, 17),
(496, 17),
(497, 17),
(498, 17),
(499, 17),
(500, 17),
(501, 17),
(502, 17),
(503, 17),
(504, 17),
(505, 17),
(506, 17),
(507, 17),
(508, 17),
(509, 17),
(510, 17),
(511, 17),
(512, 17),
(513, 17),
(514, 17),
(515, 17),
(516, 17),
(517, 17),
(518, 17),
(519, 17),
(520, 17),
(521, 12),
(522, 13),
(523, 16),
(524, 16),
(525, 16),
(526, 16),
(527, 16),
(528, 16),
(529, 16),
(530, 10),
(531, 15),
(532, 14),
(533, 11),
(534, 11),
(535, 12),
(536, 13),
(537, 16);

-- --------------------------------------------------------

--
-- Table structure for table `basestarredmodel`
--

CREATE TABLE IF NOT EXISTS `basestarredmodel` (
`id` int(11) unsigned NOT NULL,
  `_user_id` int(11) unsigned DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `bytimeworkflowinqueue`
--

CREATE TABLE IF NOT EXISTS `bytimeworkflowinqueue` (
`id` int(11) unsigned NOT NULL,
  `item_id` int(11) unsigned DEFAULT NULL,
  `savedworkflow_id` int(11) unsigned DEFAULT NULL,
  `modelclassname` varchar(64) COLLATE utf8_unicode_ci DEFAULT NULL,
  `processdatetime` datetime DEFAULT NULL,
  `modelitem_item_id` int(11) unsigned DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `calculatedderivedattributemetadata`
--

CREATE TABLE IF NOT EXISTS `calculatedderivedattributemetadata` (
`id` int(11) unsigned NOT NULL,
  `derivedattributemetadata_id` int(11) unsigned DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `campaign`
--

CREATE TABLE IF NOT EXISTS `campaign` (
`id` int(11) unsigned NOT NULL,
  `ownedsecurableitem_id` int(11) unsigned DEFAULT NULL,
  `name` varchar(64) COLLATE utf8_unicode_ci DEFAULT NULL,
  `supportsrichtext` tinyint(1) unsigned DEFAULT NULL,
  `sendondatetime` datetime DEFAULT NULL,
  `fromname` varchar(64) COLLATE utf8_unicode_ci DEFAULT NULL,
  `fromaddress` varchar(64) COLLATE utf8_unicode_ci DEFAULT NULL,
  `subject` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `htmlcontent` text COLLATE utf8_unicode_ci,
  `textcontent` text COLLATE utf8_unicode_ci,
  `enabletracking` tinyint(3) unsigned DEFAULT NULL,
  `status` int(11) DEFAULT NULL,
  `marketinglist_id` int(11) unsigned DEFAULT NULL
) ENGINE=InnoDB AUTO_INCREMENT=12 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

--
-- Dumping data for table `campaign`
--

INSERT INTO `campaign` (`id`, `ownedsecurableitem_id`, `name`, `supportsrichtext`, `sendondatetime`, `fromname`, `fromaddress`, `subject`, `htmlcontent`, `textcontent`, `enabletracking`, `status`, `marketinglist_id`) VALUES
(2, 61, '10% discount for new clients', 1, '2013-06-25 12:30:21', 'Marketing Team', 'marketing@zurmo.com', 'Special Offer: 10% Discount for new clients', '<p>We are offering <strong>10% discount</strong> on all packages to new clients.</p>', 'We are offering 10% discount on all packages to new clients.', 1, 3, 6),
(3, 62, '5% discount for existing clients', 0, '2013-06-25 12:58:36', 'Sales Team', 'sales@zurmo.com', 'Special Offer: 5% Discount for existing clients', '<p>Existing clients can upgrade to a higher package and enjoy a special one time <strong>5% discount</strong>.</p>', 'Existing clients can upgrade to a higher package and enjoy a special one time 5% discount.', 0, 4, 5),
(4, 63, 'Infrastructure redesign completed', 1, '2013-06-25 12:59:37', 'Development Team', 'development@zurmo.com', 'Infrastructure Redesign Completed', '<p>We have done lot of infrastructure redesign in terms and <strong>seucrity and performance</strong>.</p>', 'We have done lot of infrastructure redesign in terms and seucrity and performance.', 1, 3, 4),
(5, 64, 'Christmas Sale', 0, '2013-06-25 13:06:38', 'Special Offers', 'offers@zurmo.com', 'Jingle Bells and Zurmo Special Christmas Offer', '<p>Brace yourselves. This year santa came bit early with a special gift for you, <strong>25% discount</strong> on all zurmo packages.</p>', 'Brace yourselves. This year santa came bit early with a special gift for you, 25% discount on all zurmo packages.', 0, 1, 4),
(6, 65, 'Zurmo Upgrade Complete', 1, '2013-06-25 13:34:57', 'Support Team', 'support@zurmo.com', 'Zurmo Upgrade to v1.6', '<p>All existing clients have been <strong>upgraded to v1.6</strong> as of now. Please contact support if you face any issues.</p>', 'All existing clients have been upgraded to v1.6 as of now. Please contact support if you face any issues.', 0, 4, 6),
(7, 66, 'Loyalty Program - Special Deals', 0, '2013-06-25 13:46:08', 'Marketing Team', 'info@zurmo.com', 'Special Offer: 10% Discount for new clients', '<p>We are offering <strong>10% discount</strong> on all packages to new clients.</p>', 'We are offering 10% discount on all packages to new clients.', 1, 2, 4),
(8, 67, 'Loyalty Member - Enroll Now', 1, '2013-06-25 12:40:40', 'Sales Team', 'marketing@zurmo.com', 'Special Offer: 5% Discount for existing clients', '<p>Existing clients can upgrade to a higher package and enjoy a special one time <strong>5% discount</strong>.</p>', 'Existing clients can upgrade to a higher package and enjoy a special one time 5% discount.', 1, 4, 3),
(9, 68, 'Loyalty Members - Free Lunch', 1, '2013-06-25 12:30:22', 'Development Team', 'sales@zurmo.com', 'Infrastructure Redesign Completed', '<p>We have done lot of infrastructure redesign in terms and <strong>seucrity and performance</strong>.</p>', 'We have done lot of infrastructure redesign in terms and seucrity and performance.', 0, 4, 5),
(10, 69, 'Loyalty Members - Bring a friend', 1, '2013-06-25 12:59:43', 'Special Offers', 'development@zurmo.com', 'Jingle Bells and Zurmo Special Christmas Offer', '<p>Brace yourselves. This year santa came bit early with a special gift for you, <strong>25% discount</strong> on all zurmo packages.</p>', 'Brace yourselves. This year santa came bit early with a special gift for you, 25% discount on all zurmo packages.', 1, 2, 3),
(11, 70, 'Loyalty Members - Trip to Rome', 0, '2013-06-25 12:51:23', 'Support Team', 'offers@zurmo.com', 'Zurmo Upgrade to v1.6', '<p>All existing clients have been <strong>upgraded to v1.6</strong> as of now. Please contact support if you face any issues.</p>', 'All existing clients have been upgraded to v1.6 as of now. Please contact support if you face any issues.', 0, 1, 6);

-- --------------------------------------------------------

--
-- Table structure for table `campaignitem`
--

CREATE TABLE IF NOT EXISTS `campaignitem` (
`id` int(11) unsigned NOT NULL,
  `contact_id` int(11) unsigned DEFAULT NULL,
  `emailmessage_id` int(11) unsigned DEFAULT NULL,
  `processed` tinyint(3) unsigned DEFAULT NULL,
  `campaign_id` int(11) unsigned DEFAULT NULL
) ENGINE=InnoDB AUTO_INCREMENT=20 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

--
-- Dumping data for table `campaignitem`
--

INSERT INTO `campaignitem` (`id`, `contact_id`, `emailmessage_id`, `processed`, `campaign_id`) VALUES
(2, 7, 20, 1, 4),
(3, 13, 21, 0, 2),
(4, 4, 22, 0, 4),
(5, 9, 23, 0, 11),
(6, 6, 24, 1, 8),
(7, 4, 25, 1, 6),
(8, 5, 26, 0, 9),
(9, 3, 27, 0, 6),
(10, 6, 28, 1, 6),
(11, 10, 29, 1, 9),
(12, 12, 30, 1, 3),
(13, 8, 31, 0, 7),
(14, 11, 32, 0, 10),
(15, 8, 33, 1, 2),
(16, 13, 34, 0, 11),
(17, 2, 35, 1, 2),
(18, 10, 36, 1, 4),
(19, 9, 37, 1, 5);

-- --------------------------------------------------------

--
-- Table structure for table `campaignitemactivity`
--

CREATE TABLE IF NOT EXISTS `campaignitemactivity` (
`id` int(11) unsigned NOT NULL,
  `emailmessageactivity_id` int(11) unsigned DEFAULT NULL,
  `campaignitem_id` int(11) unsigned DEFAULT NULL
) ENGINE=InnoDB AUTO_INCREMENT=20 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

--
-- Dumping data for table `campaignitemactivity`
--

INSERT INTO `campaignitemactivity` (`id`, `emailmessageactivity_id`, `campaignitem_id`) VALUES
(2, 22, 16),
(3, 23, 12),
(4, 24, 14),
(5, 25, 19),
(6, 26, 15),
(7, 27, 11),
(8, 28, 9),
(9, 29, 15),
(10, 30, 13),
(11, 31, 17),
(12, 32, 4),
(13, 33, 10),
(14, 34, 5),
(15, 35, 15),
(16, 36, 3),
(17, 37, 2),
(18, 38, 15),
(19, 39, 9);

-- --------------------------------------------------------

--
-- Table structure for table `campaign_read`
--

CREATE TABLE IF NOT EXISTS `campaign_read` (
  `securableitem_id` int(11) unsigned NOT NULL,
  `munge_id` varchar(12) COLLATE utf8_unicode_ci NOT NULL,
  `count` int(8) unsigned NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

--
-- Dumping data for table `campaign_read`
--

INSERT INTO `campaign_read` (`securableitem_id`, `munge_id`, `count`) VALUES
(62, 'G3', 1),
(63, 'G3', 1),
(64, 'G3', 1),
(65, 'G3', 1),
(66, 'G3', 1),
(67, 'G3', 1),
(68, 'G3', 1),
(69, 'G3', 1),
(70, 'G3', 1),
(71, 'G3', 1);

-- --------------------------------------------------------

--
-- Table structure for table `comment`
--

CREATE TABLE IF NOT EXISTS `comment` (
`id` int(11) unsigned NOT NULL,
  `item_id` int(11) unsigned DEFAULT NULL,
  `description` text COLLATE utf8_unicode_ci,
  `relatedmodel_id` int(11) unsigned DEFAULT NULL,
  `relatedmodel_type` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL
) ENGINE=InnoDB AUTO_INCREMENT=44 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

--
-- Dumping data for table `comment`
--

INSERT INTO `comment` (`id`, `item_id`, `description`, `relatedmodel_id`, `relatedmodel_type`) VALUES
(2, 191, 'Interesting Idea', 2, 'conversation'),
(3, 192, 'I am not sure Mars is best.  What about Titan?  It offers some advantages.', 2, 'conversation'),
(4, 193, 'Are we allowed to hire aliens?', 2, 'conversation'),
(5, 194, 'Some info about Mars: Mars is the fourth planet from the Sun in the Solar System. Named after the Roman god of war, Mars, it is often described as the "Red Planet" as the iron oxide prevalent on its surface gives it a reddish appearance', 2, 'conversation'),
(6, 195, 'Great idea guys. Keep it coming.', 2, 'conversation'),
(7, 197, 'Elephants are cool.', 3, 'conversation'),
(8, 198, 'What about giraffes.  Here is some info: he giraffe (Giraffa camelopardalis) is an African even-toed ungulate mammal, the tallest living terrestrial animal and the largest ruminant. Its specific name refers to its camel-like face and the patches of color on its fur, which bear a vague resemblance to a leopard''s spots.', 3, 'conversation'),
(9, 199, 'I think something like a snake eating a mouse could be funny.', 3, 'conversation'),
(10, 200, 'Great idea guys. Keep it coming.', 3, 'conversation'),
(11, 202, 'That should be fun.  Bring your laptop in case we need you!', 4, 'conversation'),
(12, 203, 'Do not bring your laptop.  That would ruin the fun.', 4, 'conversation'),
(13, 204, 'Make sure you hike up the volcano.', 4, 'conversation'),
(14, 205, 'I want to take a vacation.', 4, 'conversation'),
(15, 206, 'We should have a company retreat in Hawaii.  That would be fun!', 4, 'conversation'),
(16, 207, 'Great idea guys. Keep it coming.', 4, 'conversation'),
(17, 347, 'How about at a museum?', 2, 'mission'),
(18, 348, 'I am going to be out of town, so I can''t attend.', 2, 'mission'),
(19, 349, 'I guess i can take this on.', 2, 'mission'),
(20, 351, 'I don''t even know what this mission is.  Guess I can''t take it.', 3, 'mission'),
(21, 352, 'Always good to save money!', 3, 'mission'),
(22, 354, 'Can I go to a bank to do this?', 4, 'mission'),
(23, 355, 'Yes, a bank will notarize a document for you', 4, 'mission'),
(24, 357, 'Is this for our consulting services?', 5, 'mission'),
(25, 358, 'No, this is for a new offering we will have around our widgets', 5, 'mission'),
(26, 484, 'Dude, get to work', 5, 'socialitem'),
(27, 485, 'Lets get some beers', 5, 'socialitem'),
(28, 487, 'I wish i was in sales..', 6, 'socialitem'),
(29, 488, 'Dude, IT just twiddles their thumbs most of the time anyways :)', 6, 'socialitem'),
(30, 489, 'Yeah whatever..', 6, 'socialitem'),
(31, 490, 'I am in for golf, primarly drinking and riding the cart.', 6, 'socialitem'),
(32, 493, 'I would love us to get this guy as a customer', 7, 'socialitem'),
(33, 494, 'I second that.', 7, 'socialitem'),
(34, 495, 'Would be an amazing case study', 7, 'socialitem'),
(35, 503, 'How about at a museum?', 14, 'socialitem'),
(36, 504, 'I am going to be out of town, so I can''t attend.', 14, 'socialitem'),
(37, 505, 'I guess i can take this on.', 14, 'socialitem'),
(38, 508, 'Did you contact Sarah in client services yet?', 15, 'socialitem'),
(39, 509, 'That is probably a good idea', 15, 'socialitem'),
(40, 510, 'Only if sarah is having a good day', 15, 'socialitem'),
(41, 513, 'Awesome!', 16, 'socialitem'),
(42, 514, 'I second that.', 16, 'socialitem'),
(43, 515, 'You are buying drinks tonight', 16, 'socialitem');

-- --------------------------------------------------------

--
-- Table structure for table `contact`
--

CREATE TABLE IF NOT EXISTS `contact` (
`id` int(11) unsigned NOT NULL,
  `person_id` int(11) unsigned DEFAULT NULL,
  `industry_customfield_id` int(11) unsigned DEFAULT NULL,
  `source_customfield_id` int(11) unsigned DEFAULT NULL,
  `account_id` int(11) unsigned DEFAULT NULL,
  `companyname` varchar(64) COLLATE utf8_unicode_ci DEFAULT NULL,
  `description` text COLLATE utf8_unicode_ci,
  `googlewebtrackingid` text COLLATE utf8_unicode_ci,
  `website` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `secondaryaddress_address_id` int(11) unsigned DEFAULT NULL,
  `secondaryemail_email_id` int(11) unsigned DEFAULT NULL,
  `state_contactstate_id` int(11) unsigned DEFAULT NULL,
  `latestactivitydatetime` datetime DEFAULT NULL
) ENGINE=InnoDB AUTO_INCREMENT=32 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

--
-- Dumping data for table `contact`
--

INSERT INTO `contact` (`id`, `person_id`, `industry_customfield_id`, `source_customfield_id`, `account_id`, `companyname`, `description`, `googlewebtrackingid`, `website`, `secondaryaddress_address_id`, `secondaryemail_email_id`, `state_contactstate_id`, `latestactivitydatetime`) VALUES
(2, 12, 23, 24, 6, NULL, NULL, NULL, 'http://www.GloboChem.com', NULL, NULL, 7, NULL),
(3, 13, 26, 27, 6, NULL, NULL, NULL, 'http://www.GloboChem.com', NULL, NULL, 6, NULL),
(4, 14, 29, 30, 7, NULL, NULL, NULL, 'http://www.WayneEnterprise.com', NULL, NULL, 6, NULL),
(5, 15, 32, 33, 4, NULL, NULL, NULL, 'http://www.SampleInc.com', NULL, NULL, 6, NULL),
(6, 16, 35, 36, 4, NULL, NULL, NULL, 'http://www.SampleInc.com', NULL, NULL, 6, NULL),
(7, 17, 38, 39, 2, NULL, NULL, NULL, 'http://www.Gringotts.com', NULL, NULL, 6, NULL),
(8, 18, 41, 42, 3, NULL, NULL, NULL, 'http://www.BigTBurgersandF.com', NULL, NULL, 7, NULL),
(9, 19, 44, 45, 5, NULL, NULL, NULL, 'http://www.AlliedBiscuit.com', NULL, NULL, 6, NULL),
(10, 20, 47, 48, 7, NULL, NULL, NULL, 'http://www.WayneEnterprise.com', NULL, NULL, 6, NULL),
(11, 21, 50, 51, 3, NULL, NULL, NULL, 'http://www.BigTBurgersandF.com', NULL, NULL, 6, NULL),
(12, 22, 53, 54, 2, NULL, NULL, NULL, 'http://www.Gringotts.com', NULL, NULL, 7, NULL),
(13, 23, 56, 57, 6, NULL, NULL, NULL, 'http://www.GloboChem.com', NULL, NULL, 7, NULL),
(14, 24, 59, 60, NULL, 'Extensive Enterprise', NULL, NULL, 'http://www.company.com', NULL, NULL, 4, NULL),
(15, 25, 62, 63, NULL, 'Flowers By Irene', NULL, NULL, 'http://www.company.com', NULL, NULL, 3, NULL),
(16, 26, 65, 66, NULL, 'ABC Telecom', NULL, NULL, 'http://www.company.com', NULL, NULL, 2, NULL),
(17, 27, 68, 69, NULL, 'C.H. Lavatory and Sons', NULL, NULL, 'http://www.company.com', NULL, NULL, 3, NULL),
(18, 28, 71, 72, NULL, 'Acme Corp', NULL, NULL, 'http://www.company.com', NULL, NULL, 3, NULL),
(19, 29, 74, 75, NULL, 'Minuteman Cafe', NULL, NULL, 'http://www.company.com', NULL, NULL, 5, NULL),
(20, 30, 77, 78, NULL, 'Tessier-Ashpool', NULL, NULL, 'http://www.company.com', NULL, NULL, 4, NULL),
(21, 31, 80, 81, NULL, 'Chotchkies', NULL, NULL, 'http://www.company.com', NULL, NULL, 4, NULL),
(22, 32, 83, 84, NULL, 'Thrift Bank', NULL, NULL, 'http://www.company.com', NULL, NULL, 5, NULL),
(23, 33, 86, 87, NULL, 'Incom Corporation', NULL, NULL, 'http://www.company.com', NULL, NULL, 4, NULL),
(24, 34, 89, 90, NULL, 'Foo Bars', NULL, NULL, 'http://www.company.com', NULL, NULL, 2, NULL),
(25, 35, 92, 93, NULL, 'Krustyco', NULL, NULL, 'http://www.company.com', NULL, NULL, 5, NULL),
(26, 36, NULL, NULL, NULL, 'Acme Corp', NULL, NULL, NULL, NULL, NULL, 7, NULL),
(27, 37, NULL, NULL, NULL, 'Allied Biscuit', NULL, NULL, NULL, NULL, NULL, 7, NULL),
(28, 38, NULL, NULL, NULL, 'BLAND Corporation', NULL, NULL, NULL, NULL, NULL, 7, NULL),
(29, 39, NULL, NULL, NULL, 'Central Perk', NULL, NULL, NULL, NULL, NULL, 7, NULL),
(30, 41, NULL, 226, NULL, NULL, '', NULL, NULL, 41, 42, 6, NULL),
(31, 42, NULL, 263, 11, NULL, '', NULL, NULL, 48, 44, 6, NULL);

-- --------------------------------------------------------

--
-- Table structure for table `contactstarred`
--

CREATE TABLE IF NOT EXISTS `contactstarred` (
`id` int(11) unsigned NOT NULL,
  `basestarredmodel_id` int(11) unsigned DEFAULT NULL,
  `contact_id` int(11) unsigned DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `contactstate`
--

CREATE TABLE IF NOT EXISTS `contactstate` (
`id` int(11) unsigned NOT NULL,
  `name` varchar(64) COLLATE utf8_unicode_ci DEFAULT NULL,
  `serializedlabels` text COLLATE utf8_unicode_ci,
  `order` int(11) DEFAULT NULL
) ENGINE=InnoDB AUTO_INCREMENT=8 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

--
-- Dumping data for table `contactstate`
--

INSERT INTO `contactstate` (`id`, `name`, `serializedlabels`, `order`) VALUES
(2, 'New', NULL, 0),
(3, 'In Progress', NULL, 1),
(4, 'Recycled', NULL, 2),
(5, 'Dead', NULL, 3),
(6, 'Qualified', NULL, 4),
(7, 'Customer', NULL, 5);

-- --------------------------------------------------------

--
-- Table structure for table `contactwebform`
--

CREATE TABLE IF NOT EXISTS `contactwebform` (
`id` int(11) unsigned NOT NULL,
  `ownedsecurableitem_id` int(11) unsigned DEFAULT NULL,
  `defaultstate_contactstate_id` int(11) unsigned DEFAULT NULL,
  `name` text COLLATE utf8_unicode_ci,
  `submitbuttonlabel` text COLLATE utf8_unicode_ci,
  `serializeddata` text COLLATE utf8_unicode_ci,
  `language` varchar(10) COLLATE utf8_unicode_ci DEFAULT NULL,
  `excludestyles` tinyint(3) unsigned DEFAULT NULL,
  `redirecturl` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `defaultowner__user_id` int(11) unsigned DEFAULT NULL,
  `_user_id` int(11) unsigned DEFAULT NULL,
  `enablecaptcha` tinyint(1) unsigned DEFAULT NULL,
  `defaultpermissionsetting` tinyint(11) DEFAULT NULL,
  `defaultpermissiongroupsetting` int(11) DEFAULT NULL
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

--
-- Dumping data for table `contactwebform`
--

INSERT INTO `contactwebform` (`id`, `ownedsecurableitem_id`, `defaultstate_contactstate_id`, `name`, `submitbuttonlabel`, `serializeddata`, `language`, `excludestyles`, `redirecturl`, `defaultowner__user_id`, `_user_id`, `enablecaptcha`, `defaultpermissionsetting`, `defaultpermissiongroupsetting`) VALUES
(2, 282, 7, 'Corporate Web Form', 'Submit', 'a:4:{i:0;s:9:"firstName";i:1;s:8:"lastName";i:2;s:11:"companyName";i:3;s:8:"jobTitle";}', NULL, 0, 'http://zurmo.org', NULL, 9, NULL, NULL, NULL),
(3, 283, 7, 'Sales Portal Web Form', 'Save', 'a:4:{i:0;s:9:"firstName";i:1;s:8:"lastName";i:2;s:11:"companyName";i:3;s:8:"jobTitle";}', NULL, 0, 'http://zurmo.com', NULL, 8, NULL, NULL, NULL),
(4, 284, 7, 'Clients Portal Web Form', 'Save & Redirect', 'a:4:{i:0;s:9:"firstName";i:1;s:8:"lastName";i:2;s:11:"companyName";i:3;s:8:"jobTitle";}', NULL, 0, 'http://demo.zurmo.com', NULL, 3, NULL, NULL, NULL),
(5, 285, 6, 'Customer Support Portal Web Form', 'Submit Now', 'a:4:{i:0;s:9:"firstName";i:1;s:8:"lastName";i:2;s:11:"companyName";i:3;s:8:"jobTitle";}', NULL, 0, 'http://zurmo.org', NULL, 9, NULL, NULL, NULL),
(6, 286, 6, 'Sales Team Web Form', 'Save Now', 'a:4:{i:0;s:9:"firstName";i:1;s:8:"lastName";i:2;s:11:"companyName";i:3;s:8:"jobTitle";}', NULL, 0, 'http://zurmo.com', NULL, 7, NULL, NULL, NULL);

-- --------------------------------------------------------

--
-- Table structure for table `contactwebformentry`
--

CREATE TABLE IF NOT EXISTS `contactwebformentry` (
`id` int(11) unsigned NOT NULL,
  `item_id` int(11) unsigned DEFAULT NULL,
  `contact_id` int(11) unsigned DEFAULT NULL,
  `contactwebform_id` int(11) unsigned DEFAULT NULL,
  `serializeddata` text COLLATE utf8_unicode_ci,
  `message` text COLLATE utf8_unicode_ci,
  `hashindex` text COLLATE utf8_unicode_ci,
  `status` int(11) DEFAULT NULL,
  `entries_contactwebform_id` int(11) unsigned DEFAULT NULL
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

--
-- Dumping data for table `contactwebformentry`
--

INSERT INTO `contactwebformentry` (`id`, `item_id`, `contact_id`, `contactwebform_id`, `serializeddata`, `message`, `hashindex`, `status`, `entries_contactwebform_id`) VALUES
(2, 542, 26, 3, 'a:6:{s:9:"firstName";s:5:"Alice";s:8:"lastName";s:5:"Brown";s:11:"companyName";s:9:"Acme Corp";s:8:"jobTitle";s:13:"Sales Manager";s:5:"owner";i:8;s:5:"state";i:7;}', 'Success', NULL, 1, NULL),
(3, 544, 27, 3, 'a:6:{s:9:"firstName";s:3:"Jim";s:8:"lastName";s:5:"Smith";s:11:"companyName";s:14:"Allied Biscuit";s:8:"jobTitle";s:14:"Sales Director";s:5:"owner";i:8;s:5:"state";i:7;}', 'Success', NULL, 1, NULL),
(4, 545, NULL, 5, 'a:6:{s:9:"firstName";s:7:"Michael";s:8:"lastName";s:0:"";s:11:"companyName";s:23:"Charles Townsend Agency";s:8:"jobTitle";s:11:"IT Director";s:5:"owner";i:9;s:5:"state";i:6;}', 'Error', NULL, 2, NULL),
(5, 547, 28, 3, 'a:6:{s:9:"firstName";s:5:"Keith";s:8:"lastName";s:6:"Cooper";s:11:"companyName";s:17:"BLAND Corporation";s:8:"jobTitle";s:10:"IT Manager";s:5:"owner";i:8;s:5:"state";i:7;}', 'Success', NULL, 1, NULL),
(6, 549, 29, 4, 'a:6:{s:9:"firstName";s:5:"Sarah";s:8:"lastName";s:3:"Lee";s:11:"companyName";s:12:"Central Perk";s:8:"jobTitle";s:14:"Vice President";s:5:"owner";i:3;s:5:"state";i:7;}', 'Success', NULL, 1, NULL);

-- --------------------------------------------------------

--
-- Table structure for table `contactwebform_read`
--

CREATE TABLE IF NOT EXISTS `contactwebform_read` (
  `securableitem_id` int(11) unsigned NOT NULL,
  `munge_id` varchar(12) COLLATE utf8_unicode_ci NOT NULL,
  `count` int(8) unsigned NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

--
-- Dumping data for table `contactwebform_read`
--

INSERT INTO `contactwebform_read` (`securableitem_id`, `munge_id`, `count`) VALUES
(283, 'G3', 1),
(283, 'R2', 1),
(284, 'G3', 1),
(284, 'R2', 1),
(285, 'G3', 1),
(286, 'G3', 1),
(286, 'R2', 1),
(287, 'G3', 1),
(287, 'R2', 1);

-- --------------------------------------------------------

--
-- Table structure for table `contact_contract`
--

CREATE TABLE IF NOT EXISTS `contact_contract` (
`id` int(11) unsigned NOT NULL,
  `contract_id` int(11) unsigned DEFAULT NULL,
  `contact_id` int(11) unsigned DEFAULT NULL
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

--
-- Dumping data for table `contact_contract`
--

INSERT INTO `contact_contract` (`id`, `contract_id`, `contact_id`) VALUES
(1, 6, 30);

-- --------------------------------------------------------

--
-- Table structure for table `contact_opportunity`
--

CREATE TABLE IF NOT EXISTS `contact_opportunity` (
`id` int(11) unsigned NOT NULL,
  `contact_id` int(11) unsigned DEFAULT NULL,
  `opportunity_id` int(11) unsigned DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `contact_project`
--

CREATE TABLE IF NOT EXISTS `contact_project` (
`id` int(11) unsigned NOT NULL,
  `contact_id` int(11) unsigned DEFAULT NULL,
  `project_id` int(11) unsigned DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `contact_read`
--

CREATE TABLE IF NOT EXISTS `contact_read` (
  `securableitem_id` int(11) unsigned NOT NULL,
  `munge_id` varchar(12) COLLATE utf8_unicode_ci NOT NULL,
  `count` int(8) unsigned NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

--
-- Dumping data for table `contact_read`
--

INSERT INTO `contact_read` (`securableitem_id`, `munge_id`, `count`) VALUES
(42, 'R2', 1),
(99, 'R2', 1),
(100, 'R2', 1),
(101, 'R2', 1),
(102, 'R2', 1),
(103, 'R2', 1),
(104, 'R2', 1),
(105, 'R2', 1),
(106, 'R2', 1),
(107, 'R2', 1),
(108, 'R2', 1),
(109, 'R2', 1),
(110, 'R2', 1),
(288, 'R2', 1),
(289, 'R2', 1),
(290, 'R2', 1),
(306, 'G3', 1),
(329, 'G3', 1);

-- --------------------------------------------------------

--
-- Table structure for table `contact_read_subscription`
--

CREATE TABLE IF NOT EXISTS `contact_read_subscription` (
`id` int(11) unsigned NOT NULL,
  `userid` int(11) unsigned NOT NULL,
  `modelid` int(11) unsigned NOT NULL,
  `modifieddatetime` datetime DEFAULT NULL,
  `subscriptiontype` tinyint(4) DEFAULT NULL
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

--
-- Dumping data for table `contact_read_subscription`
--

INSERT INTO `contact_read_subscription` (`id`, `userid`, `modelid`, `modifieddatetime`, `subscriptiontype`) VALUES
(1, 1, 30, '2016-01-06 12:26:02', 1),
(2, 1, 31, '2016-01-12 18:51:53', 1);

-- --------------------------------------------------------

--
-- Table structure for table `contract`
--

CREATE TABLE IF NOT EXISTS `contract` (
`id` int(11) unsigned NOT NULL,
  `closedate` date DEFAULT NULL,
  `description` text COLLATE utf8_unicode_ci,
  `name` varchar(64) COLLATE utf8_unicode_ci DEFAULT NULL,
  `probability` tinyint(11) DEFAULT NULL,
  `ownedsecurableitem_id` int(11) unsigned DEFAULT NULL,
  `stage_customfield_id` int(11) unsigned DEFAULT NULL,
  `source_customfield_id` int(11) unsigned DEFAULT NULL,
  `account_id` int(11) unsigned DEFAULT NULL,
  `amount_currencyvalue_id` int(11) unsigned DEFAULT NULL,
  `blendedbulkcstm` tinyint(11) DEFAULT NULL,
  `monthlynetcscstm_currencyvalue_id` int(11) unsigned DEFAULT NULL,
  `doorfeecstmcstm_currencyvalue_id` int(11) unsigned DEFAULT NULL,
  `propbillcstmcstm` date DEFAULT NULL,
  `statuscstm_customfield_id` int(11) unsigned DEFAULT NULL,
  `roicstmcstm` varchar(11) COLLATE utf8_unicode_ci DEFAULT NULL,
  `contracttypecstm_customfield_id` int(11) unsigned DEFAULT NULL,
  `propinternetcstm` date DEFAULT NULL,
  `propphonecstm` date DEFAULT NULL,
  `propalaramcstm` date DEFAULT NULL
) ENGINE=InnoDB AUTO_INCREMENT=72 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

--
-- Dumping data for table `contract`
--

INSERT INTO `contract` (`id`, `closedate`, `description`, `name`, `probability`, `ownedsecurableitem_id`, `stage_customfield_id`, `source_customfield_id`, `account_id`, `amount_currencyvalue_id`, `blendedbulkcstm`, `monthlynetcscstm_currencyvalue_id`, `doorfeecstmcstm_currencyvalue_id`, `propbillcstmcstm`, `statuscstm_customfield_id`, `roicstmcstm`, `contracttypecstm_customfield_id`, `propinternetcstm`, `propphonecstm`, `propalaramcstm`) VALUES
(13, '2020-01-01', NULL, 'Midtown Retail-New Contract', 10, 450, 394, NULL, NULL, 393, 0, 391, 392, '2016-01-01', NULL, '10', 478, NULL, NULL, NULL),
(14, '2016-09-30', NULL, '3360 Condo-New Contract', 10, 451, 395, NULL, NULL, 394, 70, 395, 396, '2016-01-01', 525, '16', 457, '0000-00-00', '0000-00-00', '0000-00-00'),
(15, '2015-06-30', NULL, '400 Association (Data)-Renewal Contract', 10, 452, 396, NULL, NULL, 397, 100, 398, 399, '2016-01-01', NULL, '10', 500, NULL, NULL, NULL),
(16, '2020-01-01', NULL, '9 Island (Net)-Renewal Contract', 10, 453, 397, NULL, NULL, 400, 100, 401, 402, '2016-01-01', NULL, '10', 501, NULL, NULL, NULL),
(17, '2020-01-01', NULL, 'Alexander Hotel/Condo-New Contract', 10, 454, 398, NULL, NULL, 403, 100, 404, 405, '2016-01-01', NULL, '10', 459, NULL, NULL, NULL),
(18, '2020-01-01', NULL, 'Artesia-New Contract', 10, 455, 399, NULL, NULL, 406, 100, 407, 408, '2016-01-01', NULL, '10', 458, NULL, NULL, NULL),
(19, '2015-03-01', NULL, 'Aventi-New Contract', 10, 456, 400, NULL, NULL, 409, 100, 410, 411, '2016-01-01', NULL, '10', 460, NULL, NULL, NULL),
(20, '2020-01-01', NULL, 'Balmoral Condo-New Contract', 10, 457, 401, NULL, NULL, 412, 100, 413, 414, '2016-01-01', NULL, '10', 461, NULL, NULL, NULL),
(21, '2020-01-01', NULL, 'Bravura 1 Condo-New Contract', 10, 458, 402, NULL, NULL, 415, 100, 416, 417, '2016-01-01', NULL, '10', 463, NULL, NULL, NULL),
(22, '2016-09-30', NULL, 'Christopher House-New Contract', 10, 459, 403, NULL, NULL, 418, 100, 419, 420, '2016-01-01', NULL, '10', 462, NULL, NULL, NULL),
(23, '2020-01-01', NULL, 'Cloisters (Net)-Renewal Contract', 10, 460, 404, NULL, NULL, 421, 100, 422, 423, '2016-01-01', NULL, '10', 502, NULL, NULL, NULL),
(24, '2020-01-01', NULL, 'Commodore Club South-New Contract', 10, 461, 405, NULL, NULL, 424, 100, 425, 426, '2016-01-01', NULL, '10', 464, NULL, NULL, NULL),
(25, '2020-01-01', NULL, 'Commodore Plaza-New Contract', 10, 462, 406, NULL, NULL, 427, 100, 428, 429, '2016-01-01', NULL, '10', 465, NULL, NULL, NULL),
(26, '2020-01-01', NULL, 'Cypress Trails-New Contract', 10, 463, 407, NULL, NULL, 430, 100, 431, 432, '2016-01-01', NULL, '10', 466, NULL, NULL, NULL),
(27, '2020-01-01', NULL, 'East Pointe Towers-New Contract', 10, 464, 408, NULL, NULL, 433, 100, 434, 435, '2016-01-01', NULL, '10', 467, NULL, NULL, NULL),
(28, '2015-12-31', NULL, 'Emerald (Net)-Renewal Contract', 10, 465, 409, NULL, NULL, 436, 100, 437, 438, '2016-01-01', NULL, '10', 503, NULL, NULL, NULL),
(29, '2020-01-01', NULL, 'Fairways of Tamarac-New Contract', 10, 466, 410, NULL, NULL, 439, 100, 440, 441, '2016-01-01', NULL, '10', 468, NULL, NULL, NULL),
(30, '2020-01-01', NULL, 'Garden Estates (Net)-Renewal Contract', 10, 467, 411, NULL, NULL, 442, 100, 443, 444, '2016-01-01', NULL, '10', 504, NULL, NULL, NULL),
(31, '2020-01-01', NULL, 'Glades Country Club (Net)-Renewal Contract', 10, 468, 412, NULL, NULL, 445, 100, 446, 447, '2016-01-01', NULL, '10', 505, NULL, NULL, NULL),
(32, '2020-01-01', NULL, 'Harbour House-New Contract', 10, 469, 413, NULL, NULL, 448, 100, 449, 450, '2016-01-01', NULL, '10', 469, NULL, NULL, NULL),
(33, '2020-01-01', NULL, 'Hillsboro Cove-New Contract', 10, 470, 414, NULL, NULL, 451, 100, 452, 453, '2016-01-01', NULL, '10', 470, NULL, NULL, NULL),
(34, '2020-01-01', NULL, 'Isles at Grand Bay-New Contract', 10, 471, 415, NULL, NULL, 454, 100, 455, 456, '2016-01-01', NULL, '10', 471, NULL, NULL, NULL),
(35, '2015-09-30', NULL, 'Kenilworth (Net)-Renewal Contract', 10, 472, 416, NULL, NULL, 457, 100, 458, 459, '2016-01-01', NULL, '10', 506, NULL, NULL, NULL),
(36, '2020-01-01', NULL, 'Key Largo-New Contract', 10, 473, 417, NULL, NULL, 460, 100, 461, 462, '2016-01-01', NULL, '10', 472, NULL, NULL, NULL),
(37, '2020-01-01', NULL, 'Lake Worth Towers-Renewal Contract', 10, 474, 418, NULL, NULL, 463, 100, 464, 465, '2016-01-01', NULL, '10', 507, NULL, NULL, NULL),
(38, '2020-01-01', NULL, 'Lakes of Savannah -New Contract', 10, 475, 419, NULL, NULL, 466, 100, 467, 468, '2016-01-01', NULL, '10', 473, NULL, NULL, NULL),
(39, '2020-01-01', NULL, 'Las Verdes-New Contract', 10, 476, 420, NULL, NULL, 469, 100, 470, 471, '2016-01-01', NULL, '10', 474, NULL, NULL, NULL),
(40, '2015-09-30', NULL, 'Marina Village (Net)-Renewal Contract', 10, 477, 421, NULL, NULL, 472, 100, 473, 474, '2016-01-01', NULL, '10', 508, NULL, NULL, NULL),
(41, '2020-01-01', NULL, 'Mayfair House Condo-New Contract', 10, 478, 422, NULL, NULL, 475, 100, 476, 477, '2016-01-01', NULL, '10', 475, NULL, NULL, NULL),
(42, '2015-12-31', NULL, 'Meadowbrook # 4-New Contract', 10, 479, 423, NULL, NULL, 478, 100, 479, 480, '2016-01-01', NULL, '10', 476, NULL, NULL, NULL),
(43, '2020-01-01', NULL, 'Midtown Doral-New Contract', 10, 480, 424, NULL, NULL, 481, 100, 482, 483, '2016-01-01', NULL, '10', 477, NULL, NULL, NULL),
(44, '2020-01-01', NULL, 'Midtown Retail-New Contract', 10, 481, 425, NULL, NULL, 484, 100, 485, 486, '2016-01-01', NULL, '10', 479, NULL, NULL, NULL),
(45, '2020-01-01', NULL, 'Mystic Point-New Contract', 10, 482, 426, NULL, NULL, 487, 100, 488, 489, '2016-01-01', NULL, '10', 480, NULL, NULL, NULL),
(46, '2020-01-01', NULL, 'Nirvana Condos -New Contract', 10, 483, 427, NULL, NULL, 490, 100, 491, 492, '2016-01-01', NULL, '10', 481, NULL, NULL, NULL),
(47, '2015-12-31', NULL, 'Northern Star (Net)-Renewal Contract', 10, 484, 428, NULL, NULL, 493, 100, 494, 495, '2016-01-01', NULL, '10', 509, NULL, NULL, NULL),
(48, '2020-01-01', NULL, 'OakBridge-New Contract', 10, 485, 429, NULL, NULL, 496, 100, 497, 498, '2016-01-01', NULL, '10', 482, NULL, NULL, NULL),
(49, '2020-01-01', NULL, 'Ocean Place-New Contract', 10, 486, 430, NULL, NULL, 499, 100, 500, 501, '2016-01-01', NULL, '10', 483, NULL, NULL, NULL),
(50, '2020-01-01', NULL, 'Oceanfront Plaza-New Contract', 10, 487, 431, NULL, NULL, 502, 100, 503, 504, '2016-01-01', NULL, '10', NULL, NULL, NULL, NULL),
(51, '2020-01-01', NULL, 'OceanView Place-New Contract', 10, 488, 432, NULL, NULL, 505, 100, 506, 507, '2016-01-01', NULL, '10', NULL, NULL, NULL, NULL),
(52, '2020-01-01', NULL, 'Parker Plaza-New Contract', 10, 489, 433, NULL, NULL, 508, 100, 509, 510, '2016-01-01', NULL, '10', 484, NULL, NULL, NULL),
(53, '2020-01-01', NULL, 'Patrician of the Palm Beaches-New Contract', 10, 490, 434, NULL, NULL, 511, 100, 512, 513, '2016-01-01', NULL, '10', 485, NULL, NULL, NULL),
(54, '2020-01-01', NULL, 'Pine Ridge Condo-New Contract', 10, 491, 435, NULL, NULL, 514, 100, 515, 516, '2016-01-01', NULL, '10', 486, NULL, NULL, NULL),
(55, '2015-12-31', NULL, 'Pinehurst Club (Net)-Renewal Contract', 10, 492, 436, NULL, NULL, 517, 100, 518, 519, '2016-01-01', NULL, '10', 510, NULL, NULL, NULL),
(56, '2020-01-01', NULL, 'Plaza of Bal Harbour-New Contract', 10, 493, 437, NULL, NULL, 520, 100, 521, 522, '2016-01-01', NULL, '10', 487, NULL, NULL, NULL),
(57, '2020-01-01', NULL, 'Point East Condo-New Contract', 10, 494, 438, NULL, NULL, 523, 100, 524, 525, '2016-01-01', NULL, '10', 488, NULL, NULL, NULL),
(58, '2020-01-01', NULL, 'River Bridge-New Contract', 10, 495, 439, NULL, NULL, 526, 100, 527, 528, '2016-01-01', NULL, '10', 489, NULL, NULL, NULL),
(59, '2020-01-01', NULL, 'Sand Pebble Beach Condominiums-New Contract', 10, 496, 440, NULL, NULL, 529, 100, 530, 531, '2016-01-01', NULL, '10', 490, NULL, NULL, NULL),
(60, '2016-03-31', NULL, 'Seamark (Net)-Renewal Contract', 10, 497, 441, NULL, NULL, 532, 100, 533, 534, '2016-01-01', NULL, '10', 511, NULL, NULL, NULL),
(61, '2015-03-31', NULL, 'Strada 315 (Data)-New Contract', 10, 498, 442, NULL, NULL, 535, 100, 536, 537, '2016-01-01', NULL, '10', 491, NULL, NULL, NULL),
(62, '2014-09-30', NULL, 'Strada 315 (Video)-New Contract', 10, 499, 443, NULL, NULL, 538, 100, 539, 540, '2016-01-01', NULL, '10', 492, NULL, NULL, NULL),
(63, '2014-12-31', NULL, 'Sunset Bay (Data)-New Contract', 10, 500, 444, NULL, NULL, 541, 100, 542, 543, '2016-01-01', NULL, '10', 493, NULL, NULL, NULL),
(64, '2015-06-30', NULL, 'Sunset Bay (Video)-New Contract', 10, 501, 445, NULL, NULL, 544, 100, 545, 546, '2016-01-01', NULL, '10', 494, NULL, NULL, NULL),
(65, '2020-01-01', NULL, 'The Atriums-New Contract', 10, 502, 446, NULL, NULL, 547, 100, 548, 549, '2016-01-01', NULL, '10', 496, NULL, NULL, NULL),
(66, '2020-01-01', NULL, 'The Residences on Hollywood Beach Proposal (Net)-Renewal Contrac', 10, 503, 447, NULL, NULL, 550, 100, 551, 552, '2016-01-01', NULL, '10', 512, NULL, NULL, NULL),
(67, '2015-09-30', NULL, 'The Summit (Net)-Renewal Contract', 10, 504, 448, NULL, NULL, 553, 100, 554, 555, '2016-01-01', NULL, '10', 513, NULL, NULL, NULL),
(68, '2020-01-01', NULL, 'The Tides @ Bridgeside Square-New Contract', 10, 505, 449, NULL, NULL, 556, 100, 557, 558, '2016-01-01', NULL, '10', 495, NULL, NULL, NULL),
(69, '2015-12-31', NULL, 'Topaz North-New Contract', 10, 506, 450, NULL, NULL, 559, 100, 560, 561, '2016-01-01', NULL, '10', 497, NULL, NULL, NULL),
(70, '2020-01-01', NULL, 'TOWERS OF KENDAL LAKES-New Contract', 10, 507, 451, NULL, NULL, 562, 100, 563, 564, '2016-01-01', NULL, '10', 498, NULL, NULL, NULL),
(71, '2015-09-30', NULL, 'Tropic Harbor-New Contract', 10, 508, 452, NULL, NULL, 565, 100, 566, 567, '2016-01-01', NULL, '10', 499, NULL, NULL, NULL);

-- --------------------------------------------------------

--
-- Table structure for table `contractstarred`
--

CREATE TABLE IF NOT EXISTS `contractstarred` (
`id` int(11) unsigned NOT NULL,
  `basestarredmodel_id` int(11) unsigned DEFAULT NULL,
  `contract_id` int(11) unsigned DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `contract_opportunity`
--

CREATE TABLE IF NOT EXISTS `contract_opportunity` (
`id` int(11) unsigned NOT NULL,
  `contract_id` int(11) unsigned DEFAULT NULL,
  `opportunity_id` int(11) unsigned DEFAULT NULL
) ENGINE=InnoDB AUTO_INCREMENT=59 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

--
-- Dumping data for table `contract_opportunity`
--

INSERT INTO `contract_opportunity` (`id`, `contract_id`, `opportunity_id`) VALUES
(1, 14, 22),
(2, 15, 23),
(3, 16, 24),
(4, 17, 25),
(5, 18, 26),
(6, 19, 27),
(7, 20, 28),
(8, 21, 29),
(9, 22, 30),
(10, 23, 31),
(11, 24, 32),
(12, 25, 33),
(13, 26, 34),
(14, 27, 35),
(15, 28, 36),
(16, 29, 37),
(17, 30, 38),
(18, 31, 39),
(19, 32, 40),
(20, 33, 41),
(21, 34, 42),
(22, 35, 43),
(23, 36, 44),
(24, 37, 45),
(25, 38, 46),
(26, 39, 47),
(27, 40, 48),
(28, 41, 49),
(29, 42, 50),
(30, 43, 51),
(31, 44, 52),
(32, 45, 53),
(33, 46, 54),
(34, 47, 55),
(35, 48, 56),
(36, 49, 57),
(37, 50, 58),
(38, 51, 59),
(39, 52, 60),
(40, 53, 61),
(41, 54, 62),
(42, 55, 63),
(43, 56, 64),
(44, 57, 65),
(45, 58, 66),
(46, 59, 67),
(47, 60, 68),
(48, 61, 69),
(49, 62, 70),
(50, 63, 71),
(51, 64, 72),
(52, 65, 73),
(53, 66, 74),
(54, 67, 75),
(55, 68, 76),
(56, 69, 77),
(57, 70, 78),
(58, 71, 79);

-- --------------------------------------------------------

--
-- Table structure for table `contract_project`
--

CREATE TABLE IF NOT EXISTS `contract_project` (
`id` int(11) unsigned NOT NULL,
  `contract_id` int(11) unsigned DEFAULT NULL,
  `project_id` int(11) unsigned DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `contract_read`
--

CREATE TABLE IF NOT EXISTS `contract_read` (
  `securableitem_id` int(11) unsigned NOT NULL,
  `munge_id` varchar(12) COLLATE utf8_unicode_ci NOT NULL,
  `count` int(8) unsigned NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

--
-- Dumping data for table `contract_read`
--

INSERT INTO `contract_read` (`securableitem_id`, `munge_id`, `count`) VALUES
(111, 'R2', 1),
(112, 'R2', 1),
(113, 'R2', 1),
(114, 'R2', 1),
(115, 'R2', 1),
(116, 'R2', 1),
(117, 'R2', 1),
(118, 'R2', 1),
(119, 'R2', 1),
(120, 'R2', 1),
(121, 'R2', 1),
(122, 'R2', 1),
(299, 'G3', 1),
(300, 'G3', 1),
(301, 'G3', 1),
(302, 'G3', 1),
(303, 'G3', 1),
(316, 'G3', 1);

-- --------------------------------------------------------

--
-- Table structure for table `conversation`
--

CREATE TABLE IF NOT EXISTS `conversation` (
`id` int(11) unsigned NOT NULL,
  `ownedsecurableitem_id` int(11) unsigned DEFAULT NULL,
  `description` text COLLATE utf8_unicode_ci,
  `latestdatetime` datetime DEFAULT NULL,
  `subject` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `ownerhasreadlatest` tinyint(1) unsigned DEFAULT NULL,
  `isclosed` tinyint(1) unsigned DEFAULT NULL
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

--
-- Dumping data for table `conversation`
--

INSERT INTO `conversation` (`id`, `ownedsecurableitem_id`, `description`, `latestdatetime`, `subject`, `ownerhasreadlatest`, `isclosed`) VALUES
(2, 89, 'We are running out of good locations to put our offices. I am thinking we should open an office on Mars.', '2013-06-25 12:30:28', 'Should we consider building a new corporate headquarters on Mars?', 0, NULL),
(3, 90, 'We are going to maybe do a tv commercial and I need to make it compelling.', '2013-06-25 12:30:28', 'I am considering a new marketing campaign that uses elephants.  What do you guys think?', 0, NULL),
(4, 91, 'My wife and I are thinking about going to Hawaii in December.  Does this time of year work?', '2013-06-25 12:30:29', 'Vacation time in December', 0, NULL);

-- --------------------------------------------------------

--
-- Table structure for table `conversationparticipant`
--

CREATE TABLE IF NOT EXISTS `conversationparticipant` (
`id` int(11) unsigned NOT NULL,
  `person_item_id` int(11) unsigned DEFAULT NULL,
  `hasreadlatest` tinyint(1) unsigned DEFAULT NULL,
  `conversation_id` int(11) unsigned DEFAULT NULL
) ENGINE=InnoDB AUTO_INCREMENT=14 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

--
-- Dumping data for table `conversationparticipant`
--

INSERT INTO `conversationparticipant` (`id`, `person_item_id`, `hasreadlatest`, `conversation_id`) VALUES
(2, 65, 0, 2),
(3, 70, 0, 2),
(4, 1, 0, 2),
(5, 70, 0, 3),
(6, 68, 0, 3),
(7, 64, 0, 3),
(8, 1, 0, 3),
(9, 68, 0, 4),
(10, 64, 0, 4),
(11, 70, 0, 4),
(12, 65, 0, 4),
(13, 1, 1, 4);

-- --------------------------------------------------------

--
-- Table structure for table `conversationstarred`
--

CREATE TABLE IF NOT EXISTS `conversationstarred` (
`id` int(11) unsigned NOT NULL,
  `basestarredmodel_id` int(11) unsigned DEFAULT NULL,
  `conversation_id` int(11) unsigned DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `conversation_item`
--

CREATE TABLE IF NOT EXISTS `conversation_item` (
`id` int(11) unsigned NOT NULL,
  `conversation_id` int(11) unsigned DEFAULT NULL,
  `item_id` int(11) unsigned DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `conversation_read`
--

CREATE TABLE IF NOT EXISTS `conversation_read` (
  `securableitem_id` int(11) unsigned NOT NULL,
  `munge_id` varchar(12) COLLATE utf8_unicode_ci NOT NULL,
  `count` int(8) unsigned NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

--
-- Dumping data for table `conversation_read`
--

INSERT INTO `conversation_read` (`securableitem_id`, `munge_id`, `count`) VALUES
(90, 'R2', 3),
(90, 'U1', 1),
(90, 'U4', 1),
(90, 'U9', 1),
(91, 'R2', 3),
(91, 'U1', 1),
(91, 'U3', 1),
(91, 'U7', 1),
(91, 'U9', 1),
(92, 'R2', 4),
(92, 'U1', 1),
(92, 'U3', 1),
(92, 'U4', 1),
(92, 'U7', 1),
(92, 'U9', 1);

-- --------------------------------------------------------

--
-- Table structure for table `currency`
--

CREATE TABLE IF NOT EXISTS `currency` (
`id` int(11) unsigned NOT NULL,
  `active` tinyint(1) unsigned DEFAULT NULL,
  `code` varchar(3) COLLATE utf8_unicode_ci DEFAULT NULL,
  `ratetobase` double DEFAULT NULL
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

--
-- Dumping data for table `currency`
--

INSERT INTO `currency` (`id`, `active`, `code`, `ratetobase`) VALUES
(1, 1, 'USD', 1),
(3, 1, 'EUR', 1.0868),
(4, 1, 'CAD', 0.690031746032),
(5, 1, 'JPY', 0.00848267249454);

-- --------------------------------------------------------

--
-- Table structure for table `currencyvalue`
--

CREATE TABLE IF NOT EXISTS `currencyvalue` (
`id` int(11) unsigned NOT NULL,
  `currency_id` int(11) unsigned DEFAULT NULL,
  `value` double DEFAULT NULL,
  `ratetobase` double DEFAULT NULL
) ENGINE=InnoDB AUTO_INCREMENT=586 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

--
-- Dumping data for table `currencyvalue`
--

INSERT INTO `currencyvalue` (`id`, `currency_id`, `value`, `ratetobase`) VALUES
(14, 1, 200, 1),
(15, 1, 200, 1),
(16, 1, 200, 1),
(17, 4, 200, 1.1),
(18, 4, 200, 1.1),
(19, 4, 200, 1.1),
(20, 4, 200, 1.1),
(21, 4, 200, 1.1),
(22, 4, 200, 1.1),
(23, 5, 200, 0.75),
(24, 5, 200, 0.75),
(25, 5, 200, 0.75),
(26, 1, 200, 1),
(27, 1, 200, 1),
(28, 1, 200, 1),
(29, 1, 200, 1),
(30, 1, 200, 1),
(31, 1, 200, 1),
(32, 1, 200, 1),
(33, 1, 200, 1),
(34, 1, 200, 1),
(35, 4, 200, 1.1),
(36, 4, 200, 1.1),
(37, 4, 200, 1.1),
(38, 4, 200, 1.1),
(39, 4, 200, 1.1),
(40, 4, 200, 1.1),
(41, 1, 200, 1),
(42, 1, 200, 1),
(43, 1, 200, 1),
(44, 4, 200, 1.1),
(45, 4, 200, 1.1),
(46, 4, 200, 1.1),
(47, 5, 200, 0.75),
(48, 5, 200, 0.75),
(49, 5, 200, 0.75),
(50, 5, 200, 0.75),
(51, 5, 200, 0.75),
(52, 5, 200, 0.75),
(53, 1, 200, 1),
(54, 1, 200, 1),
(55, 1, 200, 1),
(56, 4, 200, 1.1),
(57, 4, 200, 1.1),
(58, 4, 200, 1.1),
(59, 3, 200, 1.5),
(60, 3, 200, 1.5),
(61, 3, 200, 1.5),
(62, 1, 200, 1),
(63, 1, 200, 1),
(64, 1, 200, 1),
(65, 4, 200, 1.1),
(66, 4, 200, 1.1),
(67, 4, 200, 1.1),
(68, 3, 200, 1.5),
(69, 3, 200, 1.5),
(70, 3, 200, 1.5),
(71, 1, 200, 1),
(72, 1, 200, 1),
(73, 1, 200, 1),
(74, 3, 200, 1.5),
(75, 3, 200, 1.5),
(76, 3, 200, 1.5),
(77, 4, 200, 1.1),
(78, 4, 200, 1.1),
(79, 4, 200, 1.1),
(80, 4, 200, 1.1),
(81, 4, 200, 1.1),
(82, 4, 200, 1.1),
(83, 4, 200, 1.1),
(84, 4, 200, 1.1),
(85, 4, 200, 1.1),
(86, 5, 200, 0.75),
(87, 5, 200, 0.75),
(88, 5, 200, 0.75),
(89, 1, 200, 1),
(90, 1, 200, 1),
(91, 1, 200, 1),
(92, 5, 200, 0.75),
(93, 5, 200, 0.75),
(94, 5, 200, 0.75),
(95, 3, 200, 1.5),
(96, 3, 200, 1.5),
(97, 3, 200, 1.5),
(98, 3, 200, 1.5),
(99, 3, 200, 1.5),
(100, 3, 200, 1.5),
(101, 1, 200, 1),
(102, 1, 200, 1),
(103, 1, 200, 1),
(104, 3, 200, 1.5),
(105, 3, 200, 1.5),
(106, 3, 200, 1.5),
(107, 4, 200, 1.1),
(108, 4, 200, 1.1),
(109, 4, 200, 1.1),
(110, 1, 200, 1),
(111, 1, 200, 1),
(112, 1, 200, 1),
(113, 1, 200, 1),
(114, 1, 200, 1),
(115, 1, 200, 1),
(116, 1, 200, 1),
(117, 1, 200, 1),
(118, 1, 200, 1),
(119, 1, 200, 1),
(120, 1, 200, 1),
(121, 1, 200, 1),
(122, 1, 200, 1),
(123, 1, 200, 1),
(124, 1, 200, 1),
(125, 1, 200, 1),
(126, 1, 200, 1),
(127, 1, 200, 1),
(128, 1, 200, 1),
(129, 1, 200, 1),
(130, 1, 200, 1),
(131, 1, 200, 1),
(132, 1, 200, 1),
(133, 1, 200, 1),
(134, 1, 200, 1),
(135, 1, 200, 1),
(136, 1, 200, 1),
(137, 1, 200, 1),
(138, 1, 200, 1),
(139, 1, 200, 1),
(140, 1, 200, 1),
(141, 1, 200, 1),
(142, 1, 200, 1),
(143, 1, 200, 1),
(144, 1, 200, 1),
(145, 1, 200, 1),
(146, 1, 200, 1),
(147, 1, 200, 1),
(148, 1, 200, 1),
(149, 1, 200, 1),
(150, 1, 200, 1),
(151, 1, 200, 1),
(152, 1, 200, 1),
(153, 1, 200, 1),
(154, 1, 200, 1),
(155, 1, 200, 1),
(156, 1, 200, 1),
(157, 1, 200, 1),
(158, 1, 200, 1),
(159, 1, 200, 1),
(160, 1, 200, 1),
(161, 1, 200, 1),
(162, 1, 200, 1),
(163, 1, 200, 1),
(164, 1, 200, 1),
(165, 1, 200, 1),
(166, 1, 200, 1),
(167, 1, 200, 1),
(168, 1, 200, 1),
(169, 1, 11, 1),
(170, 1, 11, 1),
(171, 1, 33, 1),
(172, 1, 33, 1),
(173, 1, 324, 1),
(174, 1, 324, 1),
(183, 1, 33, 1),
(184, 1, 44, 1),
(185, 1, 33, 1),
(186, 1, 222, 1),
(205, 1, 234, 1),
(209, 1, 22.08, 1),
(221, 1, 10.05, 1),
(225, 1, 10.08, 1),
(269, 1, 69.95, 1),
(270, 1, 40, 1),
(271, 1, 20, 1),
(272, 1, 34, 1),
(273, 1, 163, 1),
(274, 1, 14670, 1),
(275, 1, 2344, 1),
(276, 1, 210960, 1),
(277, 1, 1280, 1),
(278, 1, 1, 1),
(279, 1, 1, 1),
(280, 1, 1, 1),
(281, 1, 1, 1),
(282, 1, 1, 1),
(283, 1, 1, 1),
(284, 1, 1, 1),
(285, 1, 1, 1),
(286, 1, 1, 1),
(287, 1, 1, 1),
(288, 1, 1, 1),
(289, 1, 1, 1),
(290, 1, 1, 1),
(291, 1, 1, 1),
(292, 1, 1, 1),
(293, 1, 1, 1),
(294, 1, 1, 1),
(295, 1, 1, 1),
(296, 1, 1, 1),
(297, 1, 1, 1),
(298, 1, 1, 1),
(299, 1, 1, 1),
(300, 1, 1, 1),
(301, 1, 1, 1),
(302, 1, 1, 1),
(303, 1, 1, 1),
(304, 1, 1, 1),
(305, 1, 1, 1),
(306, 1, 1, 1),
(307, 1, 1, 1),
(308, 1, 1, 1),
(309, 1, 1, 1),
(310, 1, 1, 1),
(311, 1, 1, 1),
(312, 1, 1, 1),
(313, 1, 1, 1),
(314, 1, 1, 1),
(315, 1, 1, 1),
(316, 1, 1, 1),
(317, 1, 1, 1),
(318, 1, 1, 1),
(319, 1, 1, 1),
(320, 1, 1, 1),
(321, 1, 1, 1),
(322, 1, 1, 1),
(323, 1, 1, 1),
(324, 1, 1, 1),
(325, 1, 1, 1),
(326, 1, 1, 1),
(327, 1, 1, 1),
(328, 1, 1, 1),
(329, 1, 1, 1),
(330, 1, 1, 1),
(331, 1, 1, 1),
(332, 1, 1, 1),
(333, 1, 1, 1),
(334, 1, 1, 1),
(335, 1, 1, 1),
(336, 1, 1, 1),
(337, 1, 1, 1),
(338, 1, 1, 1),
(339, 1, 1, 1),
(340, 1, 1, 1),
(341, 1, 1, 1),
(342, 1, 1, 1),
(343, 1, 1, 1),
(344, 1, 1, 1),
(345, 1, 1, 1),
(346, 1, 1, 1),
(347, 1, 1, 1),
(348, 1, 1, 1),
(349, 1, 1, 1),
(350, 1, 1, 1),
(351, 1, 1, 1),
(352, 1, 1, 1),
(353, 1, 1, 1),
(354, 1, 1, 1),
(355, 1, 1, 1),
(356, 1, 1, 1),
(357, 1, 1, 1),
(358, 1, 1, 1),
(359, 1, 1, 1),
(360, 1, 1, 1),
(361, 1, 1, 1),
(362, 1, 1, 1),
(363, 1, 1, 1),
(364, 1, 1, 1),
(365, 1, 1, 1),
(366, 1, 1, 1),
(367, 1, 1, 1),
(368, 1, 1, 1),
(369, 1, 1, 1),
(370, 1, 1, 1),
(371, 1, 1, 1),
(372, 1, 1, 1),
(373, 1, 1, 1),
(374, 1, 1, 1),
(375, 1, 1, 1),
(376, 1, 1, 1),
(377, 1, 1, 1),
(378, 1, 1, 1),
(379, 1, 1, 1),
(380, 1, 1, 1),
(381, 1, 1, 1),
(382, 1, 1, 1),
(383, 1, 1, 1),
(384, 1, 1, 1),
(385, 1, 1, 1),
(386, 1, 1, 1),
(387, 1, 1, 1),
(388, 1, 1, 1),
(389, 1, 1, 1),
(390, 1, 1, 1),
(391, 1, 100, 1),
(392, 1, 100, 1),
(393, 1, 100, 1),
(394, 1, 22500, 1),
(395, 1, 10269, 1),
(396, 4, 250, 0.689367088608),
(397, 1, 10, 1),
(398, 1, 100, 1),
(399, 4, 10, 1),
(400, 1, 10, 1),
(401, 1, 100, 1),
(402, 4, 10, 1),
(403, 1, 10, 1),
(404, 1, 100, 1),
(405, 4, 10, 1),
(406, 1, 10, 1),
(407, 1, 100, 1),
(408, 4, 10, 1),
(409, 1, 10, 1),
(410, 1, 100, 1),
(411, 4, 10, 1),
(412, 1, 10, 1),
(413, 1, 100, 1),
(414, 4, 10, 1),
(415, 1, 10, 1),
(416, 1, 100, 1),
(417, 4, 10, 1),
(418, 1, 10, 1),
(419, 1, 100, 1),
(420, 4, 10, 1),
(421, 1, 10, 1),
(422, 1, 100, 1),
(423, 4, 10, 1),
(424, 1, 10, 1),
(425, 1, 100, 1),
(426, 4, 10, 1),
(427, 1, 10, 1),
(428, 1, 100, 1),
(429, 4, 10, 1),
(430, 1, 10, 1),
(431, 1, 100, 1),
(432, 4, 10, 1),
(433, 1, 10, 1),
(434, 1, 100, 1),
(435, 4, 10, 1),
(436, 1, 10, 1),
(437, 1, 100, 1),
(438, 4, 10, 1),
(439, 1, 10, 1),
(440, 1, 100, 1),
(441, 4, 10, 1),
(442, 1, 10, 1),
(443, 1, 100, 1),
(444, 4, 10, 1),
(445, 1, 10, 1),
(446, 1, 100, 1),
(447, 4, 10, 1),
(448, 1, 10, 1),
(449, 1, 100, 1),
(450, 4, 10, 1),
(451, 1, 10, 1),
(452, 1, 100, 1),
(453, 4, 10, 1),
(454, 1, 10, 1),
(455, 1, 100, 1),
(456, 4, 10, 1),
(457, 1, 10, 1),
(458, 1, 100, 1),
(459, 4, 10, 1),
(460, 1, 10, 1),
(461, 1, 100, 1),
(462, 4, 10, 1),
(463, 1, 10, 1),
(464, 1, 100, 1),
(465, 4, 10, 1),
(466, 1, 10, 1),
(467, 1, 100, 1),
(468, 4, 10, 1),
(469, 1, 10, 1),
(470, 1, 100, 1),
(471, 4, 10, 1),
(472, 1, 10, 1),
(473, 1, 100, 1),
(474, 4, 10, 1),
(475, 1, 10, 1),
(476, 1, 100, 1),
(477, 4, 10, 1),
(478, 1, 10, 1),
(479, 1, 100, 1),
(480, 4, 10, 1),
(481, 1, 10, 1),
(482, 1, 100, 1),
(483, 4, 10, 1),
(484, 1, 10, 1),
(485, 1, 100, 1),
(486, 4, 10, 1),
(487, 1, 10, 1),
(488, 1, 100, 1),
(489, 4, 10, 1),
(490, 1, 10, 1),
(491, 1, 100, 1),
(492, 4, 10, 1),
(493, 1, 10, 1),
(494, 1, 100, 1),
(495, 4, 10, 1),
(496, 1, 10, 1),
(497, 1, 100, 1),
(498, 4, 10, 1),
(499, 1, 10, 1),
(500, 1, 100, 1),
(501, 4, 10, 1),
(502, 1, 10, 1),
(503, 1, 100, 1),
(504, 4, 10, 1),
(505, 1, 10, 1),
(506, 1, 100, 1),
(507, 4, 10, 1),
(508, 1, 10, 1),
(509, 1, 100, 1),
(510, 4, 10, 1),
(511, 1, 10, 1),
(512, 1, 100, 1),
(513, 4, 10, 1),
(514, 1, 10, 1),
(515, 1, 100, 1),
(516, 4, 10, 1),
(517, 1, 10, 1),
(518, 1, 100, 1),
(519, 4, 10, 1),
(520, 1, 10, 1),
(521, 1, 100, 1),
(522, 4, 10, 1),
(523, 1, 10, 1),
(524, 1, 100, 1),
(525, 4, 10, 1),
(526, 1, 10, 1),
(527, 1, 100, 1),
(528, 4, 10, 1),
(529, 1, 10, 1),
(530, 1, 100, 1),
(531, 4, 10, 1),
(532, 1, 10, 1),
(533, 1, 100, 1),
(534, 4, 10, 1),
(535, 1, 10, 1),
(536, 1, 100, 1),
(537, 4, 10, 1),
(538, 1, 10, 1),
(539, 1, 100, 1),
(540, 4, 10, 1),
(541, 1, 10, 1),
(542, 1, 100, 1),
(543, 4, 10, 1),
(544, 1, 10, 1),
(545, 1, 100, 1),
(546, 4, 10, 1),
(547, 1, 10, 1),
(548, 1, 100, 1),
(549, 4, 10, 1),
(550, 1, 10, 1),
(551, 1, 100, 1),
(552, 4, 10, 1),
(553, 1, 10, 1),
(554, 1, 100, 1),
(555, 4, 10, 1),
(556, 1, 10, 1),
(557, 1, 100, 1),
(558, 4, 10, 1),
(559, 1, 10, 1),
(560, 1, 100, 1),
(561, 4, 10, 1),
(562, 1, 10, 1),
(563, 1, 100, 1),
(564, 4, 10, 1),
(565, 1, 10, 1),
(566, 1, 100, 1),
(567, 4, 10, 1),
(568, 1, 10, 1),
(569, 1, 0, 1),
(570, 1, 0, 1),
(571, 1, 10, 1),
(572, 1, 20, 1),
(573, 1, 0, 1),
(574, 1, 0, 1),
(575, 1, 0, 1),
(576, 1, 0, 1),
(577, 1, 0, 1),
(578, 1, 0, 1),
(579, 1, 0, 1),
(580, 1, 0, 1),
(581, 1, 0, 1),
(582, 1, 0, 1),
(583, 1, 0, 1),
(584, 1, 0, 1),
(585, 1, 0, 1);

-- --------------------------------------------------------

--
-- Table structure for table `customfield`
--

CREATE TABLE IF NOT EXISTS `customfield` (
`id` int(11) unsigned NOT NULL,
  `basecustomfield_id` int(11) unsigned DEFAULT NULL,
  `value` text COLLATE utf8_unicode_ci
) ENGINE=InnoDB AUTO_INCREMENT=529 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

--
-- Dumping data for table `customfield`
--

INSERT INTO `customfield` (`id`, `basecustomfield_id`, `value`) VALUES
(2, 2, 'Sir'),
(3, 3, 'Mr.'),
(4, 4, 'Mr.'),
(5, 5, 'Dr.'),
(6, 6, 'Mrs.'),
(7, 7, 'Ms.'),
(8, 8, 'Ms.'),
(9, 9, 'Mr.'),
(22, 22, 'Mr.'),
(23, 23, 'Manufacturing'),
(24, 24, 'Tradeshow'),
(25, 25, 'Dr.'),
(26, 26, 'Energy'),
(27, 27, 'Word of Mouth'),
(28, 28, 'Ms.'),
(29, 29, 'Technology'),
(30, 30, 'Tradeshow'),
(31, 31, 'Dr.'),
(32, 32, 'Energy'),
(33, 33, 'Tradeshow'),
(34, 34, 'Dr.'),
(35, 35, 'Insurance'),
(36, 36, 'Inbound Call'),
(37, 37, 'Mr.'),
(38, 38, 'Banking'),
(39, 39, 'Word of Mouth'),
(40, 40, 'Dr.'),
(41, 41, 'Insurance'),
(42, 42, 'Word of Mouth'),
(43, 43, 'Mr.'),
(44, 44, 'Technology'),
(45, 45, 'Self-Generated'),
(46, 46, 'Dr.'),
(47, 47, 'Insurance'),
(48, 48, 'Self-Generated'),
(49, 49, 'Ms.'),
(50, 50, 'Business Services'),
(51, 51, 'Word of Mouth'),
(52, 52, 'Dr.'),
(53, 53, 'Technology'),
(54, 54, 'Word of Mouth'),
(55, 55, 'Mr.'),
(56, 56, 'Automotive'),
(57, 57, 'Self-Generated'),
(58, 58, 'Dr.'),
(59, 59, 'Business Services'),
(60, 60, 'Inbound Call'),
(61, 61, 'Dr.'),
(62, 62, 'Energy'),
(63, 63, 'Self-Generated'),
(64, 64, 'Dr.'),
(65, 65, 'Automotive'),
(66, 66, 'Inbound Call'),
(67, 67, 'Mr.'),
(68, 68, 'Energy'),
(69, 69, 'Inbound Call'),
(70, 70, 'Mr.'),
(71, 71, 'Banking'),
(72, 72, 'Word of Mouth'),
(73, 73, 'Dr.'),
(74, 74, 'Energy'),
(75, 75, 'Tradeshow'),
(76, 76, 'Ms.'),
(77, 77, 'Energy'),
(78, 78, 'Self-Generated'),
(79, 79, 'Mr.'),
(80, 80, 'Business Services'),
(81, 81, 'Self-Generated'),
(82, 82, 'Dr.'),
(83, 83, 'Automotive'),
(84, 84, 'Self-Generated'),
(85, 85, 'Dr.'),
(86, 86, 'Automotive'),
(87, 87, 'Word of Mouth'),
(88, 88, 'Mr.'),
(89, 89, 'Retail'),
(90, 90, 'Word of Mouth'),
(91, 91, 'Dr.'),
(92, 92, 'Business Services'),
(93, 93, 'Tradeshow'),
(118, 118, 'Meeting'),
(119, 119, 'Meeting'),
(120, 120, 'Call'),
(121, 121, 'Call'),
(122, 122, 'Meeting'),
(123, 123, 'Call'),
(124, 124, 'Meeting'),
(125, 125, 'Meeting'),
(126, 126, 'Call'),
(127, 127, 'Call'),
(128, 128, 'Call'),
(129, 129, 'Call'),
(130, 130, 'Call'),
(131, 131, 'Call'),
(132, 132, 'Meeting'),
(133, 133, 'Call'),
(134, 134, 'Meeting'),
(135, 135, 'Meeting'),
(136, 136, 'Meeting'),
(137, 137, 'Meeting'),
(138, 138, 'Meeting'),
(139, 139, 'Meeting'),
(140, 140, 'Call'),
(141, 141, 'Meeting'),
(142, 142, 'Call'),
(143, 143, 'Call'),
(144, 144, 'Call'),
(145, 145, 'Meeting'),
(146, 146, 'Meeting'),
(147, 147, 'Meeting'),
(148, 148, 'Call'),
(149, 149, 'Meeting'),
(150, 150, 'Call'),
(151, 151, 'Call'),
(152, 152, 'Meeting'),
(153, 153, 'Call'),
(154, 154, 'Open'),
(155, 155, 'Open'),
(156, 156, 'Open'),
(157, 157, 'Open'),
(158, 158, 'Open'),
(159, 159, 'Open'),
(160, 160, 'Open'),
(161, 161, 'Open'),
(162, 162, 'Open'),
(163, 163, 'Open'),
(164, 164, 'Open'),
(165, 165, 'Open'),
(166, 166, 'Open'),
(167, 167, 'Open'),
(168, 168, 'Open'),
(169, 169, 'Open'),
(170, 170, 'Open'),
(171, 171, 'Open'),
(172, 172, 'Open'),
(173, 173, 'Open'),
(174, 174, 'Open'),
(175, 175, 'Open'),
(176, 176, 'Open'),
(177, 177, 'Open'),
(178, 178, 'Open'),
(179, 179, 'Open'),
(180, 180, 'Open'),
(181, 181, 'Open'),
(182, 182, 'Open'),
(183, 183, 'Open'),
(184, 184, 'Open'),
(185, 185, 'Open'),
(186, 186, 'Open'),
(187, 187, 'Open'),
(188, 188, 'Open'),
(189, 189, 'Open'),
(190, 190, 'Open'),
(191, 191, 'Open'),
(192, 192, 'Open'),
(193, 193, 'Open'),
(194, 194, 'Open'),
(195, 195, 'Open'),
(196, 196, 'Open'),
(197, 197, 'Open'),
(198, 198, 'Open'),
(199, 199, 'Open'),
(200, 200, 'Open'),
(201, 201, 'Open'),
(202, 202, 'Open'),
(203, 203, 'Open'),
(204, 204, 'Open'),
(205, 205, 'Open'),
(206, 206, 'Open'),
(207, 207, 'Open'),
(208, 208, 'Open'),
(209, 209, 'Open'),
(210, 210, 'Open'),
(211, 211, 'Open'),
(212, 212, 'Open'),
(213, 213, 'First Presentation'),
(214, 214, 'Self-Generated'),
(215, 215, 'First Presentation'),
(216, 216, 'Self-Generated'),
(217, 217, 'Initial Contact'),
(218, 218, ''),
(219, 219, 'Initial Contact'),
(220, 220, ''),
(221, 221, 'Initial Contact'),
(222, 222, ''),
(223, 223, 'Initial Contact'),
(224, 224, ''),
(225, 225, ''),
(226, 226, ''),
(227, 227, 'Meeting'),
(228, 228, 'Low Rise Condo'),
(232, 233, 'Initial Contact'),
(233, 234, 'Active'),
(262, 265, 'Mr.'),
(263, 266, 'Tradeshow'),
(276, 282, 'Low Rise Condo'),
(278, 284, 'Low Rise Condo'),
(280, 286, 'Low Rise Condo'),
(281, 287, 'Low Rise Condo'),
(282, 288, 'Low Rise Condo'),
(283, 289, 'Low Rise Condo'),
(284, 290, 'Low Rise Condo'),
(285, 291, 'Low Rise Condo'),
(286, 292, 'Low Rise Condo'),
(287, 293, 'Low Rise Condo'),
(288, 294, 'Low Rise Condo'),
(289, 295, 'Low Rise Condo'),
(290, 296, 'Low Rise Condo'),
(291, 297, 'Low Rise Condo'),
(292, 298, 'Low Rise Condo'),
(293, 299, 'Low Rise Condo'),
(294, 300, 'Low Rise Condo'),
(295, 301, 'Low Rise Condo'),
(296, 302, 'Low Rise Condo'),
(297, 303, 'Low Rise Condo'),
(298, 304, 'Low Rise Condo'),
(299, 305, 'Low Rise Condo'),
(300, 306, 'Low Rise Condo'),
(301, 307, 'Low Rise Condo'),
(302, 308, 'Low Rise Condo'),
(303, 309, 'Low Rise Condo'),
(304, 310, 'Low Rise Condo'),
(305, 311, 'Low Rise Condo'),
(306, 312, 'Low Rise Condo'),
(307, 313, 'Low Rise Condo'),
(308, 314, 'Low Rise Condo'),
(309, 315, 'Low Rise Condo'),
(310, 316, 'Low Rise Condo'),
(311, 317, 'Low Rise Condo'),
(312, 318, 'Low Rise Condo'),
(313, 319, 'Low Rise Condo'),
(314, 320, 'Low Rise Condo'),
(315, 321, 'Low Rise Condo'),
(316, 322, 'Low Rise Condo'),
(317, 323, 'Low Rise Condo'),
(318, 324, 'Low Rise Condo'),
(319, 325, 'Low Rise Condo'),
(320, 326, 'Low Rise Condo'),
(321, 327, 'Low Rise Condo'),
(322, 328, 'Low Rise Condo'),
(323, 329, 'Low Rise Condo'),
(324, 330, 'Low Rise Condo'),
(325, 331, 'Low Rise Condo'),
(326, 332, 'Low Rise Condo'),
(327, 333, 'Low Rise Condo'),
(328, 334, 'Low Rise Condo'),
(329, 335, 'Low Rise Condo'),
(330, 336, 'Low Rise Condo'),
(331, 337, 'Low Rise Condo'),
(332, 338, 'Low Rise Condo'),
(333, 339, 'Low Rise Condo'),
(334, 340, 'Under Construction'),
(335, 342, '8 years'),
(336, 343, 'Yes'),
(337, 344, 'Under Construction'),
(338, 345, 'Under Construction'),
(339, 346, 'Under Construction'),
(340, 347, 'Under Construction'),
(341, 348, 'Under Construction'),
(342, 349, 'Under Construction'),
(343, 350, 'Under Construction'),
(344, 351, 'Under Construction'),
(345, 352, 'Under Construction'),
(346, 353, 'Under Construction'),
(347, 354, 'Under Construction'),
(348, 355, 'Under Construction'),
(349, 356, 'Under Construction'),
(350, 357, 'Under Construction'),
(351, 358, 'Under Construction'),
(352, 359, 'Under Construction'),
(353, 360, 'Under Construction'),
(354, 361, 'Under Construction'),
(355, 362, 'Under Construction'),
(356, 363, 'Under Construction'),
(357, 364, 'Under Construction'),
(358, 365, 'Under Construction'),
(359, 366, 'Under Construction'),
(360, 367, 'Under Construction'),
(361, 368, 'Under Construction'),
(362, 369, 'Under Construction'),
(363, 370, 'Under Construction'),
(364, 371, 'Under Construction'),
(365, 372, 'Under Construction'),
(366, 373, 'Under Construction'),
(367, 374, 'Under Construction'),
(368, 375, 'Under Construction'),
(369, 376, 'Under Construction'),
(370, 377, 'Under Construction'),
(371, 378, 'Under Construction'),
(372, 379, 'Under Construction'),
(373, 380, 'Under Construction'),
(374, 381, 'Under Construction'),
(375, 382, 'Under Construction'),
(376, 383, 'Under Construction'),
(377, 384, 'Under Construction'),
(378, 385, 'Under Construction'),
(379, 386, 'Under Construction'),
(380, 387, 'Under Construction'),
(381, 388, 'Under Construction'),
(382, 389, 'Under Construction'),
(383, 390, 'Under Construction'),
(384, 391, 'Under Construction'),
(385, 392, 'Under Construction'),
(386, 393, 'Under Construction'),
(387, 394, 'Under Construction'),
(388, 395, 'Under Construction'),
(389, 396, 'Under Construction'),
(390, 397, 'Under Construction'),
(391, 398, 'Under Construction'),
(392, 399, 'Under Construction'),
(393, 400, 'Under Construction'),
(394, 401, 'Prospecting'),
(395, 402, 'Prospecting'),
(396, 403, 'Prospecting'),
(397, 404, 'Prospecting'),
(398, 405, 'Prospecting'),
(399, 406, 'Prospecting'),
(400, 407, 'Prospecting'),
(401, 408, 'Prospecting'),
(402, 409, 'Prospecting'),
(403, 410, 'Prospecting'),
(404, 411, 'Prospecting'),
(405, 412, 'Prospecting'),
(406, 413, 'Prospecting'),
(407, 414, 'Prospecting'),
(408, 415, 'Prospecting'),
(409, 416, 'Prospecting'),
(410, 417, 'Prospecting'),
(411, 418, 'Prospecting'),
(412, 419, 'Prospecting'),
(413, 420, 'Prospecting'),
(414, 421, 'Prospecting'),
(415, 422, 'Prospecting'),
(416, 423, 'Prospecting'),
(417, 424, 'Prospecting'),
(418, 425, 'Prospecting'),
(419, 426, 'Prospecting'),
(420, 427, 'Prospecting'),
(421, 428, 'Prospecting'),
(422, 429, 'Prospecting'),
(423, 430, 'Prospecting'),
(424, 431, 'Prospecting'),
(425, 432, 'Prospecting'),
(426, 433, 'Prospecting'),
(427, 434, 'Prospecting'),
(428, 435, 'Prospecting'),
(429, 436, 'Prospecting'),
(430, 437, 'Prospecting'),
(431, 438, 'Prospecting'),
(432, 439, 'Prospecting'),
(433, 440, 'Prospecting'),
(434, 441, 'Prospecting'),
(435, 442, 'Prospecting'),
(436, 443, 'Prospecting'),
(437, 444, 'Prospecting'),
(438, 445, 'Prospecting'),
(439, 446, 'Prospecting'),
(440, 447, 'Prospecting'),
(441, 448, 'Prospecting'),
(442, 449, 'Prospecting'),
(443, 450, 'Prospecting'),
(444, 451, 'Prospecting'),
(445, 452, 'Prospecting'),
(446, 453, 'Prospecting'),
(447, 454, 'Prospecting'),
(448, 455, 'Prospecting'),
(449, 456, 'Prospecting'),
(450, 457, 'Prospecting'),
(451, 458, 'Prospecting'),
(452, 459, 'Prospecting'),
(453, 460, '7 years'),
(454, 461, ''),
(455, 462, ''),
(456, 463, 'No'),
(457, 464, 'New'),
(458, 465, 'New'),
(459, 466, 'New'),
(460, 467, 'New'),
(461, 468, 'New'),
(462, 469, 'New'),
(463, 470, 'New'),
(464, 471, 'New'),
(465, 472, 'New'),
(466, 473, 'New'),
(467, 474, 'New'),
(468, 475, 'New'),
(469, 476, 'New'),
(470, 477, 'New'),
(471, 478, 'New'),
(472, 479, 'New'),
(473, 480, 'New'),
(474, 481, 'New'),
(475, 482, 'New'),
(476, 483, 'New'),
(477, 484, 'New'),
(478, 485, 'New'),
(479, 486, 'New'),
(480, 487, 'New'),
(481, 488, 'New'),
(482, 489, 'New'),
(483, 490, 'New'),
(484, 491, 'New'),
(485, 492, 'New'),
(486, 493, 'New'),
(487, 494, 'New'),
(488, 495, 'New'),
(489, 496, 'New'),
(490, 497, 'New'),
(491, 498, 'New'),
(492, 499, 'New'),
(493, 500, 'New'),
(494, 501, 'New'),
(495, 502, 'New'),
(496, 503, 'New'),
(497, 504, 'New'),
(498, 505, 'New'),
(499, 506, 'New'),
(500, 507, 'Renewal'),
(501, 508, 'Renewal'),
(502, 509, 'Renewal'),
(503, 510, 'Renewal'),
(504, 511, 'Renewal'),
(505, 512, 'Renewal'),
(506, 513, 'Renewal'),
(507, 514, 'Renewal'),
(508, 515, 'Renewal'),
(509, 516, 'Renewal'),
(510, 517, 'Renewal'),
(511, 518, 'Renewal'),
(512, 519, 'Renewal'),
(513, 520, 'Renewal'),
(514, 521, '5 years'),
(515, 522, ''),
(516, 523, ''),
(517, 524, 'Yes'),
(518, 525, 'Yes'),
(519, 526, 'Yes'),
(520, 527, 'Yes'),
(521, 528, 'Yes'),
(522, 529, 'Yes'),
(523, 530, 'High Rise Condo'),
(524, 531, 'Prospect'),
(525, 532, ''),
(526, 535, ''),
(527, 536, ''),
(528, 537, '');

-- --------------------------------------------------------

--
-- Table structure for table `customfielddata`
--

CREATE TABLE IF NOT EXISTS `customfielddata` (
`id` int(11) unsigned NOT NULL,
  `name` varchar(64) COLLATE utf8_unicode_ci DEFAULT NULL,
  `defaultvalue` text COLLATE utf8_unicode_ci,
  `serializeddata` text COLLATE utf8_unicode_ci,
  `serializedlabels` text COLLATE utf8_unicode_ci
) ENGINE=InnoDB AUTO_INCREMENT=18 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

--
-- Dumping data for table `customfielddata`
--

INSERT INTO `customfielddata` (`id`, `name`, `defaultvalue`, `serializeddata`, `serializedlabels`) VALUES
(2, 'Industries', NULL, 'a:9:{i:0;s:10:"Automotive";i:1;s:7:"Banking";i:2;s:17:"Business Services";i:3;s:6:"Energy";i:4;s:18:"Financial Services";i:5;s:9:"Insurance";i:6;s:13:"Manufacturing";i:7;s:6:"Retail";i:8;s:10:"Technology";}', NULL),
(3, 'AccountTypes', NULL, 'a:3:{i:0;s:8:"Prospect";i:1;s:8:"Customer";i:2;s:6:"Vendor";}', NULL),
(4, 'LeadSources', NULL, 'a:4:{i:0;s:14:"Self-Generated";i:1;s:12:"Inbound Call";i:2;s:9:"Tradeshow";i:3;s:13:"Word of Mouth";}', NULL),
(5, 'MeetingCategories', 'Meeting', 'a:2:{i:0;s:7:"Meeting";i:1;s:4:"Call";}', NULL),
(6, 'SalesStages', 'Prospecting', 'a:6:{i:0;s:15:"Initial Contact";i:1;s:18:"First Presentation";i:2;s:17:"Last Presentation";i:3;s:17:"Awaiting Decision";i:4;s:20:"Contract Negotiation";i:5;s:18:"Under Construction";}', NULL),
(7, 'ProductStages', NULL, 'a:3:{i:0;s:4:"Open";i:1;s:4:"Lost";i:2;s:3:"Won";}', NULL),
(8, 'Titles', NULL, 'a:4:{i:0;s:3:"Mr.";i:1;s:4:"Mrs.";i:2;s:3:"Ms.";i:3;s:3:"Dr.";}', NULL),
(9, 'AccountContactAffiliationRoles', NULL, 'a:6:{i:0;s:7:"Billing";i:1;s:8:"Shipping";i:2;s:7:"Support";i:3;s:9:"Technical";i:4;s:14:"Administrative";i:5;s:15:"Project Manager";}', NULL),
(10, 'Comtypecstm', NULL, 'a:3:{i:0;s:15:"High Rise Condo";i:1;s:14:"Low Rise Condo";i:2;s:12:"Luxury Homes";}', NULL),
(11, 'Bulkservprcs', NULL, 'a:4:{i:0;s:5:"Video";i:1;s:8:"Internet";i:2;s:5:"Phone";i:3;s:5:"Alarm";}', NULL),
(12, 'Contractleng', NULL, 'a:11:{i:0;s:7:"5 years";i:1;s:7:"6 years";i:2;s:7:"7 years";i:3;s:7:"8 years";i:4;s:7:"9 years";i:5;s:8:"10 years";i:6;s:8:"11 years";i:7;s:8:"12 years";i:8;s:8:"13 years";i:9;s:8:"14 years";i:10;s:8:"15 years";}', NULL),
(13, 'Consrequestc', NULL, 'a:2:{i:0;s:3:"Yes";i:1;s:2:"No";}', NULL),
(14, 'Status', NULL, 'a:2:{i:0;s:6:"Active";i:1;s:9:"In-Active";}', NULL),
(15, 'Customertype', NULL, 'a:2:{i:0;s:8:"Customer";i:1;s:8:"Prospect";}', NULL),
(16, 'Rampup', NULL, 'a:2:{i:0;s:3:"Yes";i:1;s:2:"No";}', NULL),
(17, 'Contracttype', NULL, 'a:2:{i:0;s:3:"New";i:1;s:7:"Renewal";}', NULL);

-- --------------------------------------------------------

--
-- Table structure for table `customfieldvalue`
--

CREATE TABLE IF NOT EXISTS `customfieldvalue` (
`id` int(11) unsigned NOT NULL,
  `value` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `multiplevaluescustomfield_id` int(11) unsigned DEFAULT NULL
) ENGINE=InnoDB AUTO_INCREMENT=24 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

--
-- Dumping data for table `customfieldvalue`
--

INSERT INTO `customfieldvalue` (`id`, `value`, `multiplevaluescustomfield_id`) VALUES
(18, 'Internet', 7),
(19, 'Video', 7),
(20, 'Video', 8),
(21, 'Internet', 8),
(22, 'Internet', 9),
(23, 'Alarm', 9);

-- --------------------------------------------------------

--
-- Table structure for table `dashboard`
--

CREATE TABLE IF NOT EXISTS `dashboard` (
`id` int(11) unsigned NOT NULL,
  `ownedsecurableitem_id` int(11) unsigned DEFAULT NULL,
  `isdefault` tinyint(1) unsigned DEFAULT NULL,
  `layouttype` varchar(10) COLLATE utf8_unicode_ci DEFAULT NULL,
  `name` varchar(64) COLLATE utf8_unicode_ci DEFAULT NULL,
  `layoutid` int(11) DEFAULT NULL
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

--
-- Dumping data for table `dashboard`
--

INSERT INTO `dashboard` (`id`, `ownedsecurableitem_id`, `isdefault`, `layouttype`, `name`, `layoutid`) VALUES
(1, 312, 1, '50,50', 'Dashboard', 1);

-- --------------------------------------------------------

--
-- Table structure for table `derivedattributemetadata`
--

CREATE TABLE IF NOT EXISTS `derivedattributemetadata` (
`id` int(11) unsigned NOT NULL,
  `name` varchar(64) COLLATE utf8_unicode_ci DEFAULT NULL,
  `modelclassname` varchar(64) COLLATE utf8_unicode_ci DEFAULT NULL,
  `serializedmetadata` text COLLATE utf8_unicode_ci
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `dropdowndependencyderivedattributemetadata`
--

CREATE TABLE IF NOT EXISTS `dropdowndependencyderivedattributemetadata` (
`id` int(11) unsigned NOT NULL,
  `derivedattributemetadata_id` int(11) unsigned DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `email`
--

CREATE TABLE IF NOT EXISTS `email` (
`id` int(11) unsigned NOT NULL,
  `isinvalid` tinyint(1) unsigned DEFAULT NULL,
  `optout` tinyint(1) unsigned DEFAULT NULL,
  `emailaddress` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL
) ENGINE=InnoDB AUTO_INCREMENT=45 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

--
-- Dumping data for table `email`
--

INSERT INTO `email` (`id`, `isinvalid`, `optout`, `emailaddress`) VALUES
(2, NULL, NULL, 'Super.test@test.zurmo.com'),
(3, NULL, NULL, 'Jason.Blue@test.zurmo.com'),
(4, NULL, NULL, 'Jim@test.zurmo.com'),
(5, NULL, NULL, 'John@test.zurmo.com'),
(6, NULL, NULL, 'Sally@test.zurmo.com'),
(7, NULL, NULL, 'Mary@test.zurmo.com'),
(8, NULL, NULL, 'Katie@test.zurmo.com'),
(9, NULL, NULL, 'Jill@test.zurmo.com'),
(10, NULL, NULL, 'Sam@test.zurmo.com'),
(17, NULL, 0, 'Jose.Robinson@GloboChem.com'),
(18, NULL, 0, 'Kirby.Davis@GloboChem.com'),
(19, NULL, 0, 'Laura.Miller@WayneEnterprise.com'),
(20, NULL, 0, 'Walter.Williams@SampleInc.com'),
(21, NULL, 0, 'Alice.Martin@SampleInc.com'),
(22, NULL, 0, 'Jeffrey.Lee@Gringotts.com'),
(23, NULL, 0, 'Maya.Wilson@BigTBurgersandF.com'),
(24, NULL, 0, 'Kirby.Johnson@AlliedBiscuit.com'),
(25, NULL, 0, 'Sarah.Harris@WayneEnterprise.com'),
(26, NULL, 0, 'Sarah.Harris@BigTBurgersandF.com'),
(27, NULL, 0, 'Ester.Taylor@Gringotts.com'),
(28, NULL, 0, 'Jake.Williams@GloboChem.com'),
(29, NULL, 0, 'Kirby.Williams@company.com'),
(30, NULL, 0, 'Ray.Harris@company.com'),
(31, NULL, 0, 'Sophie.Rodriguez@company.com'),
(32, NULL, 0, 'Nev.Lee@company.com'),
(33, NULL, 0, 'Kirby.Lee@company.com'),
(34, NULL, 0, 'Jeffrey.Clark@company.com'),
(35, NULL, 0, 'Lisa.Johnson@company.com'),
(36, NULL, 0, 'Ray.Robinson@company.com'),
(37, NULL, 0, 'Jake.Lewis@company.com'),
(38, NULL, 0, 'Alice.Walker@company.com'),
(39, NULL, 0, 'Jose.Hall@company.com'),
(40, NULL, 0, 'Ray.Martinez@company.com'),
(41, NULL, 0, ''),
(42, NULL, 0, ''),
(43, NULL, 0, 'jmontolio@opticaltel.com'),
(44, NULL, 0, '');

-- --------------------------------------------------------

--
-- Table structure for table `emailaccount`
--

CREATE TABLE IF NOT EXISTS `emailaccount` (
`id` int(11) unsigned NOT NULL,
  `item_id` int(11) unsigned DEFAULT NULL,
  `name` text COLLATE utf8_unicode_ci,
  `fromname` varchar(64) COLLATE utf8_unicode_ci DEFAULT NULL,
  `replytoname` varchar(64) COLLATE utf8_unicode_ci DEFAULT NULL,
  `outboundhost` varchar(64) COLLATE utf8_unicode_ci DEFAULT NULL,
  `outboundusername` varchar(64) COLLATE utf8_unicode_ci DEFAULT NULL,
  `outboundpassword` varchar(128) COLLATE utf8_unicode_ci DEFAULT NULL,
  `outboundsecurity` varchar(3) COLLATE utf8_unicode_ci DEFAULT NULL,
  `outboundtype` varchar(4) COLLATE utf8_unicode_ci DEFAULT NULL,
  `usecustomoutboundsettings` tinyint(1) unsigned DEFAULT NULL,
  `fromaddress` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `replytoaddress` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `outboundport` int(11) DEFAULT NULL,
  `_user_id` int(11) unsigned DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `emailbox`
--

CREATE TABLE IF NOT EXISTS `emailbox` (
`id` int(11) unsigned NOT NULL,
  `item_id` int(11) unsigned DEFAULT NULL,
  `name` varchar(64) COLLATE utf8_unicode_ci DEFAULT NULL,
  `_user_id` int(11) unsigned DEFAULT NULL
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

--
-- Dumping data for table `emailbox`
--

INSERT INTO `emailbox` (`id`, `item_id`, `name`, `_user_id`) VALUES
(2, 99, 'Default', 1),
(3, 601, 'System Notifications', NULL);

-- --------------------------------------------------------

--
-- Table structure for table `emailfolder`
--

CREATE TABLE IF NOT EXISTS `emailfolder` (
`id` int(11) unsigned NOT NULL,
  `item_id` int(11) unsigned DEFAULT NULL,
  `emailbox_id` int(11) unsigned DEFAULT NULL,
  `name` varchar(64) COLLATE utf8_unicode_ci DEFAULT NULL,
  `type` varchar(20) COLLATE utf8_unicode_ci DEFAULT NULL
) ENGINE=InnoDB AUTO_INCREMENT=18 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

--
-- Dumping data for table `emailfolder`
--

INSERT INTO `emailfolder` (`id`, `item_id`, `emailbox_id`, `name`, `type`) VALUES
(2, 100, 2, 'Draft', 'Draft'),
(3, 101, 2, 'Inbox', 'Inbox'),
(4, 102, 2, 'Sent', 'Sent'),
(5, 103, 2, 'Outbox', 'Outbox'),
(6, 104, 2, 'Outbox Error', 'OutboxError'),
(7, 105, 2, 'Outbox Failure', 'OutboxFailure'),
(8, 106, 2, 'Archived', 'Archived'),
(9, 107, 2, 'Archived Unmatched', 'ArchivedUnmatched'),
(10, 602, 3, 'Draft', 'Draft'),
(11, 603, 3, 'Sent', 'Sent'),
(12, 604, 3, 'Outbox', 'Outbox'),
(13, 605, 3, 'Outbox Error', 'OutboxError'),
(14, 606, 3, 'Outbox Failure', 'OutboxFailure'),
(15, 607, 3, 'Inbox', 'Inbox'),
(16, 608, 3, 'Archived', 'Archived'),
(17, 609, 3, 'Archived Unmatched', 'ArchivedUnmatched');

-- --------------------------------------------------------

--
-- Table structure for table `emailmessage`
--

CREATE TABLE IF NOT EXISTS `emailmessage` (
`id` int(11) unsigned NOT NULL,
  `ownedsecurableitem_id` int(11) unsigned DEFAULT NULL,
  `folder_emailfolder_id` int(11) unsigned DEFAULT NULL,
  `content_emailmessagecontent_id` int(11) unsigned DEFAULT NULL,
  `subject` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `sentdatetime` datetime DEFAULT NULL,
  `sendondatetime` datetime DEFAULT NULL,
  `headers` text COLLATE utf8_unicode_ci,
  `sendattempts` int(11) DEFAULT NULL,
  `sender_emailmessagesender_id` int(11) unsigned DEFAULT NULL,
  `error_emailmessagesenderror_id` int(11) unsigned DEFAULT NULL,
  `account_emailaccount_id` int(11) unsigned DEFAULT NULL,
  `emailaccount_id` int(11) unsigned DEFAULT NULL
) ENGINE=InnoDB AUTO_INCREMENT=38 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

--
-- Dumping data for table `emailmessage`
--

INSERT INTO `emailmessage` (`id`, `ownedsecurableitem_id`, `folder_emailfolder_id`, `content_emailmessagecontent_id`, `subject`, `sentdatetime`, `sendondatetime`, `headers`, `sendattempts`, `sender_emailmessagesender_id`, `error_emailmessagesenderror_id`, `account_emailaccount_id`, `emailaccount_id`) VALUES
(2, 43, 8, 2, 'A test archived sent email', '2013-06-02 12:29:51', NULL, NULL, NULL, 2, NULL, NULL, NULL),
(3, 44, 8, 3, 'A test archived sent email', '2013-06-20 12:29:53', NULL, NULL, NULL, 3, NULL, NULL, NULL),
(4, 45, 8, 4, 'A test archived sent email', '2013-06-17 12:29:55', NULL, NULL, NULL, 4, NULL, NULL, NULL),
(5, 46, 8, 5, 'A test archived sent email', '2013-06-22 12:29:58', NULL, NULL, NULL, 5, NULL, NULL, NULL),
(6, 47, 8, 6, 'A test archived sent email', '2013-06-19 12:30:00', NULL, NULL, NULL, 6, NULL, NULL, NULL),
(7, 48, 8, 7, 'A test archived sent email', '2013-06-16 12:30:02', NULL, NULL, NULL, 7, NULL, NULL, NULL),
(8, 49, 8, 8, 'A test archived sent email', '2013-06-02 12:30:05', NULL, NULL, NULL, 8, NULL, NULL, NULL),
(9, 50, 8, 9, 'A test archived sent email', '2013-06-18 12:30:07', NULL, NULL, NULL, 9, NULL, NULL, NULL),
(10, 51, 8, 10, 'A test archived sent email', '2013-05-29 12:30:09', NULL, NULL, NULL, 10, NULL, NULL, NULL),
(11, 52, 8, 11, 'A test archived sent email', '2013-06-19 12:30:11', NULL, NULL, NULL, 11, NULL, NULL, NULL),
(12, 53, 8, 12, 'A test archived sent email', '2013-06-22 12:30:14', NULL, NULL, NULL, 12, NULL, NULL, NULL),
(13, 54, 8, 13, 'A test archived sent email', '2013-06-14 12:30:16', NULL, NULL, NULL, 13, NULL, NULL, NULL),
(14, 55, 8, 14, 'A test archived sent email', '2013-05-26 12:30:18', NULL, NULL, NULL, 14, NULL, NULL, NULL),
(15, 56, 8, 15, 'A test archived sent email', '2013-06-14 12:30:21', NULL, NULL, NULL, 15, NULL, NULL, NULL),
(16, 57, 8, 16, 'A test archived sent email', '2013-06-12 12:30:21', NULL, NULL, NULL, 16, NULL, NULL, NULL),
(17, 58, 8, 17, 'A test archived sent email', '2013-05-27 12:30:21', NULL, NULL, NULL, 17, NULL, NULL, NULL),
(18, 59, 8, 18, 'A test archived sent email', '2013-05-28 12:30:21', NULL, NULL, NULL, 18, NULL, NULL, NULL),
(19, 60, 8, 19, 'A test archived sent email', '2013-06-06 12:30:21', NULL, NULL, NULL, 19, NULL, NULL, NULL),
(20, 71, 8, 20, 'A test archived sent email', '2013-06-11 12:30:25', NULL, NULL, NULL, 20, NULL, NULL, NULL),
(21, 72, 8, 21, 'A test archived sent email', '2013-05-31 12:30:25', NULL, NULL, NULL, 21, NULL, NULL, NULL),
(22, 73, 8, 22, 'A test archived sent email', '2013-06-11 12:30:25', NULL, NULL, NULL, 22, NULL, NULL, NULL),
(23, 74, 8, 23, 'A test archived sent email', '2013-05-28 12:30:25', NULL, NULL, NULL, 23, NULL, NULL, NULL),
(24, 75, 8, 24, 'A test archived sent email', '2013-06-07 12:30:25', NULL, NULL, NULL, 24, NULL, NULL, NULL),
(25, 76, 8, 25, 'A test archived sent email', '2013-06-19 12:30:25', NULL, NULL, NULL, 25, NULL, NULL, NULL),
(26, 77, 8, 26, 'A test archived sent email', '2013-05-26 12:30:26', NULL, NULL, NULL, 26, NULL, NULL, NULL),
(27, 78, 8, 27, 'A test archived sent email', '2013-06-09 12:30:26', NULL, NULL, NULL, 27, NULL, NULL, NULL),
(28, 79, 8, 28, 'A test archived sent email', '2013-06-10 12:30:26', NULL, NULL, NULL, 28, NULL, NULL, NULL),
(29, 80, 8, 29, 'A test archived sent email', '2013-05-28 12:30:26', NULL, NULL, NULL, 29, NULL, NULL, NULL),
(30, 81, 8, 30, 'A test archived sent email', '2013-06-10 12:30:26', NULL, NULL, NULL, 30, NULL, NULL, NULL),
(31, 82, 8, 31, 'A test archived sent email', '2013-05-30 12:30:27', NULL, NULL, NULL, 31, NULL, NULL, NULL),
(32, 83, 8, 32, 'A test archived sent email', '2013-06-15 12:30:27', NULL, NULL, NULL, 32, NULL, NULL, NULL),
(33, 84, 8, 33, 'A test archived sent email', '2013-06-11 12:30:27', NULL, NULL, NULL, 33, NULL, NULL, NULL),
(34, 85, 8, 34, 'A test archived sent email', '2013-06-01 12:30:27', NULL, NULL, NULL, 34, NULL, NULL, NULL),
(35, 86, 8, 35, 'A test archived sent email', '2013-06-22 12:30:27', NULL, NULL, NULL, 35, NULL, NULL, NULL),
(36, 87, 8, 36, 'A test archived sent email', '2013-06-08 12:30:27', NULL, NULL, NULL, 36, NULL, NULL, NULL),
(37, 88, 8, 37, 'A test archived sent email', '2013-06-15 12:30:28', NULL, NULL, NULL, 37, NULL, NULL, NULL);

-- --------------------------------------------------------

--
-- Table structure for table `emailmessageactivity`
--

CREATE TABLE IF NOT EXISTS `emailmessageactivity` (
`id` int(11) unsigned NOT NULL,
  `item_id` int(11) unsigned DEFAULT NULL,
  `latestdatetime` datetime DEFAULT NULL,
  `latestsourceip` text COLLATE utf8_unicode_ci,
  `type` int(11) DEFAULT NULL,
  `quantity` int(11) DEFAULT NULL,
  `person_id` int(11) unsigned DEFAULT NULL,
  `emailmessageurl_id` int(11) unsigned DEFAULT NULL
) ENGINE=InnoDB AUTO_INCREMENT=40 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

--
-- Dumping data for table `emailmessageactivity`
--

INSERT INTO `emailmessageactivity` (`id`, `item_id`, `latestdatetime`, `latestsourceip`, `type`, `quantity`, `person_id`, `emailmessageurl_id`) VALUES
(4, 108, '2013-06-25 12:29:49', '10.11.12.13', 2, 34, 23, 13),
(5, 109, '2013-06-25 12:29:50', '10.11.12.13', 2, 78, 15, 6),
(6, 110, '2013-06-25 12:29:50', '10.11.12.13', 2, 93, 23, 8),
(7, 111, '2013-06-25 12:29:50', '10.11.12.13', 2, 84, 23, 2),
(8, 112, '2013-06-25 12:29:50', '10.11.12.13', 2, 28, 23, 19),
(9, 113, '2013-06-25 12:29:50', '10.11.12.13', 2, 69, 12, 16),
(10, 114, '2013-06-25 12:29:50', '10.11.12.13', 2, 89, 15, 15),
(11, 115, '2013-06-25 12:29:50', '10.11.12.13', 2, 73, 15, 2),
(12, 116, '2013-06-25 12:29:50', '10.11.12.13', 2, 48, 15, 17),
(13, 117, '2013-06-25 12:29:50', '10.11.12.13', 2, 100, 15, 18),
(14, 118, '2013-06-25 12:29:50', '10.11.12.13', 2, 26, 23, 4),
(15, 119, '2013-06-25 12:29:51', '10.11.12.13', 2, 69, 13, 15),
(16, 120, '2013-06-25 12:29:51', '10.11.12.13', 1, 25, 14, NULL),
(17, 121, '2013-06-25 12:29:51', '10.11.12.13', 2, 31, 14, 17),
(18, 122, '2013-06-25 12:29:51', '10.11.12.13', 4, 93, 16, NULL),
(19, 123, '2013-06-25 12:29:51', '10.11.12.13', 2, 81, 15, 19),
(20, 124, '2013-06-25 12:29:51', '10.11.12.13', 1, 33, 15, NULL),
(21, 125, '2013-06-25 12:29:51', '10.11.12.13', 1, 88, 19, NULL),
(22, 154, '2013-06-25 12:30:24', '10.11.12.13', 2, 70, 23, 2),
(23, 155, '2013-06-25 12:30:24', '10.11.12.13', 2, 96, 22, 4),
(24, 156, '2013-06-25 12:30:24', '10.11.12.13', 2, 74, 21, 6),
(25, 157, '2013-06-25 12:30:24', '10.11.12.13', 2, 90, 19, 13),
(26, 158, '2013-06-25 12:30:24', '10.11.12.13', 4, 24, 18, NULL),
(27, 159, '2013-06-25 12:30:24', '10.11.12.13', 2, 18, 20, 13),
(28, 160, '2013-06-25 12:30:24', '10.11.12.13', 2, 94, 13, 19),
(29, 161, '2013-06-25 12:30:24', '10.11.12.13', 2, 56, 18, 14),
(30, 162, '2013-06-25 12:30:24', '10.11.12.13', 2, 14, 18, 16),
(31, 163, '2013-06-25 12:30:24', '10.11.12.13', 2, 45, 12, 11),
(32, 164, '2013-06-25 12:30:24', '10.11.12.13', 2, 63, 14, 4),
(33, 165, '2013-06-25 12:30:24', '10.11.12.13', 4, 95, 16, NULL),
(34, 166, '2013-06-25 12:30:24', '10.11.12.13', 2, 31, 19, 7),
(35, 167, '2013-06-25 12:30:24', '10.11.12.13', 2, 30, 18, 18),
(36, 168, '2013-06-25 12:30:24', '10.11.12.13', 2, 84, 23, 18),
(37, 169, '2013-06-25 12:30:24', '10.11.12.13', 2, 93, 17, 3),
(38, 170, '2013-06-25 12:30:25', '10.11.12.13', 1, 55, 18, NULL),
(39, 171, '2013-06-25 12:30:25', '10.11.12.13', 4, 54, 13, NULL);

-- --------------------------------------------------------

--
-- Table structure for table `emailmessagecontent`
--

CREATE TABLE IF NOT EXISTS `emailmessagecontent` (
`id` int(11) unsigned NOT NULL,
  `htmlcontent` text COLLATE utf8_unicode_ci,
  `textcontent` text COLLATE utf8_unicode_ci
) ENGINE=InnoDB AUTO_INCREMENT=38 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

--
-- Dumping data for table `emailmessagecontent`
--

INSERT INTO `emailmessagecontent` (`id`, `htmlcontent`, `textcontent`) VALUES
(2, 'Some fake HTML content', 'My First Message'),
(3, 'Some fake HTML content', 'My First Message'),
(4, 'Some fake HTML content', 'My First Message'),
(5, 'Some fake HTML content', 'My First Message'),
(6, 'Some fake HTML content', 'My First Message'),
(7, 'Some fake HTML content', 'My First Message'),
(8, 'Some fake HTML content', 'My First Message'),
(9, 'Some fake HTML content', 'My First Message'),
(10, 'Some fake HTML content', 'My First Message'),
(11, 'Some fake HTML content', 'My First Message'),
(12, 'Some fake HTML content', 'My First Message'),
(13, 'Some fake HTML content', 'My First Message'),
(14, 'Some fake HTML content', 'My First Message'),
(15, 'Some fake HTML content', 'My First Message'),
(16, 'Some fake HTML content', 'My First Message'),
(17, 'Some fake HTML content', 'My First Message'),
(18, 'Some fake HTML content', 'My First Message'),
(19, 'Some fake HTML content', 'My First Message'),
(20, 'Some fake HTML content', 'My First Message'),
(21, 'Some fake HTML content', 'My First Message'),
(22, 'Some fake HTML content', 'My First Message'),
(23, 'Some fake HTML content', 'My First Message'),
(24, 'Some fake HTML content', 'My First Message'),
(25, 'Some fake HTML content', 'My First Message'),
(26, 'Some fake HTML content', 'My First Message'),
(27, 'Some fake HTML content', 'My First Message'),
(28, 'Some fake HTML content', 'My First Message'),
(29, 'Some fake HTML content', 'My First Message'),
(30, 'Some fake HTML content', 'My First Message'),
(31, 'Some fake HTML content', 'My First Message'),
(32, 'Some fake HTML content', 'My First Message'),
(33, 'Some fake HTML content', 'My First Message'),
(34, 'Some fake HTML content', 'My First Message'),
(35, 'Some fake HTML content', 'My First Message'),
(36, 'Some fake HTML content', 'My First Message'),
(37, 'Some fake HTML content', 'My First Message');

-- --------------------------------------------------------

--
-- Table structure for table `emailmessagerecipient`
--

CREATE TABLE IF NOT EXISTS `emailmessagerecipient` (
`id` int(11) unsigned NOT NULL,
  `personoraccount_item_id` int(11) unsigned DEFAULT NULL,
  `toname` varchar(128) COLLATE utf8_unicode_ci DEFAULT NULL,
  `toaddress` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `type` int(11) DEFAULT NULL,
  `emailmessage_id` int(11) unsigned DEFAULT NULL
) ENGINE=InnoDB AUTO_INCREMENT=38 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

--
-- Dumping data for table `emailmessagerecipient`
--

INSERT INTO `emailmessagerecipient` (`id`, `personoraccount_item_id`, `toname`, `toaddress`, `type`, `emailmessage_id`) VALUES
(2, 86, 'Walter Williams', 'bob.message@zurmotest.com', 1, 2),
(3, 86, 'Walter Williams', 'bob.message@zurmotest.com', 1, 3),
(4, 94, 'Jake Williams', 'bob.message@zurmotest.com', 1, 4),
(5, 83, 'Jose Robinson', 'bob.message@zurmotest.com', 1, 5),
(6, 85, 'Laura Miller', 'bob.message@zurmotest.com', 1, 6),
(7, 94, 'Jake Williams', 'bob.message@zurmotest.com', 1, 7),
(8, 87, 'Alice Martin', 'bob.message@zurmotest.com', 1, 8),
(9, 86, 'Walter Williams', 'bob.message@zurmotest.com', 1, 9),
(10, 86, 'Walter Williams', 'bob.message@zurmotest.com', 1, 10),
(11, 84, 'Kirby Davis', 'bob.message@zurmotest.com', 1, 11),
(12, 91, 'Sarah Harris', 'bob.message@zurmotest.com', 1, 12),
(13, 87, 'Alice Martin', 'bob.message@zurmotest.com', 1, 13),
(14, 90, 'Kirby Johnson', 'bob.message@zurmotest.com', 1, 14),
(15, 84, 'Kirby Davis', 'bob.message@zurmotest.com', 1, 15),
(16, 85, 'Laura Miller', 'bob.message@zurmotest.com', 1, 16),
(17, 90, 'Kirby Johnson', 'bob.message@zurmotest.com', 1, 17),
(18, 86, 'Walter Williams', 'bob.message@zurmotest.com', 1, 18),
(19, 86, 'Walter Williams', 'bob.message@zurmotest.com', 1, 19),
(20, 88, 'Jeffrey Lee', 'bob.message@zurmotest.com', 1, 20),
(21, 94, 'Jake Williams', 'bob.message@zurmotest.com', 1, 21),
(22, 85, 'Laura Miller', 'bob.message@zurmotest.com', 1, 22),
(23, 90, 'Kirby Johnson', 'bob.message@zurmotest.com', 1, 23),
(24, 87, 'Alice Martin', 'bob.message@zurmotest.com', 1, 24),
(25, 85, 'Laura Miller', 'bob.message@zurmotest.com', 1, 25),
(26, 86, 'Walter Williams', 'bob.message@zurmotest.com', 1, 26),
(27, 84, 'Kirby Davis', 'bob.message@zurmotest.com', 1, 27),
(28, 87, 'Alice Martin', 'bob.message@zurmotest.com', 1, 28),
(29, 91, 'Sarah Harris', 'bob.message@zurmotest.com', 1, 29),
(30, 93, 'Ester Taylor', 'bob.message@zurmotest.com', 1, 30),
(31, 89, 'Maya Wilson', 'bob.message@zurmotest.com', 1, 31),
(32, 92, 'Sarah Harris', 'bob.message@zurmotest.com', 1, 32),
(33, 89, 'Maya Wilson', 'bob.message@zurmotest.com', 1, 33),
(34, 94, 'Jake Williams', 'bob.message@zurmotest.com', 1, 34),
(35, 83, 'Jose Robinson', 'bob.message@zurmotest.com', 1, 35),
(36, 91, 'Sarah Harris', 'bob.message@zurmotest.com', 1, 36),
(37, 90, 'Kirby Johnson', 'bob.message@zurmotest.com', 1, 37);

-- --------------------------------------------------------

--
-- Table structure for table `emailmessagerecipient_item`
--

CREATE TABLE IF NOT EXISTS `emailmessagerecipient_item` (
`id` int(11) unsigned NOT NULL,
  `emailmessagerecipient_id` int(11) unsigned DEFAULT NULL,
  `item_id` int(11) unsigned DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `emailmessagesender`
--

CREATE TABLE IF NOT EXISTS `emailmessagesender` (
`id` int(11) unsigned NOT NULL,
  `personoraccount_item_id` int(11) unsigned DEFAULT NULL,
  `fromname` varchar(128) COLLATE utf8_unicode_ci DEFAULT NULL,
  `fromaddress` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL
) ENGINE=InnoDB AUTO_INCREMENT=38 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

--
-- Dumping data for table `emailmessagesender`
--

INSERT INTO `emailmessagesender` (`id`, `personoraccount_item_id`, `fromname`, `fromaddress`) VALUES
(2, 1, 'Super User', 'super@zurmotest.com'),
(3, 1, 'Super User', 'super@zurmotest.com'),
(4, 1, 'Super User', 'super@zurmotest.com'),
(5, 1, 'Super User', 'super@zurmotest.com'),
(6, 1, 'Super User', 'super@zurmotest.com'),
(7, 1, 'Super User', 'super@zurmotest.com'),
(8, 1, 'Super User', 'super@zurmotest.com'),
(9, 1, 'Super User', 'super@zurmotest.com'),
(10, 1, 'Super User', 'super@zurmotest.com'),
(11, 1, 'Super User', 'super@zurmotest.com'),
(12, 1, 'Super User', 'super@zurmotest.com'),
(13, 1, 'Super User', 'super@zurmotest.com'),
(14, 1, 'Super User', 'super@zurmotest.com'),
(15, 1, 'Super User', 'super@zurmotest.com'),
(16, 1, 'Super User', 'super@zurmotest.com'),
(17, 1, 'Super User', 'super@zurmotest.com'),
(18, 1, 'Super User', 'super@zurmotest.com'),
(19, 1, 'Super User', 'super@zurmotest.com'),
(20, 1, 'Super User', 'super@zurmotest.com'),
(21, 1, 'Super User', 'super@zurmotest.com'),
(22, 1, 'Super User', 'super@zurmotest.com'),
(23, 1, 'Super User', 'super@zurmotest.com'),
(24, 1, 'Super User', 'super@zurmotest.com'),
(25, 1, 'Super User', 'super@zurmotest.com'),
(26, 1, 'Super User', 'super@zurmotest.com'),
(27, 1, 'Super User', 'super@zurmotest.com'),
(28, 1, 'Super User', 'super@zurmotest.com'),
(29, 1, 'Super User', 'super@zurmotest.com'),
(30, 1, 'Super User', 'super@zurmotest.com'),
(31, 1, 'Super User', 'super@zurmotest.com'),
(32, 1, 'Super User', 'super@zurmotest.com'),
(33, 1, 'Super User', 'super@zurmotest.com'),
(34, 1, 'Super User', 'super@zurmotest.com'),
(35, 1, 'Super User', 'super@zurmotest.com'),
(36, 1, 'Super User', 'super@zurmotest.com'),
(37, 1, 'Super User', 'super@zurmotest.com');

-- --------------------------------------------------------

--
-- Table structure for table `emailmessagesenderror`
--

CREATE TABLE IF NOT EXISTS `emailmessagesenderror` (
`id` int(11) unsigned NOT NULL,
  `createddatetime` datetime DEFAULT NULL,
  `serializeddata` text COLLATE utf8_unicode_ci
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `emailmessagesender_item`
--

CREATE TABLE IF NOT EXISTS `emailmessagesender_item` (
`id` int(11) unsigned NOT NULL,
  `emailmessagesender_id` int(11) unsigned DEFAULT NULL,
  `item_id` int(11) unsigned DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `emailmessageurl`
--

CREATE TABLE IF NOT EXISTS `emailmessageurl` (
`id` int(11) unsigned NOT NULL,
  `url` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `emailmessageactivity_id` int(11) unsigned DEFAULT NULL
) ENGINE=InnoDB AUTO_INCREMENT=20 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

--
-- Dumping data for table `emailmessageurl`
--

INSERT INTO `emailmessageurl` (`id`, `url`, `emailmessageactivity_id`) VALUES
(2, 'http://0.zurmo.com/', NULL),
(3, 'http://1.zurmo.com/', NULL),
(4, 'http://2.zurmo.com/', NULL),
(5, 'http://3.zurmo.com/', NULL),
(6, 'http://4.zurmo.com/', NULL),
(7, 'http://5.zurmo.com/', NULL),
(8, 'http://6.zurmo.com/', NULL),
(9, 'http://7.zurmo.com/', NULL),
(10, 'http://8.zurmo.com/', NULL),
(11, 'http://9.zurmo.com/', NULL),
(12, 'http://10.zurmo.com/', NULL),
(13, 'http://11.zurmo.com/', NULL),
(14, 'http://12.zurmo.com/', NULL),
(15, 'http://13.zurmo.com/', NULL),
(16, 'http://14.zurmo.com/', NULL),
(17, 'http://15.zurmo.com/', NULL),
(18, 'http://16.zurmo.com/', NULL),
(19, 'http://17.zurmo.com/', NULL);

-- --------------------------------------------------------

--
-- Table structure for table `emailmessage_read`
--

CREATE TABLE IF NOT EXISTS `emailmessage_read` (
  `securableitem_id` int(11) unsigned NOT NULL,
  `munge_id` varchar(12) COLLATE utf8_unicode_ci NOT NULL,
  `count` int(8) unsigned NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

--
-- Dumping data for table `emailmessage_read`
--

INSERT INTO `emailmessage_read` (`securableitem_id`, `munge_id`, `count`) VALUES
(44, 'G3', 1),
(44, 'R2', 1),
(45, 'G3', 1),
(45, 'R2', 1),
(46, 'G3', 1),
(47, 'G3', 1),
(47, 'R2', 1),
(48, 'G3', 1),
(48, 'R2', 1),
(49, 'G3', 1),
(50, 'G3', 1),
(50, 'R2', 1),
(51, 'G3', 1),
(51, 'R2', 1),
(52, 'G3', 1),
(52, 'R2', 1),
(53, 'G3', 1),
(53, 'R2', 1),
(54, 'G3', 1),
(54, 'R2', 1),
(55, 'G3', 1),
(55, 'R2', 1),
(56, 'G3', 1),
(56, 'R2', 1),
(57, 'G3', 1),
(57, 'R2', 1),
(58, 'G3', 1),
(58, 'R2', 1),
(59, 'G3', 1),
(59, 'R2', 1),
(60, 'G3', 1),
(60, 'R2', 1),
(61, 'G3', 1),
(61, 'R2', 1),
(72, 'G3', 1),
(72, 'R2', 1),
(73, 'G3', 1),
(73, 'R2', 1),
(74, 'G3', 1),
(74, 'R2', 1),
(75, 'G3', 1),
(75, 'R2', 1),
(76, 'G3', 1),
(76, 'R2', 1),
(77, 'G3', 1),
(77, 'R2', 1),
(78, 'G3', 1),
(78, 'R2', 1),
(79, 'G3', 1),
(79, 'R2', 1),
(80, 'G3', 1),
(80, 'R2', 1),
(81, 'G3', 1),
(81, 'R2', 1),
(82, 'G3', 1),
(82, 'R2', 1),
(83, 'G3', 1),
(83, 'R2', 1),
(84, 'G3', 1),
(84, 'R2', 1),
(85, 'G3', 1),
(85, 'R2', 1),
(86, 'G3', 1),
(86, 'R2', 1),
(87, 'G3', 1),
(87, 'R2', 1),
(88, 'G3', 1),
(88, 'R2', 1),
(89, 'G3', 1),
(89, 'R2', 1);

-- --------------------------------------------------------

--
-- Table structure for table `emailsignature`
--

CREATE TABLE IF NOT EXISTS `emailsignature` (
`id` int(11) unsigned NOT NULL,
  `_user_id` int(11) unsigned DEFAULT NULL,
  `textcontent` text COLLATE utf8_unicode_ci,
  `htmlcontent` text COLLATE utf8_unicode_ci
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `emailtemplate`
--

CREATE TABLE IF NOT EXISTS `emailtemplate` (
`id` int(11) unsigned NOT NULL,
  `ownedsecurableitem_id` int(11) unsigned DEFAULT NULL,
  `modelclassname` varchar(64) COLLATE utf8_unicode_ci DEFAULT NULL,
  `name` varchar(64) COLLATE utf8_unicode_ci DEFAULT NULL,
  `subject` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `language` varchar(2) COLLATE utf8_unicode_ci DEFAULT NULL,
  `htmlcontent` text COLLATE utf8_unicode_ci,
  `textcontent` text COLLATE utf8_unicode_ci,
  `type` int(11) DEFAULT NULL,
  `isdraft` tinyint(1) unsigned DEFAULT NULL,
  `builttype` int(11) DEFAULT NULL,
  `serializeddata` text COLLATE utf8_unicode_ci,
  `isfeatured` tinyint(1) unsigned DEFAULT NULL
) ENGINE=InnoDB AUTO_INCREMENT=14 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

--
-- Dumping data for table `emailtemplate`
--

INSERT INTO `emailtemplate` (`id`, `ownedsecurableitem_id`, `modelclassname`, `name`, `subject`, `language`, `htmlcontent`, `textcontent`, `type`, `isdraft`, `builttype`, `serializeddata`, `isfeatured`) VALUES
(2, 92, 'Contact', 'Happy Birthday', 'Happy Birthday', 'en', '<img src="http://zurmo.com/img/logo.png" alt="zurmo" />''s source code is hosted on bitbucket while we use <img src="http://www.selenic.com/hg-logo/droplets-50.png" alt="mercurial" /> for version control.', 'Zurmo''s source code is hosted on bitbucket while we use mercurial for version control.', 1, 0, 2, NULL, NULL),
(3, 93, 'Contact', 'Discount', 'Special Offer, 10% discount', 'es', '<img src="http://zurmo.com/img/logo.png" alt="zurmo" />''s source code is hosted on bitbucket while we use <img src="http://www.selenic.com/hg-logo/droplets-50.png" alt="mercurial" /> for version control.', 'Zurmo''s source code is hosted on bitbucket while we use mercurial for version control.', 2, 0, 2, NULL, NULL),
(4, 94, 'Account', 'Downtime Alert', 'Planned Downtime', 'it', '<img src="http://zurmo.com/img/logo.png" alt="zurmo" />''s source code is hosted on bitbucket while we use <img src="http://www.selenic.com/hg-logo/droplets-50.png" alt="mercurial" /> for version control.', 'Zurmo''s source code is hosted on bitbucket while we use mercurial for version control.', 1, 0, 2, NULL, NULL),
(5, 95, 'Contact', 'Sales decrease', 'Q4 Sales decrease', 'fr', '<img src="http://zurmo.com/img/logo.png" alt="zurmo" />''s source code is hosted on bitbucket while we use <img src="http://www.selenic.com/hg-logo/droplets-50.png" alt="mercurial" /> for version control.', 'Zurmo''s source code is hosted on bitbucket while we use mercurial for version control.', 2, 0, 2, NULL, NULL),
(6, 96, 'Task', 'Missions alert', 'Upcoming Missions', 'de', '<img src="http://zurmo.com/img/logo.png" alt="zurmo" />''s source code is hosted on bitbucket while we use <img src="http://www.selenic.com/hg-logo/droplets-50.png" alt="mercurial" /> for version control.', 'Zurmo''s source code is hosted on bitbucket while we use mercurial for version control.', 1, 0, 2, NULL, NULL),
(7, 97, 'Contact', 'Inbox Update', 'New Inbox Module is live', 'en', '<img src="http://zurmo.com/img/logo.png" alt="zurmo" />''s source code is hosted on bitbucket while we use <img src="http://www.selenic.com/hg-logo/droplets-50.png" alt="mercurial" /> for version control.', 'Zurmo''s source code is hosted on bitbucket while we use mercurial for version control.', 2, 0, 2, NULL, NULL),
(8, 291, NULL, 'Blank', 'Blank', 'en', '', '', NULL, 0, 3, '{"baseTemplateId":"","icon":"icon-template-0","dom":{"canvas1":{"content":{"builderrowelement_1393965668_53163a6448794":{"content":{"buildercolumnelement_1393965668_53163a644866d":{"content":[],"properties":[],"class":"BuilderColumnElement"}},"properties":{"backend":{"configuration":"1"}},"class":"BuilderRowElement"}},"properties":{"frontend":{"inlineStyles":{"background-color":"#ffffff","color":"#545454"}}},"class":"BuilderCanvasElement"}}}', NULL),
(9, 292, NULL, '1 Column', '1 Column', 'en', '', '', NULL, 0, 3, '{"baseTemplateId":"","icon":"icon-template-5","dom":{"canvas1":{"content":{"builderheaderimagetextelement_1393965594_53163a1a0eb53":{"content":{"buildercolumnelement_1393965594_53163a1a0ef48":{"content":{"builderimageelement_1393965594_53163a1a0ee52":{"content":{"image":"<img src=\\"http:\\/\\/placehold.it\\/200x50\\">"},"properties":[],"class":"BuilderImageElement"}},"properties":[],"class":"BuilderColumnElement"},"buildercolumnelement_1393965594_53163a1a145cc":{"content":{"builderheadertextelement_1393965594_53163a1a14515":{"content":{"text":"Acme Inc. Newsletter"},"properties":{"frontend":{"inlineStyles":{"color":"#ffffff","font-weight":"bold","text-align":"right"}}},"class":"BuilderHeaderTextElement"}},"properties":[],"class":"BuilderColumnElement"}},"properties":{"backend":{"configuration":"1:2","header":"1"},"frontend":{"inlineStyles":{"background-color":"#282a76"}}},"class":"BuilderHeaderImageTextElement"},"builderrowelement_1393965668_53163a6448794":{"content":{"buildercolumnelement_1393965668_53163a644866d":{"content":{"buildertitleelement_1393965668_53163a6447762":{"content":{"text":"Hello there William S..."},"properties":{"backend":{"headingLevel":"h3"},"frontend":{"inlineStyles":{"color":"#666666","font-size":"24","font-weight":"bold","text-align":"center"}}},"class":"BuilderTitleElement"},"builderimageelement_1393970522_53164d5a3787a":{"content":{"image":"<img src=\\"http:\\/\\/placehold.it\\/580x180\\">"},"properties":[],"class":"BuilderImageElement"},"builderexpanderelement_1393970557_53164d7d2881e":{"content":[],"properties":{"frontend":{"height":"10"}},"class":"BuilderExpanderElement"},"buildertextelement_1393965781_53163ad53b77c":{"content":{"text":"\\n<p>\\n    Orsino, the <i>Duke of Illyria<\\/i>, is consumed by his passion for the melancholy Countess Olivia. His ostentatious musings on the nature of love begin with what has become one of Shakespeare''s most famous lines: \\"If music be the food of love, play on.\\" It is apparent that Orsino''s love is hollow. He is a romantic dreamer, for whom the idea of being in love is most important. When Valentine gives him the terrible news that <b>Olivia<\\/b> plans to seclude herself for seven years to mourn her deceased brother, Orsino seems unfazed, and hopes Olivia may one day be as bewitched by love (the one self king) as he. Fittingly, the scene ends with Orsino off to lay in a bed of flowers, where he can be alone with his love-thoughts. Later in the play it will be up to Viola to teach Orsino the true meaning of love.\\n<\\/p>\\n"},"properties":[],"class":"BuilderTextElement"},"builderbuttonelement_1393965942_53163b76e666c":{"content":[],"properties":{"backend":{"text":"Call Me","sizeClass":"medium-button","align":"left"},"frontend":{"href":"http:\\/\\/localhost\\/Zurmo\\/app\\/index.php","target":"_blank","inlineStyles":{"background-color":"#97c43d","border-color":"#7cb830"}}},"class":"BuilderButtonElement"},"builderdividerelement_1393965948_53163b7cb98ae":{"content":[],"properties":{"frontend":{"inlineStyles":{"border-top-width":"1","border-top-style":"solid","border-top-color":"#cccccc"}},"backend":{"divider-padding":"10"}},"class":"BuilderDividerElement"},"buildersocialelement_1394060039_5317ab07cf03d":{"content":[],"properties":{"backend":{"layout":"vertical","services":{"Twitter":{"enabled":"1","url":"http:\\/\\/www.twitter.com\\/"},"Facebook":{"enabled":"1","url":"http:\\/\\/www.facebook.com\\/"},"GooglePlus":{"enabled":"1","url":"http:\\/\\/gplus.com"}}}},"class":"BuilderSocialElement"},"builderexpanderelement_1393970592_53164da0bd137":{"content":[],"properties":{"frontend":{"height":"10"}},"class":"BuilderExpanderElement"},"builderfooterelement_1393966090_53163c0ac51bd":{"content":{"text":"[[GLOBAL^MARKETING^FOOTER^HTML]]"},"properties":{"frontend":{"inlineStyles":{"background-color":"#efefef","font-size":"10"}}},"class":"BuilderFooterElement"}},"properties":[],"class":"BuilderColumnElement"}},"properties":[],"class":"BuilderRowElement"}},"properties":{"frontend":{"inlineStyles":{"background-color":"#ffffff","color":"#545454"}}},"class":"BuilderCanvasElement"}}}', NULL),
(10, 293, NULL, '2 Columns', '2 Columns', 'en', '', '', NULL, 0, 3, '{"baseTemplateId":"","icon":"icon-template-2","dom":{"canvas1":{"content":{"builderheaderimagetextelement_1393965594_53163a1a0eb53":{"content":{"buildercolumnelement_1393965594_53163a1a0ef48":{"content":{"builderimageelement_1393965594_53163a1a0ee52":{"content":{"image":"<img src=\\"http:\\/\\/placehold.it\\/200x50\\">"},"properties":[],"class":"BuilderImageElement"}},"properties":[],"class":"BuilderColumnElement"},"buildercolumnelement_1393965594_53163a1a145cc":{"content":{"builderheadertextelement_1393965594_53163a1a14515":{"content":{"text":"Acme Inc. Newsletter"},"properties":{"frontend":{"inlineStyles":{"color":"#ffffff","font-weight":"bold","text-align":"right"}}},"class":"BuilderHeaderTextElement"}},"properties":[],"class":"BuilderColumnElement"}},"properties":{"backend":{"configuration":"1:2","header":"1"},"frontend":{"inlineStyles":{"background-color":"#282a76"}}},"class":"BuilderHeaderImageTextElement"},"builderrowelement_1394062546_5317b4d264a62":{"content":{"buildercolumnelement_1394062546_5317b4d26488b":{"content":{"buildertitleelement_1394062546_5317b4d263942":{"content":{"text":"Hello there William S..."},"properties":{"backend":{"headingLevel":"h1"},"frontend":{"inlineStyles":{"color":"#666666","font-size":"28","font-weight":"bold","line-height":"200"}}},"class":"BuilderTitleElement"}},"properties":[],"class":"BuilderColumnElement"}},"properties":[],"class":"BuilderRowElement"},"builderrowelement_1393965668_53163a6448794":{"content":{"buildercolumnelement_1393965668_53163a644866d":{"content":{"buildertextelement_1393965781_53163ad53b77c":{"content":{"text":"\\n<p>\\n    Orsino, the <i>Duke of Illyria<\\/i>, is consumed by his passion for the melancholy Countess Olivia. His ostentatious musings on the nature of love begin with what has become one of Shakespeare''s most famous lines: \\"If music be the food of love, play on.\\" It is apparent that Orsino''s love is hollow. He is a romantic dreamer, for whom the idea of being in love is most important. When Valentine gives him the terrible news that <b>Olivia<\\/b> plans to seclude herself for seven years to mourn her deceased brother, Orsino seems unfazed, and hopes Olivia may one day be as bewitched by love (the one self king) as he. Fittingly, the scene ends with Orsino off to lay in a bed of flowers, where he can be alone with his love-thoughts. Later in the play it will be up to Viola to teach Orsino the true meaning of love.\\n<\\/p>\\n"},"properties":[],"class":"BuilderTextElement"},"builderbuttonelement_1393965942_53163b76e666c":{"content":[],"properties":{"backend":{"text":"Contact Us Now","sizeClass":"medium-button","align":"left"},"frontend":{"href":"http:\\/\\/localhost\\/Zurmo\\/app\\/index.php","target":"_blank","inlineStyles":{"background-color":"#97c43d","border-color":"#7cb830"}}},"class":"BuilderButtonElement"}},"properties":[],"class":"BuilderColumnElement"},"buildercolumnelement_1394061698_5317b182c1f19":{"content":{"buildertextelement_1394061967_5317b28fc8088":{"content":{"text":"\\n<b>New Articles<\\/b>\\n<ul>\\n    <li>Article Name about something<\\/li>\\n    <li>10 ways to create email templates<\\/li>\\n    <li>Great new marketing tools from Acme<\\/li>\\n    <li>Best blog post of the year<\\/li>\\n    <li>Meet our new chef<\\/li>\\n<\\/ul>\\n"},"properties":{"frontend":{"inlineStyles":{"background-color":"#f6f6f7","color":"#323232","font-size":"16"}}},"class":"BuilderTextElement"},"builderexpanderelement_1394062193_5317b37137abc":{"content":[],"properties":{"frontend":{"height":"10"}},"class":"BuilderExpanderElement"},"buildertitleelement_1394062361_5317b419e1c51":{"content":{"text":"Acme Elsewhere"},"properties":{"backend":{"headingLevel":"h3"},"frontend":{"inlineStyles":{"color":"#6c1d1d","font-weight":"bold","line-height":"200"}}},"class":"BuilderTitleElement"},"buildersocialelement_1394060039_5317ab07cf03d":{"content":[],"properties":{"backend":{"layout":"vertical","services":{"Twitter":{"enabled":"1","url":"http:\\/\\/www.twitter.com\\/"},"Facebook":{"enabled":"1","url":"http:\\/\\/www.facebook.com\\/"},"GooglePlus":{"enabled":"1","url":"http:\\/\\/gplus.com"}}}},"class":"BuilderSocialElement"}},"properties":[],"class":"BuilderColumnElement"}},"properties":{"backend":{"configuration":"2"}},"class":"BuilderRowElement"},"builderrowelement_1394062652_5317b53c906f9":{"content":{"buildercolumnelement_1394062652_5317b53c90615":{"content":{"builderdividerelement_1394062652_5317b53c901fc":{"content":[],"properties":{"frontend":{"inlineStyles":{"border-top-width":"1","border-top-style":"dotted","border-top-color":"#efefef"}},"backend":{"divider-padding":"10"}},"class":"BuilderDividerElement"}},"properties":[],"class":"BuilderColumnElement"}},"properties":[],"class":"BuilderRowElement"},"builderrowelement_1394062641_5317b53112a36":{"content":{"buildercolumnelement_1394062641_5317b5311291a":{"content":{"builderfooterelement_1394062641_5317b5311226e":{"content":{"text":"[[GLOBAL^MARKETING^FOOTER^HTML]]"},"properties":{"frontend":{"inlineStyles":{"font-size":"11","background-color":"#ebebeb"}}},"class":"BuilderFooterElement"}},"properties":[],"class":"BuilderColumnElement"}},"properties":[],"class":"BuilderRowElement"}},"properties":{"frontend":{"inlineStyles":{"background-color":"#ffffff","color":"#545454"}}},"class":"BuilderCanvasElement"}}}', NULL),
(11, 294, NULL, '2 Columns with strong right', '2 Columns with strong right', 'en', '', '', NULL, 0, 3, '{"baseTemplateId":"","icon":"icon-template-3","dom":{"canvas1":{"content":{"builderheaderimagetextelement_1393965594_53163a1a0eb53":{"content":{"buildercolumnelement_1393965594_53163a1a0ef48":{"content":{"builderimageelement_1393965594_53163a1a0ee52":{"content":{"image":"<img src=\\"http:\\/\\/placehold.it\\/200x50\\">"},"properties":[],"class":"BuilderImageElement"}},"properties":[],"class":"BuilderColumnElement"},"buildercolumnelement_1393965594_53163a1a145cc":{"content":{"builderheadertextelement_1393965594_53163a1a14515":{"content":{"text":"Acme Inc. Newsletter"},"properties":{"frontend":{"inlineStyles":{"color":"#ffffff","font-weight":"bold","text-align":"right"}}},"class":"BuilderHeaderTextElement"}},"properties":[],"class":"BuilderColumnElement"}},"properties":{"backend":{"configuration":"1:2","header":"1"},"frontend":{"inlineStyles":{"background-color":"#282a76"}}},"class":"BuilderHeaderImageTextElement"},"builderrowelement_1394062546_5317b4d264a62":{"content":{"buildercolumnelement_1394062546_5317b4d26488b":{"content":{"buildertitleelement_1394062546_5317b4d263942":{"content":{"text":"Hello there William S..."},"properties":{"backend":{"headingLevel":"h1"},"frontend":{"inlineStyles":{"color":"#666666","font-size":"28","font-weight":"bold","line-height":"200"}}},"class":"BuilderTitleElement"}},"properties":[],"class":"BuilderColumnElement"}},"properties":[],"class":"BuilderRowElement"},"builderrowelement_1393965668_53163a6448794":{"content":{"buildercolumnelement_1393965668_53163a644866d":{"content":{"buildertextelement_1394061967_5317b28fc8088":{"content":{"text":"\\n <b>New Products<\\/b>\\n<ul>\\n    <li><a href=\\"#\\" target=\\"_blank\\">AcmeMaster 10,000<\\/a><\\/li>\\n    <li><a href=\\"#\\">ProAcme 5,000<\\/a><\\/li>\\n    <li><a href=\\"#\\">AcmeMaster++<\\/a><\\/li>\\n    <li><a href=\\"#\\" target=\\"_blank\\">The Acme Beginner pro<\\/a><\\/li>\\n<\\/ul>\\n"},"properties":{"frontend":{"inlineStyles":{"background-color":"#f6f6f7","color":"#323232","font-size":"16"}}},"class":"BuilderTextElement"},"buildertitleelement_1394062361_5317b419e1c51":{"content":{"text":"Follow Us!"},"properties":{"backend":{"headingLevel":"h3"},"frontend":{"inlineStyles":{"color":"#6c1d1d","font-weight":"bold","line-height":"200"}}},"class":"BuilderTitleElement"},"buildersocialelement_1394060039_5317ab07cf03d":{"content":[],"properties":{"backend":{"layout":"vertical","services":{"Twitter":{"enabled":"1","url":"http:\\/\\/www.twitter.com\\/"},"Facebook":{"enabled":"1","url":"http:\\/\\/www.facebook.com\\/"},"GooglePlus":{"enabled":"1","url":"http:\\/\\/gplus.com"}}}},"class":"BuilderSocialElement"}},"properties":[],"class":"BuilderColumnElement"},"buildercolumnelement_1394061698_5317b182c1f19":{"content":{"buildertextelement_1393965781_53163ad53b77c":{"content":{"text":"\\n<p>\\n    Orsino, the <i>Duke of Illyria<\\/i>, is consumed by his passion for the melancholy Countess Olivia. His ostentatious musings on the nature of love begin with what has become one of Shakespeare''s most famous lines: \\"If music be the food of love, play on.\\" It is apparent that Orsino''s love is hollow. He is a romantic dreamer, for whom the idea of being in love is most important. When Valentine gives him the terrible news that <b>Olivia<\\/b> plans to seclude herself for seven years to mourn her deceased brother, Orsino seems unfazed, and hopes Olivia may one day be as bewitched by love (the one self king) as he. Fittingly, the scene ends with Orsino off to lay in a bed of flowers, where he can be alone with his love-thoughts. Later in the play it will be up to Viola to teach Orsino the true meaning of love.\\n<\\/p>\\n"},"properties":[],"class":"BuilderTextElement"},"builderbuttonelement_1393965942_53163b76e666c":{"content":[],"properties":{"backend":{"text":"Contact Us Now","sizeClass":"medium-button","align":"left"},"frontend":{"href":"http:\\/\\/localhost\\/Zurmo\\/app\\/index.php","target":"_blank","inlineStyles":{"background-color":"#97c43d","border-color":"#7cb830"}}},"class":"BuilderButtonElement"},"builderexpanderelement_1394062193_5317b37137abc":{"content":[],"properties":{"frontend":{"height":"10"}},"class":"BuilderExpanderElement"}},"properties":[],"class":"BuilderColumnElement"}},"properties":{"backend":{"configuration":"1:2"}},"class":"BuilderRowElement"},"builderrowelement_1394062652_5317b53c906f9":{"content":{"buildercolumnelement_1394062652_5317b53c90615":{"content":{"builderdividerelement_1394062652_5317b53c901fc":{"content":[],"properties":{"frontend":{"inlineStyles":{"border-top-width":"1","border-top-style":"dotted","border-top-color":"#efefef"}},"backend":{"divider-padding":"10"}},"class":"BuilderDividerElement"}},"properties":[],"class":"BuilderColumnElement"}},"properties":[],"class":"BuilderRowElement"},"builderrowelement_1394062641_5317b53112a36":{"content":{"buildercolumnelement_1394062641_5317b5311291a":{"content":{"builderfooterelement_1394062641_5317b5311226e":{"content":{"text":"[[GLOBAL^MARKETING^FOOTER^HTML]]"},"properties":{"frontend":{"inlineStyles":{"font-size":"11","background-color":"#ebebeb"}}},"class":"BuilderFooterElement"}},"properties":[],"class":"BuilderColumnElement"}},"properties":[],"class":"BuilderRowElement"}},"properties":{"frontend":{"inlineStyles":{"background-color":"#ffffff","color":"#545454"}}},"class":"BuilderCanvasElement"}}}', NULL),
(12, 295, NULL, '3 Columns', '3 Columns', 'en', '', '', NULL, 0, 3, '{"baseTemplateId":"","icon":"icon-template-4","dom":{"canvas1":{"content":{"builderheaderimagetextelement_1393965594_53163a1a0eb53":{"content":{"buildercolumnelement_1393965594_53163a1a0ef48":{"content":{"builderimageelement_1393965594_53163a1a0ee52":{"content":{"image":"<img src=\\"http:\\/\\/placehold.it\\/200x50\\">"},"properties":[],"class":"BuilderImageElement"}},"properties":[],"class":"BuilderColumnElement"},"buildercolumnelement_1393965594_53163a1a145cc":{"content":{"builderheadertextelement_1393965594_53163a1a14515":{"content":{"text":"Acme Inc. Newsletter"},"properties":{"frontend":{"inlineStyles":{"color":"#ffffff","font-weight":"bold","text-align":"right"}}},"class":"BuilderHeaderTextElement"}},"properties":[],"class":"BuilderColumnElement"}},"properties":{"backend":{"configuration":"1:2"},"frontend":{"inlineStyles":{"background-color":"#282a76"}}},"class":"BuilderHeaderImageTextElement"},"builderrowelement_1394062546_5317b4d264a62":{"content":{"buildercolumnelement_1394062546_5317b4d26488b":{"content":{"buildertitleelement_1394062546_5317b4d263942":{"content":{"text":"Latest entries on our database"},"properties":{"backend":{"headingLevel":"h1"},"frontend":{"inlineStyles":{"color":"#666666","font-size":"28","font-weight":"bold","line-height":"200"}}},"class":"BuilderTitleElement"}},"properties":[],"class":"BuilderColumnElement"}},"properties":[],"class":"BuilderRowElement"},"builderrowelement_1393965668_53163a6448794":{"content":{"buildercolumnelement_1393965668_53163a644866d":{"content":{"builderimageelement_1394063801_5317b9b9eedc5":{"content":{"image":"<img src=\\"http:\\/\\/placehold.it\\/200x200\\"><\\/img>"},"properties":[],"class":"BuilderImageElement"},"buildertitleelement_1394063416_5317b838c6ce1":{"content":{"text":"Property at NYC"},"properties":{"backend":{"headingLevel":"h2"},"frontend":{"inlineStyles":{"color":"#323232","font-size":"18","font-family":"Georgia","font-weight":"bold"}}},"class":"BuilderTitleElement"},"builderplaintextelement_1394063772_5317b99cab31e":{"content":{"text":"Orsino, the Duke of Illyria, is consumed by his passion for the melancholy Countess Olivia. His ostentatious musings on the nature of love begin with what has become one of Shakespeare''s most famous lines: \\"If music be the food of love, play on.\\" It is apparent that Orsino''s love is hollow. He is a romantic dreamer, for whom the idea of being in love is most important. When Valentine gives him the terrible news that Olivia plans to seclude herself for seven years to mourn her deceased brother, Orsino seems unfazed, and hopes Olivia may one day be as bewitched by love (the one self king) as he. Fittingly, the scene ends with Orsino off to lay in a bed of flowers, where he can be alone with his love-thoughts. Later in the play it will be up to Viola to teach Orsino the true meaning of love."},"properties":[],"class":"BuilderPlainTextElement"}},"properties":[],"class":"BuilderColumnElement"},"buildercolumnelement_1394061698_5317b182c1f19":{"content":{"builderimageelement_1394063806_5317b9be406a3":{"content":{"image":"<img src=\\"http:\\/\\/placehold.it\\/200x200\\"><\\/img>"},"properties":[],"class":"BuilderImageElement"},"buildertitleelement_1394063420_5317b83cb81a3":{"content":{"text":"Chalet in Bs. As."},"properties":{"backend":{"headingLevel":"h3"},"frontend":{"inlineStyles":{"color":"#323232","font-size":"18","font-family":"Georgia","font-weight":"bold"}}},"class":"BuilderTitleElement"},"builderplaintextelement_1394063737_5317b979ce2a3":{"content":{"text":"Orsino, the Duke of Illyria, is consumed by his passion for the melancholy Countess Olivia. His ostentatious musings on the nature of love begin with what has become one of Shakespeare''s most famous lines: \\"If music be the food of love, play on.\\" It is apparent that Orsino''s love is hollow. He is a romantic dreamer, for whom the idea of being in love is most important. When Valentine gives him the terrible news that Olivia plans to seclude herself for seven years to mourn her deceased brother, Orsino seems unfazed, and hopes Olivia may one day be as bewitched by love (the one self king) as he. Fittingly, the scene ends with Orsino off to lay in a bed of flowers, where he can be alone with his love-thoughts. Later in the play it will be up to Viola to teach Orsino the true meaning of love."},"properties":[],"class":"BuilderPlainTextElement"}},"properties":[],"class":"BuilderColumnElement"},"buildercolumnelement_1394063404_5317b82c72b5c":{"content":{"builderimageelement_1394063809_5317b9c1da156":{"content":{"image":"<img src=\\"http:\\/\\/placehold.it\\/200x200\\"><\\/img>"},"properties":[],"class":"BuilderImageElement"},"buildertitleelement_1394063425_5317b8410f24b":{"content":{"text":"Tiny Island"},"properties":{"backend":{"headingLevel":"h3"},"frontend":{"inlineStyles":{"color":"#323232","font-size":"18","font-family":"Georgia","font-weight":"bold"}}},"class":"BuilderTitleElement"},"builderplaintextelement_1394063741_5317b97d68d8d":{"content":{"text":"Orsino, the Duke of Illyria, is consumed by his passion for the melancholy Countess Olivia. His ostentatious musings on the nature of love begin with what has become one of Shakespeare''s most famous lines: \\"If music be the food of love, play on.\\" It is apparent that Orsino''s love is hollow. He is a romantic dreamer, for whom the idea of being in love is most important. When Valentine gives him the terrible news that Olivia plans to seclude herself for seven years to mourn her deceased brother, Orsino seems unfazed, and hopes Olivia may one day be as bewitched by love (the one self king) as he. Fittingly, the scene ends with Orsino off to lay in a bed of flowers, where he can be alone with his love-thoughts. Later in the play it will be up to Viola to teach Orsino the true meaning of love."},"properties":[],"class":"BuilderPlainTextElement"}},"properties":[],"class":"BuilderColumnElement"}},"properties":{"backend":{"configuration":"3"}},"class":"BuilderRowElement"},"builderrowelement_1394062652_5317b53c906f9":{"content":{"buildercolumnelement_1394062652_5317b53c90615":{"content":{"builderbuttonelement_1394063832_5317b9d8a797c":{"content":[],"properties":{"backend":{"text":"Click for more details","sizeClass":"large-button","width":"100%","align":"center"},"frontend":{"href":"http:\\/\\/google.com","target":"_blank","inlineStyles":{"background-color":"#8224e3","color":"#ffffff","font-weight":"bold","text-align":"center","border-color":"#8224e3","border-width":"1","border-style":"solid"}}},"class":"BuilderButtonElement"},"builderdividerelement_1394062652_5317b53c901fc":{"content":[],"properties":{"frontend":{"inlineStyles":{"border-top-width":"1","border-top-style":"dotted","border-top-color":"#efefef"}},"backend":{"divider-padding":"10"}},"class":"BuilderDividerElement"}},"properties":[],"class":"BuilderColumnElement"}},"properties":[],"class":"BuilderRowElement"},"builderrowelement_1394062641_5317b53112a36":{"content":{"buildercolumnelement_1394062641_5317b5311291a":{"content":{"builderfooterelement_1394062641_5317b5311226e":{"content":{"text":"[[GLOBAL^MARKETING^FOOTER^HTML]]"},"properties":{"frontend":{"inlineStyles":{"font-size":"11","background-color":"#ebebeb"}}},"class":"BuilderFooterElement"}},"properties":[],"class":"BuilderColumnElement"}},"properties":[],"class":"BuilderRowElement"}},"properties":{"frontend":{"inlineStyles":{"background-color":"#ffffff","color":"#545454"}}},"class":"BuilderCanvasElement"}}}', NULL),
(13, 296, NULL, '3 Columns with Hero', '3 Columns with Hero', 'en', '', '', NULL, 0, 3, '{"baseTemplateId":"","icon":"icon-template-1","dom":{"canvas1":{"content":{"builderheaderimagetextelement_1393965594_53163a1a0eb53":{"content":{"buildercolumnelement_1393965594_53163a1a0ef48":{"content":{"builderimageelement_1393965594_53163a1a0ee52":{"content":{"image":"<img src=\\"http:\\/\\/placehold.it\\/200x50\\">"},"properties":[],"class":"BuilderImageElement"}},"properties":[],"class":"BuilderColumnElement"},"buildercolumnelement_1393965594_53163a1a145cc":{"content":{"builderheadertextelement_1393965594_53163a1a14515":{"content":{"text":"Acme Real Estate"},"properties":{"frontend":{"inlineStyles":{"color":"#ffffff","font-weight":"bold","text-align":"right"}}},"class":"BuilderHeaderTextElement"}},"properties":[],"class":"BuilderColumnElement"}},"properties":{"backend":{"configuration":"1:2","header":"1","border-negation":{"border-top":"none","border-right":"none","border-bottom":"none","border-left":"none"}},"frontend":{"inlineStyles":{"background-color":"#282a76"}}},"class":"BuilderHeaderImageTextElement"},"builderrowelement_1394062546_5317b4d264a62":{"content":{"buildercolumnelement_1394062546_5317b4d26488b":{"content":{"buildertitleelement_1394062546_5317b4d263942":{"content":{"text":"New on our Downtown NYC locations"},"properties":{"backend":{"headingLevel":"h1"},"frontend":{"inlineStyles":{"color":"#323232","font-size":"28","font-weight":"bold","line-height":"100"}}},"class":"BuilderTitleElement"}},"properties":[],"class":"BuilderColumnElement"}},"properties":[],"class":"BuilderRowElement"},"builderrowelement_1394122137_53189d999cade":{"content":{"buildercolumnelement_1394122137_53189d999c769":{"content":{"builderimageelement_1394122137_53189d999b21b":{"content":{"image":"<img src=\\"http:\\/\\/maps.googleapis.com\\/maps\\/api\\/staticmap?center=Brooklyn+Bridge,New+York,NY&amp;zoom=13&amp;size=580x180&amp;maptype=roadmap &amp;markers=color:blue%7Clabel:S%7C40.702147,-74.015794&amp;markers=color:green%7Clabel:G%7C40.711614,-74.012318 &amp;markers=color:red%7Clabel:C%7C40.718217,-73.998284&amp;sensor=false\\">"},"properties":[],"class":"BuilderImageElement"}},"properties":[],"class":"BuilderColumnElement"}},"properties":[],"class":"BuilderRowElement"},"builderrowelement_1393965668_53163a6448794":{"content":{"buildercolumnelement_1393965668_53163a644866d":{"content":{"builderimageelement_1394063801_5317b9b9eedc5":{"content":{"image":"<img src=\\"http:\\/\\/placehold.it\\/200x200\\"><\\/img>"},"properties":[],"class":"BuilderImageElement"},"buildertitleelement_1394063416_5317b838c6ce1":{"content":{"text":"Property at NYC"},"properties":{"backend":{"headingLevel":"h2"},"frontend":{"inlineStyles":{"color":"#323232","font-size":"18","font-family":"Georgia","font-weight":"bold"}}},"class":"BuilderTitleElement"},"builderplaintextelement_1394063772_5317b99cab31e":{"content":{"text":"With its welcoming fireplace, wood-paneled ceiling, limestone floor, and luminous\\nview into a stunning courtyard, The Sterling Mason lobby imparts the intimate warmth of home."},"properties":{"backend":{"border-negation":{"border-top":"none","border-right":"none","border-bottom":"none","border-left":"none"}}},"class":"BuilderPlainTextElement"}},"properties":[],"class":"BuilderColumnElement"},"buildercolumnelement_1394061698_5317b182c1f19":{"content":{"builderimageelement_1394063806_5317b9be406a3":{"content":{"image":"<img src=\\"http:\\/\\/placehold.it\\/200x200\\"><\\/img>"},"properties":[],"class":"BuilderImageElement"},"buildertitleelement_1394063420_5317b83cb81a3":{"content":{"text":"Chalet in Bs. As."},"properties":{"backend":{"headingLevel":"h3"},"frontend":{"inlineStyles":{"color":"#323232","font-size":"18","font-family":"Georgia","font-weight":"bold"}}},"class":"BuilderTitleElement"},"builderplaintextelement_1394063737_5317b979ce2a3":{"content":{"text":"With its welcoming fireplace, wood-paneled ceiling, limestone floor, and luminous\\nview into a stunning courtyard, The Sterling Mason lobby imparts the intimate warmth of home."},"properties":{"backend":{"border-negation":{"border-top":"none","border-right":"none","border-bottom":"none","border-left":"none"}}},"class":"BuilderPlainTextElement"}},"properties":[],"class":"BuilderColumnElement"},"buildercolumnelement_1394063404_5317b82c72b5c":{"content":{"builderimageelement_1394063809_5317b9c1da156":{"content":{"image":"<img src=\\"http:\\/\\/placehold.it\\/200x200\\"><\\/img>"},"properties":[],"class":"BuilderImageElement"},"buildertitleelement_1394063425_5317b8410f24b":{"content":{"text":"Luminus Loft"},"properties":{"backend":{"headingLevel":"h3"},"frontend":{"inlineStyles":{"color":"#323232","font-size":"18","font-family":"Georgia","font-weight":"bold"}}},"class":"BuilderTitleElement"},"builderplaintextelement_1394063741_5317b97d68d8d":{"content":{"text":"With its welcoming fireplace, wood-paneled ceiling, limestone floor, and luminous\\nview into a stunning courtyard, The Sterling Mason lobby imparts the intimate warmth of home."},"properties":{"backend":{"border-negation":{"border-top":"none","border-right":"none","border-bottom":"none","border-left":"none"}}},"class":"BuilderPlainTextElement"}},"properties":[],"class":"BuilderColumnElement"}},"properties":{"backend":{"configuration":"3"}},"class":"BuilderRowElement"},"builderrowelement_1394062641_5317b53112a36":{"content":{"buildercolumnelement_1394062641_5317b5311291a":{"content":{"buildersocialelement_1394121396_53189ab49a77c":{"content":[],"properties":{"backend":{"layout":"horizontal","services":{"Facebook":{"enabled":"1","url":"http:\\/\\/www.facebook.com\\/"},"GooglePlus":{"enabled":"1","url":"http:\\/\\/gplus.con"},"Instagram":{"enabled":"1","url":"http:\\/\\/www.instagram.com\\/"}}}},"class":"BuilderSocialElement"},"builderfooterelement_1394062641_5317b5311226e":{"content":{"text":"[[GLOBAL^MARKETING^FOOTER^HTML]]"},"properties":{"frontend":{"inlineStyles":{"font-size":"11","background-color":"#ebebeb"}}},"class":"BuilderFooterElement"}},"properties":[],"class":"BuilderColumnElement"}},"properties":[],"class":"BuilderRowElement"}},"properties":{"frontend":{"inlineStyles":{"background-color":"#fefefe","color":"#545454","border-color":"#284b7d","border-width":"10","border-style":"solid"}},"backend":{"border-negation":{"border-top":"none","border-right":"none","border-bottom":"none","border-left":"none"}}},"class":"BuilderCanvasElement"}}}', NULL);

-- --------------------------------------------------------

--
-- Table structure for table `emailtemplate_read`
--

CREATE TABLE IF NOT EXISTS `emailtemplate_read` (
  `securableitem_id` int(11) unsigned NOT NULL,
  `munge_id` varchar(12) COLLATE utf8_unicode_ci NOT NULL,
  `count` int(8) unsigned NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

--
-- Dumping data for table `emailtemplate_read`
--

INSERT INTO `emailtemplate_read` (`securableitem_id`, `munge_id`, `count`) VALUES
(93, 'G3', 1),
(94, 'G3', 1),
(94, 'R2', 1),
(95, 'G3', 1),
(95, 'R2', 1),
(96, 'G3', 1),
(96, 'R2', 1),
(97, 'G3', 1),
(97, 'R2', 1),
(98, 'G3', 1),
(292, 'G3', 1),
(293, 'G3', 1),
(294, 'G3', 1),
(295, 'G3', 1),
(296, 'G3', 1),
(297, 'G3', 1);

-- --------------------------------------------------------

--
-- Table structure for table `exportfilemodel`
--

CREATE TABLE IF NOT EXISTS `exportfilemodel` (
`id` int(11) unsigned NOT NULL,
  `filemodel_id` int(11) unsigned DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `exportitem`
--

CREATE TABLE IF NOT EXISTS `exportitem` (
`id` int(11) unsigned NOT NULL,
  `ownedsecurableitem_id` int(11) unsigned DEFAULT NULL,
  `exportfilemodel_id` int(11) unsigned DEFAULT NULL,
  `iscompleted` tinyint(1) unsigned DEFAULT NULL,
  `exportfiletype` text COLLATE utf8_unicode_ci,
  `exportfilename` text COLLATE utf8_unicode_ci,
  `modelclassname` text COLLATE utf8_unicode_ci,
  `serializeddata` longtext COLLATE utf8_unicode_ci,
  `processoffset` int(11) DEFAULT NULL,
  `isjobrunning` tinyint(1) unsigned DEFAULT NULL,
  `cancelexport` tinyint(1) unsigned DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `exportitem_read`
--

CREATE TABLE IF NOT EXISTS `exportitem_read` (
`id` int(11) unsigned NOT NULL,
  `securableitem_id` int(11) unsigned NOT NULL,
  `munge_id` varchar(12) COLLATE utf8_unicode_ci NOT NULL,
  `count` int(8) unsigned NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `filecontent`
--

CREATE TABLE IF NOT EXISTS `filecontent` (
`id` int(11) unsigned NOT NULL,
  `content` longblob
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

--
-- Dumping data for table `filecontent`
--

INSERT INTO `filecontent` (`id`, `content`) VALUES
(1, 0x89504e470d0a1a0a0000000d494844520000003000000020080600000054d4fb1c000006c74944415458c3ed987b8c54571dc73fbf7befdc991d86615d97dd952e3bb77b81222188060a31b6ddb47f882d6daa88243e4af0918a181b3594d0a451939ac66cea23a46de8239590a0689fb140495f4622a611c1aed81ad8596696b2b04f06587667eedc7b7efe3137a4ea62298b599a78929bfbc79c737ee73bdfc7f9e5c2077cc895dc6cf8d6c72c1c99af497bb9242d70ed345563f47c758073610fe5e8af8dfb3698ab12c0d08ac71648d2ba5ba63927e543c93a92ce394927ae4509742c7075b8ec9afef1e38c87cf36fe61c3e1ab0ac0d02d5b575067adb25aea0e499dd32c0d7567c475428270441c7b2e169629951d3370be5507c7cb7a3adcc979f34a63d777265ddb99ec0683d73fbc4843b35e92ce2e42d3a28614672aaf974f0e6e18ea3f5d1a3c36f0470d34e3aa5d3fa331bb6f963fb3411cb9df2825e0c09432d0dffc534bb2f6cb92b11fa2de592f96ec236d1fac0c8cfea0383850a896ab3d096367ddd01e4e454e495470237b69fd9c197b28ebdd8c9a4fcf3cfedd60ca18d071d341a0bd7a3a5a23a7aadb149611995b869d738f06549feee8eb0cde68daecda2a9f4269adab3a1f7323676ff5edf19b9c0f27baa9eaadc0f39339833529fa2aba46c7cc5e46a3f93a127a7a3adc63ce9ad4a2be1feee8e8eb0c00960d3c187c7cf881d79cc802651736adb65873cc70f43b3d63be3259095d3680fe6427c0729400a54bd1b991314d9146bb269aef1afb25b1659135cdf1256bbf6a65ec59c0bcfe64a735550cb8802382abd0a7e08612b58662ba279a6c5bf680934ecc7666b9465a12ef48b3339bb4354a42eaa7ca0326fe0342c031a261241a5c2c1612d31348c64e594dae4131849a924843ce1b97d1a9612004fa6a6f9da33066447b228c37210319a7d5b926d52f192725d39d06b28913568bdb208d89d29448a8b9b211e0758526443c813f258ced02d74f0860feb43b6466723fae35aa09eb0649480f196764e6a16f97a7f222db21b02d12b31da11d658685bc999ff6c0176c95dd828c3a09c7715b539f24d2655235a15aec43b94783680e21cf4ce94ddc5cd9d8d39fececb68c64cea52ad3cb76782e1d24ea43d15484f95122b28725e22328373354fd86bab2c68882235bb462ee1191dba6bc17ea4f76ce021e57f4c8e9baf13787eac65a23316753a133d67c3ef3d17432b590943c88c52a63e921d2d67551c5a4ad84bc3aebc8f79e9f720000a7dcce0522ac47a90706e042ae1455d43168a341c7d4256b224d882d27c596476697365d76cd3b6e5b6965321973c5dae9fe6467abc2e705ae8ba539a6e0821e33a8ab600c66a6c20b6d95cdbf9f4cadafae5d9b2e95ce7ccb75ddd21501e0e7bc1410ec3fb501a01d6521d084e0a810801a85b70c7ae09af2a610c06ff35c04f2c542f03e6b39beef6793a9d45dc9a41b3a9771d8858007bc982f16f0dbbc16e010caf79b2b1b7700ddf1f35ee2dd1a5f865ff3739e05dc0974e58b85f75a7b5f7777f74d4b962efd8c6589b99c14ba1365adc26ec0208c004f201c7c9ffb64fead2dd90a6cbe04f0d34424fb9b679e0e009c18fdd781d52801c29328cf22dc086c005a8011e061e01500159a049ef2dbbc91b8681390f5db3c143e27c23a9414f01cc24bc026603eca18b01d61c77fb4e6b54459e7b77937286c17e135e09bc0678100787ca2d6db02ee02b6a8d2ad4209d8191f7eb9c24a607fdc36ec4259fc2fd12580e2025f04da545829c24ee02c4217c2ecb87813ca7e8421601bb0e41272f1cbc02f50ba81b3c06f275ae7c40877f7f416d6fb39cf8a0d783bc2a0c0d97cb1b0d9cf790ef077845540056500615dbe58307e9b97bd505b598db01ff852ec0f54b0043a156e14c8201855e6c9c4f1f154be587822f6daaf808308dbe37376002b266220134b847cb150d3b4909da0712b5dd0ed45b24b6bbf0fe58b0500f2bd05a426cfbd225c0b8c2a18914beac1d2403bf013e0c7b137462662e0084a879ff35a802cb00878213696e5e7bc6cbcd102e0c9184416686a6ff352efde54e0cf281bfd9cb70828a034282c13f847ec15576aba0628a3b4c4116ca426b5d97eceab8f6b77030b81b5f1e5d81877bff7c77ecbe47b0ba396c24308699463c0df8077805fc6459a8013c01b4017ca0ee0c518781e388ad0fe2e173e82d085f217e004c21ea999af5d95e3c051a03e8ecf97156e061e0502945f03f701c7812dc0cf62e6df8ecf7014a503d80bb423ecf2735e4d0c7ece4bc70609510ee47b0b819ff3ee05362aac1618030ee68b85309edf10333502bc057828a7f2bd85d138d516030dc0e17cb170cacf79599425d4a4d317b31e222c4609f3bd85c37ece235e571faf1bf2db3c17f8442ce9daba1a53f362151cf86f17d6bd7ece3b79b57f1bbdb899141353f8010520fc1c98cbffc7ff76fc13f014b9d6307376c40000000049454e44ae426082),
(2, 0x89504e470d0a1a0a0000000d494844520000002d0000001e0806000000b8f49799000006654944415458c3ed986b8c55e515869ff7dbfb5c1886e1300c2390e19ccd6ca0931aa74d6a7ae19f205a635bb504134dda9a98368a6db4a6d434861a6a0c3f08556a0c31a44dd3a435b589548df7601b08944bd180586a99333d33e136cc157a18ce9cd9e75bfd310784d29b82834dbafeed9d6fadf75d2b6bbddfca07ff83a6cb1568f04b9b72a4740399a04153c3b93837dd4693411b19fb13a793b75a7ebff2e8c786f4c0b2a71d697797326ebe6665c7950d2b6e5a6606a9e0988d25f8a133f3ecc499061b19dbc619ff5ccb1fbe5dbd544c774984176f74186b95724eb3b2adae2973d8cd6c08a9f97d36369e4b6473989139e66665875c2e751ba1bed7dfb9217da9a4c34b71b64aed2e021b665ab894d1e425ef5c73edd070a6af7fe81bfda5fefd41cd39676a485b10ce9c9d7b25d7dc78b3a195c01357a43dfa66ae6fd254f7220dc16635050922b672d2736c7ce40b43e5f2af53de95d3b5209fa905ad53925439550be6a7c2706fe6aaccbd76dadfd17ae4c1dec9aff4a8bfdd2af63cc3b5157684df48bc96c8df38d878ea8e2547d77b80fd337f88f3ba5d5e3ef02e09c6f4357f22d984e79bc0ea49ede9e39975e0b989c41fa76a076cccc77ecc77a8c2c62547260803740efe8854e29e13b4bbb49bef32c16bd4086dccae9ff4411480118142337b17609cda9c71d5bafff1ec27ca8f24a954382d9c993ea2d6f0b85ac26b14e2fba6ac6b98dcf63003c9032152d5e3a9c92726927f763c353d9d0ee6654e09d224b4f89a8d58c5377286d149236d0861655055503091d49c9d06d2c0453a1ccc4aa73523959371dc6a0cc993573919e5c424b6c7ecea2a0ced340c83cf1a760af88bc93a2fd2f21b9e6e0ae6642b6482826583d94c09de5173985553589efccbc5ec19d02de6ac24e9dd94058b048bbba73ed6764e16db7e9c46ac56a8dfc9db0889bf916aad82d99b2ddb575e81cb45da8f598867fb68b6fae5447e5b3a09d289fcbd5d531f3d99f1e128700b27932d365a5b6a010709e57ca5b6424ef75db1dda32fb36e01b0d1635bfa1aff563999a938992ab94a36dd526dbc2e6c4e6df7555f65aa1bb0909b6a89dfe5528eb9ef7df727577461ea4bafbb167137460370bc3e88674c76d8b0368f0df880ab0d3b84d32c855a336fe421ff61b096df7a5b78d956d3beccba08f8aa992d042199373462d8a0c7ae32aceab13d182fe4ab3ff850182b962f77c9f8f8036198aa5e12e9b81081b108d1b5e3d84a8f1419b4633449e64c72867519ec9f5bf9be0788f3518b41babbb7f45fefd7edf9a83108dcec6b3a3baf0d02f7c1c423ce471d713eda1017a2b0febd202e44b5381f2df9000436b4e7a3e7eb4937c5f9e8c9b810cdfd0fc5b9352e44c317a8479c8f005a10e5624fa972ae8a90c3081103c59e128836e05bc04371214a30ba31962276d40921d1021371ea319a30d2c040b1b754171ecef67483897b804d71213a0a50ec29d15e88d29af01b2af6962eea7f1717a236602fa21f63302e440fd4c1f600c3403fc6db71216ab7099f2cc630503491035ec2e8880b5187609f19fd407f9c8f161b6cae9fed47ec6bcf476d1260172a816017c6698cd6381fdd29e803fa81837121ea30bbd0c7010f3391f942c4fdc05a602e4633b0da26fe0f99f158dda76a6219b04206886c3dce7a8313120b819b110730d622ae467c0ac822be6ee78ffffb44ee36711d6214b11e781c5868a284f18874a164388c4f62bc5aec297599f1ac4d045a540f3ad0dd5bea0236039df52279c1ee624fe92d34b13bd577a84ec12f8b3da5ae624f692b5096b8de8c5780373022c134d985825bf73fd0dd53da8dd164468b19379af1a48cc8a0037b1fe76c4f970d5aea4172821063c4ce4fce98833865e0eb55751700d7133488cfa314193c2ab10c6327e2c53ab0979df3f77510578f550112c13366ecaef7ff28b0e0ec9c157b4a28ce4777223619bc20e8a893fc1c70101841fcd9e02bc02a192f23de33e34d4d00dd8738047c06e3d388a78097812cf053e0298c6e4497c117053f37e388c41ae03b663c0b141187050366ac011e063e8f781d68c4d822b1c3602fc613ddbda555c18c5cee1d19fb8156893d180f167b4ba79aa7e7ee077a113d82c705bf428c606c43344b1c42ec018e99b15d623bb01ba3d5c411c1eb063f031a2502c156e0b782371035e074776fe9ede6e9b95725a6032704bb247e21312c982e3826f8236227c65f054dcdb9dcd67fada785a81817a27b3e8e2f4cee237f7afa08ecdfada6cb8021fe6f97c7fe0e76dac34d447b828b0000000049454e44ae426082);

-- --------------------------------------------------------

--
-- Table structure for table `filemodel`
--

CREATE TABLE IF NOT EXISTS `filemodel` (
`id` int(11) unsigned NOT NULL,
  `item_id` int(11) unsigned DEFAULT NULL,
  `filecontent_id` int(11) unsigned DEFAULT NULL,
  `name` varchar(100) COLLATE utf8_unicode_ci DEFAULT NULL,
  `type` varchar(128) COLLATE utf8_unicode_ci DEFAULT NULL,
  `size` int(11) DEFAULT NULL,
  `emailmessage_id` int(11) unsigned DEFAULT NULL,
  `autoresponder_id` int(11) unsigned DEFAULT NULL,
  `campaign_id` int(11) unsigned DEFAULT NULL,
  `relatedmodel_id` int(11) unsigned DEFAULT NULL,
  `relatedmodel_type` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `emailtemplate_id` int(11) unsigned DEFAULT NULL
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

--
-- Dumping data for table `filemodel`
--

INSERT INTO `filemodel` (`id`, `item_id`, `filecontent_id`, `name`, `type`, `size`, `emailmessage_id`, `autoresponder_id`, `campaign_id`, `relatedmodel_id`, `relatedmodel_type`, `emailtemplate_id`) VALUES
(1, 636, 1, 'logo1.png', 'image/png', 1792, NULL, NULL, NULL, NULL, NULL, NULL),
(2, 637, 2, 'logo1.png', 'image/png', 1694, NULL, NULL, NULL, NULL, NULL, NULL);

-- --------------------------------------------------------

--
-- Table structure for table `gamebadge`
--

CREATE TABLE IF NOT EXISTS `gamebadge` (
`id` int(11) unsigned NOT NULL,
  `item_id` int(11) unsigned DEFAULT NULL,
  `person_item_id` int(11) unsigned DEFAULT NULL,
  `type` varchar(64) COLLATE utf8_unicode_ci DEFAULT NULL,
  `grade` int(11) DEFAULT NULL
) ENGINE=InnoDB AUTO_INCREMENT=33 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

--
-- Dumping data for table `gamebadge`
--

INSERT INTO `gamebadge` (`id`, `item_id`, `person_item_id`, `type`, `grade`) VALUES
(2, 218, 64, 'LoginUser', 2),
(3, 219, 64, 'CreateAccount', 3),
(4, 226, 70, 'LoginUser', 2),
(5, 227, 70, 'CreateAccount', 3),
(6, 234, 65, 'LoginUser', 2),
(7, 235, 65, 'CreateAccount', 3),
(8, 242, 66, 'LoginUser', 2),
(9, 243, 66, 'CreateAccount', 3),
(10, 250, 69, 'LoginUser', 2),
(11, 251, 69, 'CreateAccount', 3),
(12, 258, 68, 'LoginUser', 2),
(13, 259, 68, 'CreateAccount', 3),
(14, 266, 67, 'LoginUser', 2),
(15, 267, 67, 'CreateAccount', 3),
(16, 274, 71, 'LoginUser', 2),
(17, 275, 71, 'CreateAccount', 3),
(18, 282, 1, 'LoginUser', 4),
(19, 283, 1, 'CreateAccount', 3),
(20, 559, 1, 'NightOwl', 2),
(21, 561, 1, 'EarlyBird', 2),
(22, 566, 1, 'CreateContract', 3),
(23, 581, 1, 'CreateContact', 1),
(24, 586, 1, 'CreateNote', 1),
(25, 590, 1, 'CreateMeeting', 1),
(26, 595, 1, 'CreateTask', 1),
(27, 613, 1, 'CreateOpportunity', 2),
(28, 699, 1, 'SearchAccounts', 1),
(29, 824, 1, 'MassEditContracts', 1),
(30, 826, 1, 'SearchContracts', 1),
(31, 828, 1, 'SearchOpportunities', 1),
(32, 830, 1, 'MassEditOpportunities', 1);

-- --------------------------------------------------------

--
-- Table structure for table `gamecoin`
--

CREATE TABLE IF NOT EXISTS `gamecoin` (
`id` int(11) unsigned NOT NULL,
  `value` int(11) DEFAULT NULL,
  `item_id` int(11) unsigned DEFAULT NULL,
  `person_item_id` int(11) unsigned DEFAULT NULL
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

--
-- Dumping data for table `gamecoin`
--

INSERT INTO `gamecoin` (`id`, `value`, `item_id`, `person_item_id`) VALUES
(1, 15, 569, 1);

-- --------------------------------------------------------

--
-- Table structure for table `gamecollection`
--

CREATE TABLE IF NOT EXISTS `gamecollection` (
`id` int(11) unsigned NOT NULL,
  `type` varchar(64) COLLATE utf8_unicode_ci DEFAULT NULL,
  `serializeddata` text COLLATE utf8_unicode_ci,
  `item_id` int(11) unsigned DEFAULT NULL,
  `person_item_id` int(11) unsigned DEFAULT NULL
) ENGINE=InnoDB AUTO_INCREMENT=32 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

--
-- Dumping data for table `gamecollection`
--

INSERT INTO `gamecollection` (`id`, `type`, `serializeddata`, `item_id`, `person_item_id`) VALUES
(1, 'Fitness', 'a:2:{s:14:"RedemptionItem";i:0;s:5:"Items";a:5:{s:5:"Apple";i:1;s:14:"StationaryBike";i:0;s:5:"Scale";i:0;s:7:"Weights";i:0;s:7:"Muscles";i:0;}}', 760, 1),
(2, 'Airport', 'a:2:{s:14:"RedemptionItem";i:0;s:5:"Items";a:5:{s:4:"Gate";i:0;s:8:"Passport";i:0;s:5:"Pilot";i:0;s:7:"Luggage";i:0;s:8:"TowTruck";i:0;}}', 832, 1),
(3, 'Basketball', 'a:2:{s:14:"RedemptionItem";i:0;s:5:"Items";a:5:{s:9:"Backboard";i:0;s:6:"Player";i:0;s:10:"ScoreBoard";i:0;s:7:"Uniform";i:0;s:6:"Trophy";i:0;}}', 833, 1),
(4, 'Bicycle', 'a:2:{s:14:"RedemptionItem";i:0;s:5:"Items";a:5:{s:6:"Helmet";i:0;s:11:"RidingShirt";i:0;s:12:"RidingShorts";i:0;s:11:"Speedometer";i:0;s:7:"Bottles";i:0;}}', 834, 1),
(5, 'Breakfast', 'a:2:{s:14:"RedemptionItem";i:0;s:5:"Items";a:5:{s:5:"Bread";i:0;s:3:"Jam";i:0;s:4:"Eggs";i:0;s:11:"OrangeJuice";i:0;s:7:"Toaster";i:0;}}', 835, 1),
(6, 'Business', 'a:2:{s:14:"RedemptionItem";i:0;s:5:"Items";a:5:{s:5:"Chart";i:0;s:7:"Desktop";i:0;s:3:"Fax";i:0;s:9:"LightBulb";i:0;s:4:"News";i:0;}}', 836, 1),
(7, 'Camping2', 'a:2:{s:14:"RedemptionItem";i:0;s:5:"Items";a:5:{s:10:"Binoculars";i:0;s:6:"Shovel";i:0;s:7:"Compass";i:0;s:5:"Signs";i:0;s:3:"SUV";i:0;}}', 837, 1),
(8, 'Camping', 'a:2:{s:14:"RedemptionItem";i:0;s:5:"Items";a:5:{s:9:"ArmyKnife";i:0;s:10:"FlashLight";i:0;s:3:"Gas";i:0;s:8:"GasLight";i:0;s:7:"Lighter";i:0;}}', 838, 1),
(9, 'CarParts', 'a:2:{s:14:"RedemptionItem";i:0;s:5:"Items";a:5:{s:6:"Breaks";i:0;s:4:"Seat";i:0;s:5:"Gauge";i:0;s:4:"Gear";i:0;s:10:"Suspension";i:0;}}', 839, 1),
(10, 'ChildrenPlayEquipment', 'a:2:{s:14:"RedemptionItem";i:0;s:5:"Items";a:5:{s:4:"Ball";i:0;s:7:"Bicycle";i:0;s:6:"Bucket";i:0;s:5:"Swing";i:0;s:5:"Slide";i:0;}}', 840, 1),
(11, 'Circus', 'a:2:{s:14:"RedemptionItem";i:0;s:5:"Items";a:5:{s:5:"Magic";i:0;s:6:"Cannon";i:0;s:5:"Clown";i:0;s:8:"Elephant";i:0;s:8:"Unicycle";i:0;}}', 841, 1),
(12, 'Cooking', 'a:2:{s:14:"RedemptionItem";i:0;s:5:"Items";a:5:{s:7:"Cookies";i:0;s:5:"Glove";i:0;s:4:"Oven";i:0;s:6:"Server";i:0;s:5:"Grill";i:0;}}', 842, 1),
(13, 'Drinks', 'a:2:{s:14:"RedemptionItem";i:0;s:5:"Items";a:5:{s:4:"Beer";i:0;s:3:"Ice";i:0;s:9:"Champagne";i:0;s:7:"Martini";i:0;s:5:"Water";i:0;}}', 843, 1),
(14, 'Education', 'a:2:{s:14:"RedemptionItem";i:0;s:5:"Items";a:5:{s:9:"Textbooks";i:0;s:10:"Blackboard";i:0;s:4:"Exam";i:0;s:5:"Globe";i:0;s:5:"Ruler";i:0;}}', 844, 1),
(15, 'Finance', 'a:2:{s:14:"RedemptionItem";i:0;s:5:"Items";a:5:{s:4:"Bank";i:0;s:6:"Abacus";i:0;s:5:"Check";i:0;s:4:"Safe";i:0;s:3:"ATM";i:0;}}', 845, 1),
(16, 'Food', 'a:2:{s:14:"RedemptionItem";i:0;s:5:"Items";a:5:{s:6:"Cheese";i:0;s:4:"Fish";i:0;s:5:"Fruit";i:0;s:6:"Spices";i:0;s:10:"Vegetables";i:0;}}', 846, 1),
(17, 'Golf', 'a:2:{s:14:"RedemptionItem";i:0;s:5:"Items";a:5:{s:8:"GolfBall";i:0;s:7:"GolfBag";i:0;s:8:"GolfCart";i:0;s:8:"GolfShoe";i:0;s:7:"GolfBat";i:0;}}', 847, 1),
(18, 'Health', 'a:2:{s:14:"RedemptionItem";i:0;s:5:"Items";a:5:{s:11:"FirstAidKit";i:0;s:5:"Heart";i:0;s:5:"Nurse";i:0;s:7:"Vaccine";i:0;s:8:"Vitamins";i:0;}}', 848, 1),
(19, 'Home', 'a:2:{s:14:"RedemptionItem";i:0;s:5:"Items";a:5:{s:3:"Bed";i:0;s:9:"Bookshelf";i:0;s:7:"Flowers";i:0;s:6:"Lights";i:0;s:4:"Sofa";i:0;}}', 849, 1),
(20, 'Hotel', 'a:2:{s:14:"RedemptionItem";i:0;s:5:"Items";a:5:{s:9:"CoffeeMug";i:0;s:12:"DoNotDisturb";i:0;s:11:"RoomKeyCard";i:0;s:11:"RoomService";i:0;s:6:"Towels";i:0;}}', 850, 1),
(21, 'Office', 'a:2:{s:14:"RedemptionItem";i:0;s:5:"Items";a:5:{s:8:"Calendar";i:0;s:15:"CorrectionFluid";i:0;s:9:"DeskPlant";i:0;s:8:"Shredder";i:0;s:11:"CopyMachine";i:0;}}', 851, 1),
(22, 'Racing', 'a:2:{s:14:"RedemptionItem";i:0;s:5:"Items";a:5:{s:9:"Champagne";i:0;s:6:"Helmet";i:0;s:9:"Dashboard";i:0;s:9:"StopWatch";i:0;s:5:"Track";i:0;}}', 852, 1),
(23, 'Science', 'a:2:{s:14:"RedemptionItem";i:0;s:5:"Items";a:5:{s:5:"Alien";i:0;s:7:"Shuttle";i:0;s:10:"EarthsCore";i:0;s:9:"Chemistry";i:0;s:9:"Professor";i:0;}}', 853, 1),
(24, 'Soccer', 'a:2:{s:14:"RedemptionItem";i:0;s:5:"Items";a:5:{s:8:"WorldCup";i:0;s:12:"PenaltyCards";i:0;s:4:"Goal";i:0;s:10:"ScoreBoard";i:0;s:10:"SoccerBall";i:0;}}', 854, 1),
(25, 'SocialMedia', 'a:2:{s:14:"RedemptionItem";i:0;s:5:"Items";a:5:{s:5:"Email";i:0;s:6:"Photos";i:0;s:10:"Smartphone";i:0;s:4:"Blog";i:0;s:2:"TV";i:0;}}', 855, 1),
(26, 'SummerBeach2', 'a:2:{s:14:"RedemptionItem";i:0;s:5:"Items";a:5:{s:10:"Volleyball";i:0;s:6:"Bikini";i:0;s:10:"SandCastle";i:0;s:10:"BeachChair";i:0;s:8:"Starfish";i:0;}}', 856, 1),
(27, 'SummerBeach3', 'a:2:{s:14:"RedemptionItem";i:0;s:5:"Items";a:5:{s:10:"BananaBoat";i:0;s:13:"BathingTrunks";i:0;s:7:"Snorkel";i:0;s:9:"InnerTube";i:0;s:14:"InflatableBoat";i:0;}}', 857, 1),
(28, 'SummerBeach', 'a:2:{s:14:"RedemptionItem";i:0;s:5:"Items";a:5:{s:8:"Sunshine";i:0;s:9:"Sunscreen";i:0;s:10:"SunGlasses";i:0;s:13:"BeachUmbrella";i:0;s:10:"SurfBoards";i:0;}}', 858, 1),
(29, 'Traffic', 'a:2:{s:14:"RedemptionItem";i:0;s:5:"Items";a:5:{s:9:"GasNozzle";i:0;s:11:"TrafficCone";i:0;s:9:"PoliceCar";i:0;s:8:"RoadSign";i:0;s:13:"SteeringWheel";i:0;}}', 859, 1),
(30, 'Transportation', 'a:2:{s:14:"RedemptionItem";i:0;s:5:"Items";a:5:{s:7:"Caravan";i:0;s:5:"Plane";i:0;s:8:"SailBoat";i:0;s:5:"Truck";i:0;s:4:"Taxi";i:0;}}', 860, 1),
(31, 'TravelHoliday', 'a:2:{s:14:"RedemptionItem";i:0;s:5:"Items";a:5:{s:8:"Suitcase";i:0;s:6:"Camera";i:0;s:5:"Hotel";i:0;s:9:"Landscape";i:0;s:3:"Map";i:0;}}', 861, 1);

-- --------------------------------------------------------

--
-- Table structure for table `gamelevel`
--

CREATE TABLE IF NOT EXISTS `gamelevel` (
`id` int(11) unsigned NOT NULL,
  `item_id` int(11) unsigned DEFAULT NULL,
  `person_item_id` int(11) unsigned DEFAULT NULL,
  `type` varchar(64) COLLATE utf8_unicode_ci DEFAULT NULL,
  `value` int(11) DEFAULT NULL
) ENGINE=InnoDB AUTO_INCREMENT=22 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

--
-- Dumping data for table `gamelevel`
--

INSERT INTO `gamelevel` (`id`, `item_id`, `person_item_id`, `type`, `value`) VALUES
(2, 220, 64, 'General', 1),
(3, 221, 64, 'NewBusiness', 1),
(4, 228, 70, 'General', 1),
(5, 229, 70, 'NewBusiness', 1),
(6, 236, 65, 'General', 1),
(7, 237, 65, 'NewBusiness', 1),
(8, 244, 66, 'General', 1),
(9, 245, 66, 'NewBusiness', 1),
(10, 252, 69, 'General', 1),
(11, 253, 69, 'NewBusiness', 1),
(12, 260, 68, 'General', 1),
(13, 261, 68, 'NewBusiness', 1),
(14, 268, 67, 'General', 1),
(15, 269, 67, 'NewBusiness', 1),
(16, 276, 71, 'General', 1),
(17, 277, 71, 'NewBusiness', 1),
(18, 284, 1, 'General', 7),
(19, 285, 1, 'NewBusiness', 1),
(20, 573, 1, 'Sales', 7),
(21, 630, 1, 'AccountManagement', 1);

-- --------------------------------------------------------

--
-- Table structure for table `gamenotification`
--

CREATE TABLE IF NOT EXISTS `gamenotification` (
`id` int(11) unsigned NOT NULL,
  `_user_id` int(11) unsigned DEFAULT NULL,
  `serializeddata` text COLLATE utf8_unicode_ci
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `gamepoint`
--

CREATE TABLE IF NOT EXISTS `gamepoint` (
`id` int(11) unsigned NOT NULL,
  `item_id` int(11) unsigned DEFAULT NULL,
  `type` varchar(64) COLLATE utf8_unicode_ci DEFAULT NULL,
  `value` int(11) DEFAULT NULL,
  `person_item_id` int(11) unsigned DEFAULT NULL
) ENGINE=InnoDB AUTO_INCREMENT=24 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

--
-- Dumping data for table `gamepoint`
--

INSERT INTO `gamepoint` (`id`, `item_id`, `type`, `value`, `person_item_id`) VALUES
(2, 215, 'UserAdoption', 209, 64),
(3, 217, 'NewBusiness', 100, 64),
(4, 223, 'UserAdoption', 226, 70),
(5, 225, 'NewBusiness', 100, 70),
(6, 231, 'UserAdoption', 214, 65),
(7, 233, 'NewBusiness', 100, 65),
(8, 239, 'UserAdoption', 249, 66),
(9, 241, 'NewBusiness', 100, 66),
(10, 247, 'UserAdoption', 128, 69),
(11, 249, 'NewBusiness', 100, 69),
(12, 255, 'UserAdoption', 162, 68),
(13, 257, 'NewBusiness', 100, 68),
(14, 263, 'UserAdoption', 244, 67),
(15, 265, 'NewBusiness', 100, 67),
(16, 271, 'UserAdoption', 113, 71),
(17, 273, 'NewBusiness', 100, 71),
(18, 279, 'UserAdoption', 4825, 1),
(19, 281, 'NewBusiness', 160, 1),
(20, 565, 'Sales', 990, 1),
(21, 580, 'AccountManagement', 160, 1),
(22, 585, 'Communication', 80, 1),
(23, 594, 'TimeManagement', 100, 1);

-- --------------------------------------------------------

--
-- Table structure for table `gamepointtransaction`
--

CREATE TABLE IF NOT EXISTS `gamepointtransaction` (
`id` int(11) unsigned NOT NULL,
  `createddatetime` datetime DEFAULT NULL,
  `value` int(11) DEFAULT NULL,
  `gamepoint_id` int(11) unsigned DEFAULT NULL
) ENGINE=InnoDB AUTO_INCREMENT=227 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

--
-- Dumping data for table `gamepointtransaction`
--

INSERT INTO `gamepointtransaction` (`id`, `createddatetime`, `value`, `gamepoint_id`) VALUES
(2, '2013-06-25 12:30:29', 209, 2),
(3, '2013-06-25 12:30:29', 100, 3),
(4, '2013-06-25 12:30:30', 226, 4),
(5, '2013-06-25 12:30:30', 100, 5),
(6, '2013-06-25 12:30:30', 214, 6),
(7, '2013-06-25 12:30:30', 100, 7),
(8, '2013-06-25 12:30:30', 249, 8),
(9, '2013-06-25 12:30:30', 100, 9),
(10, '2013-06-25 12:30:30', 128, 10),
(11, '2013-06-25 12:30:30', 100, 11),
(12, '2013-06-25 12:30:30', 162, 12),
(13, '2013-06-25 12:30:30', 100, 13),
(14, '2013-06-25 12:30:31', 244, 14),
(15, '2013-06-25 12:30:31', 100, 15),
(16, '2013-06-25 12:30:31', 113, 16),
(17, '2013-06-25 12:30:31', 100, 17),
(18, '2013-06-25 12:30:31', 170, 18),
(19, '2013-06-25 12:30:31', 100, 19),
(20, '2016-01-04 16:08:46', 10, 18),
(21, '2016-01-04 16:26:58', 10, 18),
(22, '2016-01-04 16:59:11', 10, 18),
(23, '2016-01-05 05:58:34', 20, 18),
(24, '2016-01-05 05:58:36', 50, 18),
(25, '2016-01-05 10:29:36', 20, 18),
(26, '2016-01-05 10:29:37', 50, 18),
(27, '2016-01-05 10:33:40', 10, 20),
(28, '2016-01-05 10:33:40', 50, 18),
(29, '2016-01-05 10:35:05', 20, 20),
(30, '2016-01-05 10:39:23', 20, 20),
(31, '2016-01-05 11:11:03', 20, 20),
(32, '2016-01-05 12:25:55', 20, 18),
(33, '2016-01-05 13:10:18', 20, 20),
(34, '2016-01-05 13:10:18', 150, 18),
(35, '2016-01-05 13:11:16', 20, 18),
(36, '2016-01-06 05:42:44', 20, 18),
(37, '2016-01-06 06:56:51', 20, 20),
(38, '2016-01-06 06:56:52', 100, 18),
(39, '2016-01-06 06:57:04', 20, 20),
(40, '2016-01-06 12:12:26', 20, 18),
(41, '2016-01-06 12:26:03', 20, 21),
(42, '2016-01-06 12:26:04', 50, 18),
(43, '2016-01-06 12:27:01', 20, 22),
(44, '2016-01-06 12:27:01', 50, 18),
(45, '2016-01-07 03:38:29', 10, 18),
(46, '2016-01-07 03:47:27', 20, 22),
(47, '2016-01-07 03:47:28', 50, 18),
(48, '2016-01-07 03:47:45', 40, 23),
(49, '2016-01-07 03:47:45', 50, 18),
(50, '2016-01-07 03:48:18', 20, 22),
(51, '2016-01-07 03:48:32', 20, 22),
(52, '2016-01-07 03:48:53', 20, 20),
(53, '2016-01-07 03:49:10', 10, 20),
(54, '2016-01-07 03:51:35', 20, 23),
(55, '2016-01-07 03:51:46', 40, 23),
(56, '2016-01-07 05:49:55', 20, 18),
(57, '2016-01-07 08:42:29', 20, 18),
(58, '2016-01-07 15:47:38', 10, 18),
(59, '2016-01-07 16:15:14', 10, 18),
(60, '2016-01-07 17:06:18', 10, 18),
(61, '2016-01-07 17:06:19', 300, 18),
(62, '2016-01-08 16:27:09', 10, 18),
(63, '2016-01-08 17:01:26', 20, 20),
(64, '2016-01-08 17:01:27', 50, 18),
(65, '2016-01-08 17:02:33', 20, 20),
(66, '2016-01-08 17:17:27', 10, 19),
(67, '2016-01-08 17:17:27', 10, 21),
(68, '2016-01-08 19:02:51', 20, 20),
(69, '2016-01-08 19:02:52', 110, 18),
(70, '2016-01-10 10:03:14', 20, 18),
(71, '2016-01-10 10:13:16', 10, 21),
(72, '2016-01-10 11:08:57', 20, 18),
(73, '2016-01-10 11:15:57', 20, 18),
(74, '2016-01-10 12:58:08', 20, 18),
(75, '2016-01-10 13:32:18', 10, 20),
(76, '2016-01-10 13:42:45', 20, 18),
(77, '2016-01-10 13:55:58', 10, 21),
(78, '2016-01-10 14:09:57', 10, 18),
(79, '2016-01-10 14:21:19', 10, 18),
(80, '2016-01-10 15:51:46', 10, 18),
(81, '2016-01-10 15:53:19', 10, 18),
(82, '2016-01-10 16:01:41', 10, 20),
(83, '2016-01-10 16:03:15', 10, 21),
(84, '2016-01-10 16:04:15', 20, 20),
(85, '2016-01-10 18:11:04', 20, 20),
(86, '2016-01-10 18:41:46', 10, 18),
(87, '2016-01-10 18:54:32', 10, 18),
(88, '2016-01-10 18:56:48', 20, 20),
(89, '2016-01-11 05:30:25', 20, 18),
(90, '2016-01-11 05:55:25', 20, 20),
(91, '2016-01-11 06:56:53', 20, 18),
(92, '2016-01-11 06:58:03', 10, 19),
(93, '2016-01-11 06:58:04', 10, 21),
(94, '2016-01-11 06:58:46', 20, 20),
(95, '2016-01-11 06:58:46', 130, 18),
(96, '2016-01-11 06:59:32', 20, 20),
(97, '2016-01-11 06:59:33', 300, 18),
(98, '2016-01-11 16:15:05', 10, 18),
(99, '2016-01-11 16:16:16', 20, 20),
(100, '2016-01-12 18:04:03', 10, 18),
(101, '2016-01-12 18:05:52', 10, 19),
(102, '2016-01-12 18:05:52', 10, 21),
(103, '2016-01-12 18:07:01', 20, 20),
(104, '2016-01-12 18:13:11', 20, 20),
(105, '2016-01-12 18:13:11', 150, 18),
(106, '2016-01-12 18:39:24', 10, 18),
(107, '2016-01-12 18:48:40', 10, 18),
(108, '2016-01-12 18:49:38', 10, 18),
(109, '2016-01-12 18:50:56', 10, 19),
(110, '2016-01-12 18:50:56', 10, 21),
(111, '2016-01-12 18:51:54', 20, 21),
(112, '2016-01-12 18:51:54', 100, 18),
(113, '2016-01-12 18:53:08', 20, 20),
(114, '2016-01-12 19:25:29', 20, 20),
(115, '2016-01-12 19:30:41', 20, 20),
(116, '2016-01-12 19:30:41', 140, 18),
(117, '2016-01-12 19:38:03', 20, 20),
(118, '2016-01-14 09:42:55', 20, 18),
(119, '2016-01-14 09:54:08', 20, 18),
(120, '2016-01-14 09:56:11', 20, 20),
(121, '2016-01-14 09:56:51', 20, 20),
(122, '2016-01-14 15:00:25', 10, 18),
(123, '2016-01-14 16:04:15', 10, 18),
(124, '2016-01-14 16:20:11', 10, 18),
(125, '2016-01-14 16:25:11', 10, 18),
(126, '2016-01-14 16:25:11', 500, 18),
(127, '2016-01-14 16:43:17', 10, 18),
(128, '2016-01-14 16:46:32', 20, 20),
(129, '2016-01-14 16:51:21', 20, 20),
(130, '2016-01-14 17:07:10', 10, 18),
(131, '2016-01-15 14:01:42', 10, 19),
(132, '2016-01-15 14:01:42', 10, 21),
(133, '2016-01-15 14:02:45', 20, 20),
(134, '2016-01-15 14:07:47', 20, 21),
(135, '2016-01-15 14:08:22', 20, 20),
(136, '2016-01-15 14:08:22', 150, 18),
(137, '2016-01-15 15:32:07', 10, 18),
(138, '2016-01-15 15:46:17', 10, 18),
(139, '2016-01-15 15:49:26', 10, 18),
(140, '2016-01-15 18:42:01', 10, 18),
(141, '2016-01-15 19:41:37', 10, 18),
(142, '2016-01-15 19:44:47', 25, 18),
(143, '2016-01-15 19:46:00', 5, 18),
(144, '2016-01-15 19:46:00', 50, 18),
(145, '2016-01-15 21:01:28', 10, 18),
(146, '2016-01-15 21:09:52', 5, 18),
(147, '2016-01-15 21:47:31', 20, 20),
(148, '2016-01-15 22:14:03', 25, 18),
(149, '2016-01-15 22:14:20', 25, 18),
(150, '2016-01-15 22:27:08', 25, 18),
(151, '2016-01-15 22:27:16', 25, 18),
(152, '2016-01-15 22:27:25', 25, 18),
(153, '2016-01-15 22:31:24', 25, 18),
(154, '2016-01-17 06:26:08', 20, 18),
(155, '2016-01-18 14:15:16', 10, 18),
(156, '2016-01-18 16:00:00', 10, 18),
(157, '2016-01-18 16:46:18', 10, 21),
(158, '2016-01-18 17:32:33', 5, 18),
(159, '2016-01-18 18:03:44', 10, 18),
(160, '2016-01-18 18:06:07', 5, 18),
(161, '2016-01-18 19:00:27', 5, 18),
(162, '2016-01-18 19:00:33', 5, 18),
(163, '2016-01-19 07:47:13', 20, 18),
(164, '2016-01-19 07:47:14', 150, 18),
(165, '2016-01-19 09:15:30', 20, 18),
(166, '2016-01-19 09:27:01', 20, 18),
(167, '2016-01-19 09:41:35', 10, 20),
(168, '2016-01-19 09:48:31', 10, 20),
(169, '2016-01-19 09:48:51', 10, 20),
(170, '2016-01-19 13:42:13', 20, 18),
(171, '2016-01-19 13:42:13', 150, 18),
(172, '2016-01-19 13:50:05', 20, 18),
(173, '2016-01-19 13:50:55', 20, 20),
(174, '2016-01-19 13:57:55', 5, 18),
(175, '2016-01-19 13:58:00', 5, 18),
(176, '2016-01-19 14:17:01', 15, 18),
(177, '2016-01-19 14:17:01', 50, 18),
(178, '2016-01-19 14:19:42', 15, 18),
(179, '2016-01-19 14:20:42', 50, 18),
(180, '2016-01-19 14:20:42', 5, 18),
(181, '2016-01-19 14:22:35', 5, 18),
(182, '2016-01-19 14:24:03', 15, 18),
(183, '2016-01-19 18:08:42', 20, 20),
(184, '2016-01-19 18:14:09', 5, 18),
(185, '2016-01-19 18:14:09', 50, 18),
(186, '2016-01-19 18:14:19', 10, 20),
(187, '2016-01-19 18:14:46', 5, 18),
(188, '2016-01-19 18:14:48', 5, 18),
(189, '2016-01-19 18:14:51', 5, 18),
(190, '2016-01-19 18:14:55', 5, 18),
(191, '2016-01-19 18:14:59', 5, 18),
(192, '2016-01-19 18:15:05', 5, 18),
(193, '2016-01-19 18:15:10', 5, 18),
(194, '2016-01-19 18:15:21', 5, 18),
(195, '2016-01-19 18:45:59', 15, 18),
(196, '2016-01-19 18:45:59', 50, 18),
(197, '2016-01-19 18:52:54', 20, 20),
(198, '2016-01-19 18:53:35', 10, 20),
(199, '2016-01-19 19:12:07', 15, 18),
(200, '2016-01-19 19:16:46', 15, 18),
(201, '2016-01-19 19:18:30', 15, 18),
(202, '2016-01-19 19:19:28', 10, 18),
(203, '2016-01-19 19:29:41', 20, 20),
(204, '2016-01-19 19:29:41', 160, 18),
(205, '2016-01-19 19:30:09', 20, 20),
(206, '2016-01-19 19:31:24', 20, 20),
(207, '2016-01-19 19:32:36', 20, 20),
(208, '2016-01-19 19:38:19', 10, 18),
(209, '2016-01-19 19:39:13', 20, 20),
(210, '2016-01-19 19:41:44', 20, 20),
(211, '2016-01-19 19:43:58', 10, 19),
(212, '2016-01-19 19:43:58', 10, 21),
(213, '2016-01-19 19:49:02', 10, 18),
(214, '2016-01-19 19:49:50', 20, 20),
(215, '2016-01-19 19:50:14', 20, 20),
(216, '2016-01-19 19:51:08', 20, 20),
(217, '2016-01-19 19:51:08', 170, 18),
(218, '2016-01-19 19:51:50', 10, 18),
(219, '2016-01-19 19:54:06', 10, 18),
(220, '2016-01-19 19:54:32', 20, 20),
(221, '2016-01-19 19:55:22', 10, 20),
(222, '2016-01-19 19:56:32', 10, 20),
(223, '2016-01-19 20:20:59', 10, 18),
(224, '2016-01-19 20:32:02', 10, 18),
(225, '2016-01-20 12:02:40', 10, 20),
(226, '2016-01-20 12:42:57', 10, 20);

-- --------------------------------------------------------

--
-- Table structure for table `gamereward`
--

CREATE TABLE IF NOT EXISTS `gamereward` (
`id` int(11) unsigned NOT NULL,
  `cost` int(11) DEFAULT NULL,
  `description` text COLLATE utf8_unicode_ci,
  `expirationdatetime` datetime DEFAULT NULL,
  `name` varchar(64) COLLATE utf8_unicode_ci DEFAULT NULL,
  `quantity` int(11) DEFAULT NULL,
  `ownedsecurableitem_id` int(11) unsigned DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `gamerewardtransaction`
--

CREATE TABLE IF NOT EXISTS `gamerewardtransaction` (
`id` int(11) unsigned NOT NULL,
  `redemptiondatetime` datetime DEFAULT NULL,
  `quantity` int(11) DEFAULT NULL,
  `person_item_id` int(11) unsigned DEFAULT NULL,
  `transactions_gamereward_id` int(11) unsigned DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `gamereward_read`
--

CREATE TABLE IF NOT EXISTS `gamereward_read` (
`id` int(11) unsigned NOT NULL,
  `securableitem_id` int(11) unsigned NOT NULL,
  `munge_id` varchar(12) COLLATE utf8_unicode_ci NOT NULL,
  `count` int(8) unsigned NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `gamescore`
--

CREATE TABLE IF NOT EXISTS `gamescore` (
`id` int(11) unsigned NOT NULL,
  `item_id` int(11) unsigned DEFAULT NULL,
  `person_item_id` int(11) unsigned DEFAULT NULL,
  `type` varchar(64) COLLATE utf8_unicode_ci DEFAULT NULL,
  `value` int(11) DEFAULT NULL
) ENGINE=InnoDB AUTO_INCREMENT=43 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

--
-- Dumping data for table `gamescore`
--

INSERT INTO `gamescore` (`id`, `item_id`, `person_item_id`, `type`, `value`) VALUES
(2, 214, 64, 'LoginUser', 10),
(3, 216, 64, 'CreateAccount', 10),
(4, 222, 70, 'LoginUser', 10),
(5, 224, 70, 'CreateAccount', 10),
(6, 230, 65, 'LoginUser', 10),
(7, 232, 65, 'CreateAccount', 10),
(8, 238, 66, 'LoginUser', 10),
(9, 240, 66, 'CreateAccount', 10),
(10, 246, 69, 'LoginUser', 10),
(11, 248, 69, 'CreateAccount', 10),
(12, 254, 68, 'LoginUser', 10),
(13, 256, 68, 'CreateAccount', 10),
(14, 262, 67, 'LoginUser', 10),
(15, 264, 67, 'CreateAccount', 10),
(16, 270, 71, 'LoginUser', 10),
(17, 272, 71, 'CreateAccount', 10),
(18, 278, 1, 'LoginUser', 74),
(19, 280, 1, 'CreateAccount', 16),
(20, 558, 1, 'NightOwl', 12),
(21, 560, 1, 'EarlyBird', 11),
(22, 564, 1, 'CreateContract', 12),
(23, 568, 1, 'UpdateContract', 22),
(24, 578, 1, 'CreateContact', 2),
(25, 579, 1, 'UpdateContact', 2),
(26, 583, 1, 'CreateNote', 3),
(27, 584, 1, 'UpdateNote', 3),
(28, 588, 1, 'CreateMeeting', 1),
(29, 589, 1, 'UpdateMeeting', 1),
(30, 592, 1, 'CreateTask', 2),
(31, 593, 1, 'UpdateTask', 8),
(32, 598, 1, 'UpdateOpportunity', 56),
(33, 612, 1, 'CreateOpportunity', 9),
(34, 616, 1, 'UpdateAccount', 12),
(35, 697, 1, 'ImportAccount', 1),
(36, 698, 1, 'SearchAccount', 8),
(37, 759, 1, 'ImportOpportunity', 2),
(38, 763, 1, 'ImportContract', 4),
(39, 823, 1, 'MassEditContract', 4),
(40, 825, 1, 'SearchContract', 2),
(41, 827, 1, 'SearchOpportunity', 9),
(42, 829, 1, 'MassEditOpportunity', 3);

-- --------------------------------------------------------

--
-- Table structure for table `globalmetadata`
--

CREATE TABLE IF NOT EXISTS `globalmetadata` (
`id` int(11) unsigned NOT NULL,
  `classname` varchar(64) COLLATE utf8_unicode_ci DEFAULT NULL,
  `serializedmetadata` text COLLATE utf8_unicode_ci
) ENGINE=InnoDB AUTO_INCREMENT=22 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

--
-- Dumping data for table `globalmetadata`
--

INSERT INTO `globalmetadata` (`id`, `classname`, `serializedmetadata`) VALUES
(1, 'ZurmoModule', 'a:29:{s:18:"configureMenuItems";a:8:{i:0;a:5:{s:8:"category";i:1;s:10:"titleLabel";s:52:"eval:Zurmo::t(''ZurmoModule'', ''Global Configuration'')";s:16:"descriptionLabel";s:59:"eval:Zurmo::t(''ZurmoModule'', ''Manage Global Configuration'')";s:5:"route";s:32:"/zurmo/default/configurationEdit";s:5:"right";s:27:"Access Global Configuration";}i:1;a:5:{s:8:"category";i:1;s:10:"titleLabel";s:54:"eval:Zurmo::t(''ZurmoModule'', ''Currency Configuration'')";s:16:"descriptionLabel";s:61:"eval:Zurmo::t(''ZurmoModule'', ''Manage Currency Configuration'')";s:5:"route";s:33:"/zurmo/currency/configurationList";s:5:"right";s:29:"Access Currency Configuration";}i:2;a:5:{s:8:"category";i:1;s:10:"titleLabel";s:34:"eval:Zurmo::t(''Core'', ''Languages'')";s:16:"descriptionLabel";s:55:"eval:Zurmo::t(''ZurmoModule'', ''Manage Active Languages'')";s:5:"route";s:33:"/zurmo/language/configurationList";s:5:"right";s:27:"Access Global Configuration";}i:3;a:5:{s:8:"category";i:1;s:10:"titleLabel";s:47:"eval:Zurmo::t(''ZurmoModule'', ''Developer Tools'')";s:16:"descriptionLabel";s:54:"eval:Zurmo::t(''ZurmoModule'', ''Access Developer Tools'')";s:5:"route";s:19:"/zurmo/development/";s:5:"right";s:27:"Access Global Configuration";}i:4;a:5:{s:8:"category";i:1;s:10:"titleLabel";s:60:"eval:Zurmo::t(''ZurmoModule'', ''Authentication Configuration'')";s:16:"descriptionLabel";s:67:"eval:Zurmo::t(''ZurmoModule'', ''Manage Authentication Configuration'')";s:5:"route";s:39:"/zurmo/authentication/configurationEdit";s:5:"right";s:27:"Access Global Configuration";}i:5;a:5:{s:8:"category";i:1;s:10:"titleLabel";s:39:"eval:Zurmo::t(''ZurmoModule'', ''Plugins'')";s:16:"descriptionLabel";s:63:"eval:Zurmo::t(''ZurmoModule'', ''Manage Plugins and Integrations'')";s:5:"route";s:32:"/zurmo/plugins/configurationEdit";s:5:"right";s:27:"Access Global Configuration";}i:6;a:5:{s:8:"category";i:1;s:10:"titleLabel";s:60:"eval:Zurmo::t(''ZurmoModule'', ''User Interface Configuration'')";s:16:"descriptionLabel";s:67:"eval:Zurmo::t(''ZurmoModule'', ''Manage User Interface Configuration'')";s:5:"route";s:45:"/zurmo/default/userInterfaceConfigurationEdit";s:5:"right";s:27:"Access Global Configuration";}i:7;a:5:{s:8:"category";i:1;s:10:"titleLabel";s:52:"eval:Zurmo::t(''ZurmoModule'', ''System Configuration'')";s:16:"descriptionLabel";s:59:"eval:Zurmo::t(''ZurmoModule'', ''Manage System Configuration'')";s:5:"route";s:38:"/zurmo/default/systemConfigurationEdit";s:5:"right";s:27:"Access Global Configuration";}}s:15:"headerMenuItems";a:3:{i:0;a:5:{s:5:"label";s:46:"eval:Zurmo::t(''ZurmoModule'', ''Administration'')";s:3:"url";a:1:{i:0;s:14:"/configuration";}s:5:"right";s:25:"Access Administration Tab";s:5:"order";i:1;s:6:"mobile";b:0;}i:1;a:4:{s:5:"label";s:45:"eval:Zurmo::t(''ZurmoModule'', ''Need Support?'')";s:3:"url";s:36:"http://www.zurmo.com/needSupport.php";s:5:"order";i:9;s:6:"mobile";b:1;}i:2;a:4:{s:5:"label";s:43:"eval:Zurmo::t(''ZurmoModule'', ''About Zurmo'')";s:3:"url";a:1:{i:0;s:20:"/zurmo/default/about";}s:5:"order";i:10;s:6:"mobile";b:1;}}s:21:"configureSubMenuItems";a:1:{i:0;a:5:{s:8:"category";i:2;s:10:"titleLabel";s:50:"eval:Zurmo::t(''ZurmoModule'', ''LDAP Configuration'')";s:16:"descriptionLabel";s:58:"eval:Zurmo::t(''ZurmoModule'', ''Manage LDAP Authentication'')";s:5:"route";s:33:"/zurmo/ldap/configurationEditLdap";s:5:"right";s:27:"Access Global Configuration";}}s:31:"adminTabMenuItemsModuleOrdering";a:9:{i:0;s:4:"home";i:1;s:13:"configuration";i:2;s:8:"designer";i:3;s:6:"import";i:4;s:6:"groups";i:5;s:5:"users";i:6;s:5:"roles";i:7;s:9:"workflows";i:8;s:15:"contactWebForms";}s:26:"tabMenuItemsModuleOrdering";a:11:{i:0;s:4:"home";i:1;s:13:"mashableInbox";i:2;s:8:"accounts";i:3;s:5:"leads";i:4;s:8:"contacts";i:5;s:13:"opportunities";i:6;s:9:"marketing";i:7;s:8:"projects";i:8;s:8:"products";i:9;s:7:"reports";i:10;s:9:"contracts";}s:11:"globalState";s:40:"a:1:{s:14:"autoBuildState";s:5:"valid";}";s:15:"applicationName";s:10:"Opticaltel";s:22:"lastZurmoStableVersion";s:9:"2.0.12 ()";s:32:"lastAttemptedInfoUpdateTimeStamp";i:1453140224;s:18:"defaultFromAddress";s:28:"notification@zurmoalerts.com";s:20:"defaultTestToAddress";s:28:"testJobEmail@zurmoalerts.com";s:22:"customThemeColorsArray";a:3:{i:0;s:7:"#868d8d";i:1;s:7:"#e9078b";i:2;s:7:"#0f0f0f";}s:16:"globalThemeColor";s:6:"custom";s:18:"forceAllUsersTheme";b:1;s:9:"logoWidth";i:48;s:10:"logoHeight";i:32;s:15:"logoFileModelId";i:1;s:20:"logoThumbFileModelId";i:2;s:8:"timeZone";s:15:"America/Chicago";s:12:"listPageSize";i:11;s:15:"subListPageSize";i:5;s:17:"modalListPageSize";i:5;s:21:"dashboardListPageSize";i:5;s:37:"gamificationModalNotificationsEnabled";b:0;s:35:"gamificationModalCollectionsEnabled";b:0;s:29:"gamificationModalCoinsEnabled";b:0;s:22:"realtimeUpdatesEnabled";b:0;s:19:"reCaptchaPrivateKey";s:0:"";s:18:"reCaptchaPublicKey";s:0:"";}'),
(3, 'ContactsModule', 'a:10:{s:17:"designerMenuItems";a:4:{s:14:"showFieldsLink";b:1;s:15:"showGeneralLink";b:1;s:15:"showLayoutsLink";b:1;s:13:"showMenusLink";b:1;}s:26:"globalSearchAttributeNames";a:4:{i:0;s:8:"fullName";i:1;s:8:"anyEmail";i:2;s:11:"officePhone";i:3;s:11:"mobilePhone";}s:13:"startingState";i:1;s:12:"tabMenuItems";a:1:{i:0;a:4:{s:5:"label";s:80:"eval:Zurmo::t(''ContactsModule'', ''ContactsModulePluralLabel'', $translationParams)";s:3:"url";a:1:{i:0;s:17:"/contacts/default";}s:5:"right";s:19:"Access Contacts Tab";s:6:"mobile";b:1;}}s:24:"shortcutsCreateMenuItems";a:1:{i:0;a:4:{s:5:"label";s:82:"eval:Zurmo::t(''ContactsModule'', ''ContactsModuleSingularLabel'', $translationParams)";s:3:"url";a:1:{i:0;s:24:"/contacts/default/create";}s:5:"right";s:15:"Create Contacts";s:6:"mobile";b:1;}}s:15:"startingStateId";i:6;s:48:"updateLatestActivityDateTimeWhenATaskIsCompleted";b:1;s:46:"updateLatestActivityDateTimeWhenANoteIsCreated";b:1;s:55:"updateLatestActivityDateTimeWhenAnEmailIsSentOrArchived";b:1;s:51:"updateLatestActivityDateTimeWhenAMeetingIsInThePast";b:1;}'),
(5, 'Currency', 'a:4:{s:7:"members";a:3:{i:0;s:6:"active";i:1;s:4:"code";i:2;s:10:"rateToBase";}s:5:"rules";a:9:{i:0;a:2:{i:0;s:6:"active";i:1;s:7:"boolean";}i:1;a:3:{i:0;s:6:"active";i:1;s:7:"default";s:5:"value";b:1;}i:2;a:2:{i:0;s:4:"code";i:1;s:8:"required";}i:3;a:2:{i:0;s:4:"code";i:1;s:6:"unique";}i:4;a:3:{i:0;s:4:"code";i:1;s:4:"type";s:4:"type";s:6:"string";}i:5;a:4:{i:0;s:4:"code";i:1;s:6:"length";s:3:"min";i:3;s:3:"max";i:3;}i:6;a:4:{i:0;s:4:"code";i:1;s:5:"match";s:7:"pattern";s:19:"/^[A-Z][A-Z][A-Z]$/";s:7:"message";s:35:"Code must be a valid currency code.";}i:7;a:2:{i:0;s:10:"rateToBase";i:1;s:8:"required";}i:8;a:3:{i:0;s:10:"rateToBase";i:1;s:4:"type";s:4:"type";s:5:"float";}}s:20:"defaultSortAttribute";s:4:"code";s:32:"lastAttemptedRateUpdateTimeStamp";i:1453291121;}'),
(6, 'UsersModule', 'a:6:{s:17:"adminTabMenuItems";a:1:{i:0;a:3:{s:5:"label";s:37:"eval:Zurmo::t(''UsersModule'', ''Users'')";s:3:"url";a:1:{i:0;s:14:"/users/default";}s:5:"right";s:16:"Access Users Tab";}}s:26:"globalSearchAttributeNames";a:3:{i:0;s:8:"fullName";i:1;s:8:"anyEmail";i:2;s:8:"username";}s:18:"configureMenuItems";a:1:{i:0;a:5:{s:8:"category";i:1;s:10:"titleLabel";s:37:"eval:Zurmo::t(''UsersModule'', ''Users'')";s:16:"descriptionLabel";s:44:"eval:Zurmo::t(''UsersModule'', ''Manage Users'')";s:5:"route";s:14:"/users/default";s:5:"right";s:16:"Access Users Tab";}}s:15:"headerMenuItems";a:1:{i:0;a:5:{s:5:"label";s:37:"eval:Zurmo::t(''UsersModule'', ''Users'')";s:3:"url";a:1:{i:0;s:14:"/users/default";}s:5:"right";s:16:"Access Users Tab";s:5:"order";i:4;s:6:"mobile";b:0;}}s:19:"userHeaderMenuItems";a:2:{i:0;a:3:{s:5:"label";s:42:"eval:Zurmo::t(''UsersModule'', ''My Profile'')";s:3:"url";a:1:{i:0;s:22:"/users/default/profile";}s:5:"order";i:1;}i:1;a:3:{s:5:"label";s:40:"eval:Zurmo::t(''UsersModule'', ''Sign out'')";s:3:"url";a:1:{i:0;s:21:"/zurmo/default/logout";}s:5:"order";i:4;}}s:17:"designerMenuItems";a:4:{s:14:"showFieldsLink";b:0;s:15:"showGeneralLink";b:0;s:15:"showLayoutsLink";b:1;s:13:"showMenusLink";b:0;}}'),
(7, 'Contract', 'a:10:{s:7:"members";a:10:{i:0;s:9:"closeDate";i:1;s:11:"description";i:2;s:4:"name";i:3;s:11:"probability";i:4;s:15:"blendedbulkCstm";i:5;s:16:"propbillCstmCstm";i:6;s:11:"roiCstmCstm";i:7;s:16:"propInternetCstm";i:8;s:13:"propphoneCstm";i:9;s:14:"propAlaramCstm";}s:9:"relations";a:12:{s:7:"account";a:2:{i:0;i:2;i:1;s:7:"Account";}s:6:"amount";a:5:{i:0;i:2;i:1;s:13:"CurrencyValue";i:2;b:1;i:3;i:1;i:4;s:6:"amount";}s:8:"products";a:2:{i:0;i:3;i:1;s:7:"Product";}s:8:"contacts";a:2:{i:0;i:4;i:1;s:7:"Contact";}s:13:"opportunities";a:2:{i:0;i:4;i:1;s:11:"Opportunity";}s:5:"stage";a:5:{i:0;i:2;i:1;s:16:"OwnedCustomField";i:2;b:1;i:3;i:1;i:4;s:5:"stage";}s:6:"source";a:5:{i:0;i:2;i:1;s:16:"OwnedCustomField";i:2;b:1;i:3;i:1;i:4;s:6:"source";}s:8:"projects";a:2:{i:0;i:4;i:1;s:7:"Project";}s:16:"monthlynetCsCstm";a:5:{i:0;i:2;i:1;s:13:"CurrencyValue";i:2;b:1;i:3;i:1;i:4;s:16:"monthlynetCsCstm";}s:15:"doorfeeCstmCstm";a:5:{i:0;i:2;i:1;s:13:"CurrencyValue";i:2;b:1;i:3;i:1;i:4;s:15:"doorfeeCstmCstm";}s:10:"statusCstm";a:5:{i:0;i:2;i:1;s:16:"OwnedCustomField";i:2;b:1;i:3;i:1;i:4;s:10:"statusCstm";}s:16:"contractTypeCstm";a:5:{i:0;i:2;i:1;s:16:"OwnedCustomField";i:2;b:1;i:3;i:1;i:4;s:16:"contractTypeCstm";}}s:32:"derivedRelationsViaCastedUpModel";a:3:{s:8:"meetings";a:3:{i:0;i:4;i:1;s:7:"Meeting";i:2;s:13:"activityItems";}s:5:"notes";a:3:{i:0;i:4;i:1;s:4:"Note";i:2;s:13:"activityItems";}s:5:"tasks";a:3:{i:0;i:4;i:1;s:4:"Task";i:2;s:13:"activityItems";}}s:5:"rules";a:28:{i:0;a:2:{i:0;s:6:"amount";i:1;s:8:"required";}i:1;a:2:{i:0;s:9:"closeDate";i:1;s:8:"required";}i:2;a:3:{i:0;s:9:"closeDate";i:1;s:4:"type";s:4:"type";s:4:"date";}i:3;a:3:{i:0;s:11:"description";i:1;s:4:"type";s:4:"type";s:6:"string";}i:4;a:2:{i:0;s:4:"name";i:1;s:8:"required";}i:5;a:3:{i:0;s:4:"name";i:1;s:4:"type";s:4:"type";s:6:"string";}i:6;a:4:{i:0;s:4:"name";i:1;s:6:"length";s:3:"min";i:1;s:3:"max";i:64;}i:7;a:3:{i:0;s:11:"probability";i:1;s:4:"type";s:4:"type";s:7:"integer";}i:8;a:4:{i:0;s:11:"probability";i:1;s:9:"numerical";s:3:"min";i:0;s:3:"max";i:100;}i:9;a:3:{i:0;s:11:"probability";i:1;s:7:"default";s:5:"value";i:0;}i:10;a:2:{i:0;s:11:"probability";i:1;s:11:"probability";}i:11;a:4:{i:0;s:15:"blendedbulkCstm";i:1;s:9:"numerical";s:3:"min";i:0;s:3:"max";i:100;}i:12;a:2:{i:0;s:15:"blendedbulkCstm";i:1;s:8:"required";}i:13;a:3:{i:0;s:15:"blendedbulkCstm";i:1;s:4:"type";s:4:"type";s:7:"integer";}i:14;a:2:{i:0;s:16:"monthlynetCsCstm";i:1;s:8:"required";}i:15;a:2:{i:0;s:15:"doorfeeCstmCstm";i:1;s:8:"required";}i:16;a:3:{i:0;s:9:"closeDate";i:1;s:15:"dateTimeDefault";s:5:"value";s:0:"";}i:17;a:3:{i:0;s:16:"propbillCstmCstm";i:1;s:4:"type";s:4:"type";s:4:"date";}i:18;a:3:{i:0;s:16:"propbillCstmCstm";i:1;s:15:"dateTimeDefault";s:5:"value";s:0:"";}i:19;a:3:{i:0;s:11:"roiCstmCstm";i:1;s:6:"length";s:3:"max";i:11;}i:20;a:2:{i:0;s:11:"roiCstmCstm";i:1;s:8:"required";}i:21;a:3:{i:0;s:11:"roiCstmCstm";i:1;s:4:"type";s:4:"type";s:7:"integer";}i:22;a:3:{i:0;s:16:"propInternetCstm";i:1;s:4:"type";s:4:"type";s:4:"date";}i:23;a:3:{i:0;s:16:"propInternetCstm";i:1;s:15:"dateTimeDefault";s:5:"value";s:0:"";}i:24;a:3:{i:0;s:13:"propphoneCstm";i:1;s:4:"type";s:4:"type";s:4:"date";}i:25;a:3:{i:0;s:13:"propphoneCstm";i:1;s:15:"dateTimeDefault";s:5:"value";s:0:"";}i:26;a:3:{i:0;s:14:"propAlaramCstm";i:1;s:4:"type";s:4:"type";s:4:"date";}i:27;a:3:{i:0;s:14:"propAlaramCstm";i:1;s:15:"dateTimeDefault";s:5:"value";s:0:"";}}s:8:"elements";a:14:{s:6:"amount";s:13:"CurrencyValue";s:7:"account";s:7:"Account";s:9:"closeDate";s:4:"Date";s:11:"description";s:8:"TextArea";s:15:"blendedbulkCstm";s:7:"Integer";s:16:"monthlynetCsCstm";s:13:"CurrencyValue";s:15:"doorfeeCstmCstm";s:13:"CurrencyValue";s:16:"propbillCstmCstm";s:4:"Date";s:10:"statusCstm";s:8:"DropDown";s:11:"roiCstmCstm";s:7:"Integer";s:16:"contractTypeCstm";s:8:"DropDown";s:16:"propInternetCstm";s:4:"Date";s:13:"propphoneCstm";s:4:"Date";s:14:"propAlaramCstm";s:4:"Date";}s:12:"customFields";a:4:{s:5:"stage";s:11:"SalesStages";s:6:"source";s:11:"LeadSources";s:10:"statusCstm";s:6:"Status";s:16:"contractTypeCstm";s:12:"Contracttype";}s:20:"defaultSortAttribute";s:4:"name";s:15:"rollupRelations";a:2:{i:0;s:8:"contacts";i:1;s:13:"opportunities";}s:7:"noAudit";a:10:{i:0;s:11:"description";i:1;s:15:"blendedbulkCstm";i:2;s:16:"monthlynetCsCstm";i:3;s:15:"doorfeeCstmCstm";i:4;s:16:"propbillCstmCstm";i:5;s:10:"statusCstm";i:6;s:11:"roiCstmCstm";i:7;s:16:"propInternetCstm";i:8;s:13:"propphoneCstm";i:9;s:14:"propAlaramCstm";}s:6:"labels";a:12:{s:15:"blendedbulkCstm";a:1:{s:2:"en";s:19:"Blended Bulk Margin";}s:16:"monthlynetCsCstm";a:1:{s:2:"en";s:24:"Monthly Net Reoccurring ";}s:15:"doorfeeCstmCstm";a:1:{s:2:"en";s:8:"Door Fee";}s:6:"amount";a:1:{s:2:"en";s:15:"Total Key Money";}s:9:"closeDate";a:1:{s:2:"en";s:20:"Proposed Closed Date";}s:16:"propbillCstmCstm";a:1:{s:2:"en";s:31:"Proposed Billing Date for Video";}s:10:"statusCstm";a:1:{s:2:"en";s:6:"Status";}s:11:"roiCstmCstm";a:1:{s:2:"en";s:27:"ROI Total Months Calculator";}s:16:"contractTypeCstm";a:1:{s:2:"en";s:13:"Contract Type";}s:16:"propInternetCstm";a:1:{s:2:"en";s:34:"Proposed Billing Date for Internet";}s:13:"propphoneCstm";a:1:{s:2:"en";s:31:"Proposed Billing Date for Phone";}s:14:"propAlaramCstm";a:1:{s:2:"en";s:32:"Proposed Billing Date for Alaram";}}}'),
(8, 'ContractsModule', 'a:7:{s:17:"designerMenuItems";a:4:{s:14:"showFieldsLink";b:1;s:15:"showGeneralLink";b:1;s:15:"showLayoutsLink";b:1;s:13:"showMenusLink";b:1;}s:26:"globalSearchAttributeNames";a:1:{i:0;s:4:"name";}s:25:"stageToProbabilityMapping";a:6:{s:11:"Prospecting";i:10;s:13:"Qualification";i:25;s:11:"Negotiating";i:50;s:6:"Verbal";i:75;s:10:"Closed Won";i:100;s:11:"Closed Lost";i:0;}s:35:"automaticProbabilityMappingDisabled";b:0;s:12:"tabMenuItems";a:1:{i:0;a:4:{s:5:"label";s:82:"eval:Zurmo::t(''ContractsModule'', ''ContractsModulePluralLabel'', $translationParams)";s:3:"url";a:1:{i:0;s:18:"/contracts/default";}s:5:"right";s:20:"Access Contracts Tab";s:6:"mobile";b:1;}}s:24:"shortcutsCreateMenuItems";a:1:{i:0;a:4:{s:5:"label";s:84:"eval:Zurmo::t(''ContractsModule'', ''ContractsModuleSingularLabel'', $translationParams)";s:3:"url";a:1:{i:0;s:25:"/contracts/default/create";}s:5:"right";s:16:"Create Contracts";s:6:"mobile";b:1;}}s:58:"ContractEditAndDetailsView_layoutMissingRequiredAttributes";N;}'),
(9, 'ContractEditAndDetailsView', 'a:5:{s:7:"toolbar";a:1:{s:8:"elements";a:6:{i:0;a:2:{s:4:"type";s:10:"SaveButton";s:10:"renderType";s:4:"Edit";}i:1;a:2:{s:4:"type";s:10:"CancelLink";s:10:"renderType";s:4:"Edit";}i:2;a:2:{s:4:"type";s:8:"EditLink";s:10:"renderType";s:7:"Details";}i:3;a:2:{s:4:"type";s:24:"AuditEventsModalListLink";s:10:"renderType";s:7:"Details";}i:4;a:2:{s:4:"type";s:8:"CopyLink";s:10:"renderType";s:7:"Details";}i:5;a:2:{s:4:"type";s:18:"ContractDeleteLink";s:10:"renderType";s:7:"Details";}}}s:21:"derivedAttributeTypes";a:0:{}s:26:"nonPlaceableAttributeNames";a:1:{i:0;s:5:"owner";}s:17:"panelsDisplayType";i:1;s:6:"panels";a:1:{i:0;a:2:{s:5:"title";s:0:"";s:4:"rows";a:14:{i:0;a:1:{s:5:"cells";a:1:{i:0;a:1:{s:8:"elements";a:1:{i:0;a:2:{s:13:"attributeName";s:4:"name";s:4:"type";s:4:"Text";}}}}}i:1;a:1:{s:5:"cells";a:1:{i:0;a:1:{s:8:"elements";a:1:{i:0;a:2:{s:13:"attributeName";s:15:"blendedbulkCstm";s:4:"type";s:7:"Integer";}}}}}i:2;a:1:{s:5:"cells";a:1:{i:0;a:1:{s:8:"elements";a:1:{i:0;a:2:{s:13:"attributeName";s:16:"monthlynetCsCstm";s:4:"type";s:13:"CurrencyValue";}}}}}i:3;a:1:{s:5:"cells";a:1:{i:0;a:1:{s:8:"elements";a:1:{i:0;a:2:{s:13:"attributeName";s:15:"doorfeeCstmCstm";s:4:"type";s:13:"CurrencyValue";}}}}}i:4;a:1:{s:5:"cells";a:1:{i:0;a:1:{s:8:"elements";a:1:{i:0;a:2:{s:13:"attributeName";s:6:"amount";s:4:"type";s:13:"CurrencyValue";}}}}}i:5;a:1:{s:5:"cells";a:1:{i:0;a:1:{s:8:"elements";a:1:{i:0;a:2:{s:13:"attributeName";s:11:"roiCstmCstm";s:4:"type";s:7:"Integer";}}}}}i:6;a:1:{s:5:"cells";a:1:{i:0;a:1:{s:8:"elements";a:1:{i:0;a:2:{s:13:"attributeName";s:9:"closeDate";s:4:"type";s:4:"Date";}}}}}i:7;a:1:{s:5:"cells";a:1:{i:0;a:1:{s:8:"elements";a:1:{i:0;a:2:{s:13:"attributeName";s:16:"propbillCstmCstm";s:4:"type";s:4:"Date";}}}}}i:8;a:1:{s:5:"cells";a:1:{i:0;a:1:{s:8:"elements";a:1:{i:0;a:2:{s:13:"attributeName";s:16:"propInternetCstm";s:4:"type";s:4:"Date";}}}}}i:9;a:1:{s:5:"cells";a:1:{i:0;a:1:{s:8:"elements";a:1:{i:0;a:2:{s:13:"attributeName";s:13:"propphoneCstm";s:4:"type";s:4:"Date";}}}}}i:10;a:1:{s:5:"cells";a:1:{i:0;a:1:{s:8:"elements";a:1:{i:0;a:2:{s:13:"attributeName";s:14:"propAlaramCstm";s:4:"type";s:4:"Date";}}}}}i:11;a:1:{s:5:"cells";a:1:{i:0;a:1:{s:8:"elements";a:1:{i:0;a:2:{s:13:"attributeName";s:7:"account";s:4:"type";s:7:"Account";}}}}}i:12;a:1:{s:5:"cells";a:1:{i:0;a:1:{s:8:"elements";a:1:{i:0;a:3:{s:13:"attributeName";s:16:"contractTypeCstm";s:4:"type";s:8:"DropDown";s:8:"addBlank";b:1;}}}}}i:13;a:1:{s:5:"cells";a:1:{i:0;a:1:{s:8:"elements";a:1:{i:0;a:3:{s:13:"attributeName";s:10:"statusCstm";s:4:"type";s:8:"DropDown";s:8:"addBlank";b:1;}}}}}}}}}'),
(10, 'CalendarsModule', 'a:2:{s:26:"globalSearchAttributeNames";a:1:{i:0;s:4:"name";}s:12:"tabMenuItems";a:1:{i:0;a:3:{s:5:"label";s:82:"eval:Zurmo::t(''CalendarsModule'', ''CalendarsModulePluralLabel'', $translationParams)";s:3:"url";a:1:{i:0;s:18:"/calendars/default";}s:5:"right";s:19:"Access Calandar Tab";}}}'),
(11, 'LeadsModule', 'a:8:{s:23:"convertToAccountSetting";s:1:"2";s:33:"convertToAccountAttributesMapping";a:7:{s:8:"industry";s:8:"industry";s:7:"website";s:7:"website";s:14:"primaryAddress";s:14:"billingAddress";s:16:"secondaryAddress";s:15:"shippingAddress";s:11:"officePhone";s:11:"officePhone";s:9:"officeFax";s:9:"officeFax";s:11:"companyName";s:4:"name";}s:17:"designerMenuItems";a:4:{s:14:"showFieldsLink";b:1;s:15:"showGeneralLink";b:1;s:15:"showLayoutsLink";b:1;s:13:"showMenusLink";b:1;}s:26:"globalSearchAttributeNames";a:5:{i:0;s:8:"anyEmail";i:1;s:11:"companyName";i:2;s:11:"mobilePhone";i:3;s:8:"fullName";i:4;s:11:"officePhone";}s:12:"tabMenuItems";a:1:{i:0;a:4:{s:5:"label";s:74:"eval:Zurmo::t(''LeadsModule'', ''LeadsModulePluralLabel'', $translationParams)";s:3:"url";a:1:{i:0;s:14:"/leads/default";}s:5:"right";s:16:"Access Leads Tab";s:6:"mobile";b:1;}}s:24:"shortcutsCreateMenuItems";a:1:{i:0;a:4:{s:5:"label";s:76:"eval:Zurmo::t(''LeadsModule'', ''LeadsModuleSingularLabel'', $translationParams)";s:3:"url";a:1:{i:0;s:21:"/leads/default/create";}s:5:"right";s:12:"Create Leads";s:6:"mobile";b:1;}}s:20:"singularModuleLabels";a:1:{s:2:"en";s:5:"leads";}s:18:"pluralModuleLabels";a:1:{s:2:"en";s:5:"leads";}}'),
(12, 'Account', 'a:10:{s:7:"members";a:9:{i:0;s:13:"annualRevenue";i:1;s:11:"description";i:2;s:9:"employees";i:3;s:22:"latestActivityDateTime";i:4;s:4:"name";i:5;s:11:"officePhone";i:6;s:9:"officeFax";i:7;s:7:"website";i:8;s:13:"unitsCstmCstm";}s:9:"relations";a:18:{s:7:"account";a:2:{i:0;i:1;i:1;s:7:"Account";}s:26:"primaryAccountAffiliations";a:5:{i:0;i:3;i:1;s:25:"AccountAccountAffiliation";i:2;b:1;i:3;i:1;i:4;s:25:"primaryAccountAffiliation";}s:28:"secondaryAccountAffiliations";a:5:{i:0;i:3;i:1;s:25:"AccountAccountAffiliation";i:2;b:1;i:3;i:1;i:4;s:27:"secondaryAccountAffiliation";}s:8:"accounts";a:2:{i:0;i:3;i:1;s:7:"Account";}s:14:"billingAddress";a:5:{i:0;i:2;i:1;s:7:"Address";i:2;b:1;i:3;i:1;i:4;s:14:"billingAddress";}s:8:"products";a:2:{i:0;i:3;i:1;s:7:"Product";}s:19:"contactAffiliations";a:5:{i:0;i:3;i:1;s:25:"AccountContactAffiliation";i:2;b:1;i:3;i:1;i:4;s:18:"accountAffiliation";}s:8:"contacts";a:2:{i:0;i:3;i:1;s:7:"Contact";}s:8:"industry";a:5:{i:0;i:2;i:1;s:16:"OwnedCustomField";i:2;b:1;i:3;i:1;i:4;s:8:"industry";}s:13:"opportunities";a:2:{i:0;i:3;i:1;s:11:"Opportunity";}s:9:"contracts";a:2:{i:0;i:3;i:1;s:8:"Contract";}s:12:"primaryEmail";a:5:{i:0;i:2;i:1;s:5:"Email";i:2;b:1;i:3;i:1;i:4;s:12:"primaryEmail";}s:14:"secondaryEmail";a:5:{i:0;i:2;i:1;s:5:"Email";i:2;b:1;i:3;i:1;i:4;s:14:"secondaryEmail";}s:15:"shippingAddress";a:5:{i:0;i:2;i:1;s:7:"Address";i:2;b:1;i:3;i:1;i:4;s:15:"shippingAddress";}s:4:"type";a:5:{i:0;i:2;i:1;s:16:"OwnedCustomField";i:2;b:1;i:3;i:1;i:4;s:4:"type";}s:8:"projects";a:2:{i:0;i:4;i:1;s:7:"Project";}s:15:"comtypeCstmCstm";a:5:{i:0;i:2;i:1;s:16:"OwnedCustomField";i:2;b:1;i:3;i:1;i:4;s:15:"comtypeCstmCstm";}s:16:"customertypeCstm";a:5:{i:0;i:2;i:1;s:16:"OwnedCustomField";i:2;b:1;i:3;i:1;i:4;s:16:"customertypeCstm";}}s:32:"derivedRelationsViaCastedUpModel";a:3:{s:8:"meetings";a:3:{i:0;i:4;i:1;s:7:"Meeting";i:2;s:13:"activityItems";}s:5:"notes";a:3:{i:0;i:4;i:1;s:4:"Note";i:2;s:13:"activityItems";}s:5:"tasks";a:3:{i:0;i:4;i:1;s:4:"Task";i:2;s:13:"activityItems";}}s:5:"rules";a:18:{i:0;a:3:{i:0;s:13:"annualRevenue";i:1;s:4:"type";s:4:"type";s:5:"float";}i:1;a:3:{i:0;s:11:"description";i:1;s:4:"type";s:4:"type";s:6:"string";}i:2;a:3:{i:0;s:9:"employees";i:1;s:4:"type";s:4:"type";s:7:"integer";}i:3;a:2:{i:0;s:22:"latestActivityDateTime";i:1;s:8:"readOnly";}i:4;a:3:{i:0;s:22:"latestActivityDateTime";i:1;s:4:"type";s:4:"type";s:8:"datetime";}i:5;a:2:{i:0;s:4:"name";i:1;s:8:"required";}i:6;a:3:{i:0;s:4:"name";i:1;s:4:"type";s:4:"type";s:6:"string";}i:7;a:4:{i:0;s:4:"name";i:1;s:6:"length";s:3:"min";i:1;s:3:"max";i:64;}i:8;a:3:{i:0;s:11:"officePhone";i:1;s:4:"type";s:4:"type";s:6:"string";}i:9;a:4:{i:0;s:11:"officePhone";i:1;s:6:"length";s:3:"min";i:1;s:3:"max";i:24;}i:10;a:3:{i:0;s:9:"officeFax";i:1;s:4:"type";s:4:"type";s:6:"string";}i:11;a:4:{i:0;s:9:"officeFax";i:1;s:6:"length";s:3:"min";i:1;s:3:"max";i:24;}i:12;a:3:{i:0;s:7:"website";i:1;s:3:"url";s:13:"defaultScheme";s:4:"http";}i:13;a:2:{i:0;s:15:"comtypeCstmCstm";i:1;s:8:"required";}i:14;a:3:{i:0;s:13:"unitsCstmCstm";i:1;s:6:"length";s:3:"max";i:255;}i:15;a:2:{i:0;s:13:"unitsCstmCstm";i:1;s:8:"required";}i:16;a:3:{i:0;s:13:"unitsCstmCstm";i:1;s:4:"type";s:4:"type";s:6:"string";}i:17;a:2:{i:0;s:16:"customertypeCstm";i:1;s:8:"required";}}s:8:"elements";a:13:{s:7:"account";s:7:"Account";s:14:"billingAddress";s:7:"Address";s:11:"description";s:8:"TextArea";s:22:"latestActivityDateTime";s:8:"DateTime";s:11:"officePhone";s:5:"Phone";s:9:"officeFax";s:5:"Phone";s:12:"primaryEmail";s:23:"EmailAddressInformation";s:14:"secondaryEmail";s:23:"EmailAddressInformation";s:15:"shippingAddress";s:7:"Address";s:4:"name";s:4:"Text";s:15:"comtypeCstmCstm";s:8:"DropDown";s:13:"unitsCstmCstm";s:4:"Text";s:16:"customertypeCstm";s:8:"DropDown";}s:12:"customFields";a:4:{s:8:"industry";s:10:"Industries";s:4:"type";s:12:"AccountTypes";s:15:"comtypeCstmCstm";s:11:"Comtypecstm";s:16:"customertypeCstm";s:12:"Customertype";}s:20:"defaultSortAttribute";s:4:"name";s:15:"rollupRelations";a:4:{s:8:"accounts";a:3:{i:0;s:8:"contacts";i:1;s:13:"opportunities";i:2;s:9:"contracts";}i:0;s:8:"contacts";i:1;s:13:"opportunities";i:2;s:9:"contracts";}s:7:"noAudit";a:8:{i:0;s:13:"annualRevenue";i:1;s:11:"description";i:2;s:9:"employees";i:3;s:22:"latestActivityDateTime";i:4;s:7:"website";i:5;s:15:"comtypeCstmCstm";i:6;s:13:"unitsCstmCstm";i:7;s:16:"customertypeCstm";}s:6:"labels";a:4:{s:4:"name";a:1:{s:2:"en";s:14:"Community Name";}s:15:"comtypeCstmCstm";a:1:{s:2:"en";s:14:"Community Type";}s:13:"unitsCstmCstm";a:1:{s:2:"en";s:15:"Number Of Units";}s:16:"customertypeCstm";a:1:{s:2:"en";s:13:"Customer Type";}}}'),
(13, 'AccountEditAndDetailsView', 'a:4:{s:7:"toolbar";a:1:{s:8:"elements";a:6:{i:0;a:2:{s:4:"type";s:10:"SaveButton";s:10:"renderType";s:4:"Edit";}i:1;a:2:{s:4:"type";s:10:"CancelLink";s:10:"renderType";s:4:"Edit";}i:2;a:2:{s:4:"type";s:8:"EditLink";s:10:"renderType";s:7:"Details";}i:3;a:2:{s:4:"type";s:24:"AuditEventsModalListLink";s:10:"renderType";s:7:"Details";}i:4;a:2:{s:4:"type";s:8:"CopyLink";s:10:"renderType";s:7:"Details";}i:5;a:2:{s:4:"type";s:17:"AccountDeleteLink";s:10:"renderType";s:7:"Details";}}}s:26:"nonPlaceableAttributeNames";a:3:{i:0;s:7:"account";i:1;s:5:"owner";i:2;s:22:"latestActivityDateTime";}s:17:"panelsDisplayType";i:1;s:6:"panels";a:1:{i:0;a:2:{s:5:"title";s:0:"";s:4:"rows";a:6:{i:0;a:1:{s:5:"cells";a:1:{i:0;a:1:{s:8:"elements";a:1:{i:0;a:2:{s:13:"attributeName";s:4:"name";s:4:"type";s:4:"Text";}}}}}i:1;a:1:{s:5:"cells";a:1:{i:0;a:1:{s:8:"elements";a:1:{i:0;a:2:{s:13:"attributeName";s:14:"billingAddress";s:4:"type";s:7:"Address";}}}}}i:2;a:1:{s:5:"cells";a:1:{i:0;a:1:{s:8:"elements";a:1:{i:0;a:3:{s:13:"attributeName";s:15:"comtypeCstmCstm";s:4:"type";s:8:"DropDown";s:8:"addBlank";b:1;}}}}}i:3;a:1:{s:5:"cells";a:1:{i:0;a:1:{s:8:"elements";a:1:{i:0;a:2:{s:13:"attributeName";s:13:"unitsCstmCstm";s:4:"type";s:4:"Text";}}}}}i:4;a:1:{s:5:"cells";a:1:{i:0;a:1:{s:8:"elements";a:1:{i:0;a:3:{s:13:"attributeName";s:16:"customertypeCstm";s:4:"type";s:8:"DropDown";s:8:"addBlank";b:1;}}}}}i:5;a:1:{s:5:"cells";a:1:{i:0;a:1:{s:8:"elements";a:1:{i:0;a:2:{s:13:"attributeName";s:11:"description";s:4:"type";s:8:"TextArea";}}}}}}}}}'),
(14, 'AccountsModule', 'a:11:{s:17:"designerMenuItems";a:4:{s:14:"showFieldsLink";b:1;s:15:"showGeneralLink";b:1;s:15:"showLayoutsLink";b:1;s:13:"showMenusLink";b:1;}s:26:"globalSearchAttributeNames";a:3:{i:0;s:4:"name";i:1;s:8:"anyEmail";i:2;s:11:"officePhone";}s:12:"tabMenuItems";a:1:{i:0;a:4:{s:5:"label";s:80:"eval:Zurmo::t(''AccountsModule'', ''AccountsModulePluralLabel'', $translationParams)";s:3:"url";a:1:{i:0;s:17:"/accounts/default";}s:5:"right";s:19:"Access Accounts Tab";s:6:"mobile";b:1;}}s:24:"shortcutsCreateMenuItems";a:1:{i:0;a:4:{s:5:"label";s:82:"eval:Zurmo::t(''AccountsModule'', ''AccountsModuleSingularLabel'', $translationParams)";s:3:"url";a:1:{i:0;s:24:"/accounts/default/create";}s:5:"right";s:15:"Create Accounts";s:6:"mobile";b:1;}}s:48:"updateLatestActivityDateTimeWhenATaskIsCompleted";b:1;s:46:"updateLatestActivityDateTimeWhenANoteIsCreated";b:1;s:55:"updateLatestActivityDateTimeWhenAnEmailIsSentOrArchived";b:1;s:51:"updateLatestActivityDateTimeWhenAMeetingIsInThePast";b:1;s:57:"AccountEditAndDetailsView_layoutMissingRequiredAttributes";N;s:52:"AccountConvertToView_layoutMissingRequiredAttributes";i:1;s:54:"AccountModalCreateView_layoutMissingRequiredAttributes";i:1;}'),
(15, 'Opportunity', 'a:10:{s:7:"members";a:5:{i:0;s:9:"closeDate";i:1;s:11:"description";i:2;s:4:"name";i:3;s:11:"probability";i:4;s:16:"proposedinfCCstm";}s:9:"relations";a:20:{s:7:"account";a:2:{i:0;i:2;i:1;s:7:"Account";}s:6:"amount";a:5:{i:0;i:2;i:1;s:13:"CurrencyValue";i:2;b:1;i:3;i:1;i:4;s:6:"amount";}s:8:"products";a:2:{i:0;i:3;i:1;s:7:"Product";}s:8:"contacts";a:2:{i:0;i:4;i:1;s:7:"Contact";}s:9:"contracts";a:2:{i:0;i:4;i:1;s:8:"Contract";}s:5:"stage";a:5:{i:0;i:2;i:1;s:16:"OwnedCustomField";i:2;b:1;i:3;i:1;i:4;s:5:"stage";}s:6:"source";a:5:{i:0;i:2;i:1;s:16:"OwnedCustomField";i:2;b:1;i:3;i:1;i:4;s:6:"source";}s:8:"projects";a:2:{i:0;i:4;i:1;s:7:"Project";}s:16:"bulkservprCsCstm";a:5:{i:0;i:2;i:1;s:30:"OwnedMultipleValuesCustomField";i:2;b:1;i:3;i:1;i:4;s:16:"bulkservprCsCstm";}s:16:"contractlengCstm";a:5:{i:0;i:2;i:1;s:16:"OwnedCustomField";i:2;b:1;i:3;i:1;i:4;s:16:"contractlengCstm";}s:16:"vidpricingCsCstm";a:5:{i:0;i:2;i:1;s:13:"CurrencyValue";i:2;b:1;i:3;i:1;i:4;s:16:"vidpricingCsCstm";}s:16:"alarmbulkCstCstm";a:5:{i:0;i:2;i:1;s:13:"CurrencyValue";i:2;b:1;i:3;i:1;i:4;s:16:"alarmbulkCstCstm";}s:16:"internetbulkCstm";a:5:{i:0;i:2;i:1;s:13:"CurrencyValue";i:2;b:1;i:3;i:1;i:4;s:16:"internetbulkCstm";}s:16:"phonebulkCstCstm";a:5:{i:0;i:2;i:1;s:13:"CurrencyValue";i:2;b:1;i:3;i:1;i:4;s:16:"phonebulkCstCstm";}s:16:"totalbulkpriCstm";a:5:{i:0;i:2;i:1;s:13:"CurrencyValue";i:2;b:1;i:3;i:1;i:4;s:16:"totalbulkpriCstm";}s:12:"tprmonreCstm";a:5:{i:0;i:2;i:1;s:13:"CurrencyValue";i:2;b:1;i:3;i:1;i:4;s:12:"tprmonreCstm";}s:16:"consrequestCCstm";a:5:{i:0;i:2;i:1;s:16:"OwnedCustomField";i:2;b:1;i:3;i:1;i:4;s:16:"consrequestCCstm";}s:16:"constructcosCstm";a:5:{i:0;i:2;i:1;s:13:"CurrencyValue";i:2;b:1;i:3;i:1;i:4;s:16:"constructcosCstm";}s:16:"totalcostprCCstm";a:5:{i:0;i:2;i:1;s:13:"CurrencyValue";i:2;b:1;i:3;i:1;i:4;s:16:"totalcostprCCstm";}s:10:"rampupCstm";a:5:{i:0;i:2;i:1;s:16:"OwnedCustomField";i:2;b:1;i:3;i:1;i:4;s:10:"rampupCstm";}}s:32:"derivedRelationsViaCastedUpModel";a:3:{s:8:"meetings";a:3:{i:0;i:4;i:1;s:7:"Meeting";i:2;s:13:"activityItems";}s:5:"notes";a:3:{i:0;i:4;i:1;s:4:"Note";i:2;s:13:"activityItems";}s:5:"tasks";a:3:{i:0;i:4;i:1;s:4:"Task";i:2;s:13:"activityItems";}}s:5:"rules";a:17:{i:0;a:2:{i:0;s:6:"amount";i:1;s:8:"required";}i:1;a:2:{i:0;s:9:"closeDate";i:1;s:8:"required";}i:2;a:3:{i:0;s:9:"closeDate";i:1;s:4:"type";s:4:"type";s:4:"date";}i:3;a:3:{i:0;s:11:"description";i:1;s:4:"type";s:4:"type";s:6:"string";}i:4;a:2:{i:0;s:4:"name";i:1;s:8:"required";}i:5;a:3:{i:0;s:4:"name";i:1;s:4:"type";s:4:"type";s:6:"string";}i:6;a:4:{i:0;s:4:"name";i:1;s:6:"length";s:3:"min";i:1;s:3:"max";i:64;}i:7;a:3:{i:0;s:11:"probability";i:1;s:4:"type";s:4:"type";s:7:"integer";}i:8;a:4:{i:0;s:11:"probability";i:1;s:9:"numerical";s:3:"min";i:0;s:3:"max";i:100;}i:9;a:2:{i:0;s:11:"probability";i:1;s:8:"required";}i:10;a:3:{i:0;s:11:"probability";i:1;s:7:"default";s:5:"value";i:0;}i:11;a:2:{i:0;s:11:"probability";i:1;s:11:"probability";}i:12;a:2:{i:0;s:5:"stage";i:1;s:8:"required";}i:13;a:3:{i:0;s:16:"proposedinfCCstm";i:1;s:6:"length";s:3:"max";i:255;}i:14;a:3:{i:0;s:16:"proposedinfCCstm";i:1;s:4:"type";s:4:"type";s:6:"string";}i:15;a:2:{i:0;s:12:"tprmonreCstm";i:1;s:8:"required";}i:16;a:3:{i:0;s:9:"closeDate";i:1;s:15:"dateTimeDefault";s:5:"value";s:0:"";}}s:8:"elements";a:19:{s:6:"amount";s:13:"CurrencyValue";s:7:"account";s:7:"Account";s:9:"closeDate";s:4:"Date";s:11:"description";s:8:"TextArea";s:4:"name";s:4:"Text";s:16:"bulkservprCsCstm";s:19:"MultiSelectDropDown";s:16:"proposedinfCCstm";s:4:"Text";s:16:"contractlengCstm";s:8:"DropDown";s:16:"vidpricingCsCstm";s:13:"CurrencyValue";s:16:"alarmbulkCstCstm";s:13:"CurrencyValue";s:16:"internetbulkCstm";s:13:"CurrencyValue";s:16:"phonebulkCstCstm";s:13:"CurrencyValue";s:16:"totalbulkpriCstm";s:13:"CurrencyValue";s:12:"tprmonreCstm";s:13:"CurrencyValue";s:16:"consrequestCCstm";s:8:"DropDown";s:16:"constructcosCstm";s:13:"CurrencyValue";s:16:"totalcostprCCstm";s:13:"CurrencyValue";s:5:"stage";s:8:"DropDown";s:10:"rampupCstm";s:8:"DropDown";}s:12:"customFields";a:6:{s:5:"stage";s:11:"SalesStages";s:6:"source";s:11:"LeadSources";s:16:"bulkservprCsCstm";s:12:"Bulkservprcs";s:16:"contractlengCstm";s:12:"Contractleng";s:16:"consrequestCCstm";s:12:"Consrequestc";s:10:"rampupCstm";s:6:"Rampup";}s:20:"defaultSortAttribute";s:4:"name";s:15:"rollupRelations";a:2:{i:0;s:8:"contacts";i:1;s:9:"contracts";}s:7:"noAudit";a:14:{i:0;s:11:"description";i:1;s:16:"bulkservprCsCstm";i:2;s:16:"proposedinfCCstm";i:3;s:16:"contractlengCstm";i:4;s:16:"vidpricingCsCstm";i:5;s:16:"alarmbulkCstCstm";i:6;s:16:"internetbulkCstm";i:7;s:16:"phonebulkCstCstm";i:8;s:16:"totalbulkpriCstm";i:9;s:12:"tprmonreCstm";i:10;s:16:"consrequestCCstm";i:11;s:16:"constructcosCstm";i:12;s:16:"totalcostprCCstm";i:13;s:10:"rampupCstm";}s:6:"labels";a:17:{s:4:"name";a:1:{s:2:"en";s:16:"Opportunity Name";}s:16:"bulkservprCsCstm";a:1:{s:2:"en";s:23:"Requested Bulk Services";}s:16:"proposedinfCCstm";a:1:{s:2:"en";s:23:"Proposed Infrastructure";}s:16:"contractlengCstm";a:1:{s:2:"en";s:15:"Contract Length";}s:16:"vidpricingCsCstm";a:1:{s:2:"en";s:36:"Video Proposed Bulk Pricing Per Unit";}s:16:"alarmbulkCstCstm";a:1:{s:2:"en";s:36:"Alarm Proposed Bulk Pricing Per Unit";}s:16:"internetbulkCstm";a:1:{s:2:"en";s:39:"Internet Proposed Bulk Pricing Per Unit";}s:16:"phonebulkCstCstm";a:1:{s:2:"en";s:36:"Phone Proposed Bulk Pricing Per Unit";}s:16:"totalbulkpriCstm";a:1:{s:2:"en";s:27:"Total Bulk Pricing Per Unit";}s:12:"tprmonreCstm";a:1:{s:2:"en";s:32:"Total Proposed Monthly Recurring";}s:16:"consrequestCCstm";a:1:{s:2:"en";s:25:"Construction Cost Request";}s:16:"constructcosCstm";a:1:{s:2:"en";s:36:"Estimated Construction Cost Per Unit";}s:16:"totalcostprCCstm";a:1:{s:2:"en";s:18:"Total Project Cost";}s:6:"amount";a:1:{s:2:"en";s:18:"Total Project Cost";}s:5:"stage";a:1:{s:2:"en";s:5:"Stage";}s:10:"rampupCstm";a:1:{s:2:"en";s:7:"Ramp up";}s:9:"closeDate";a:1:{s:2:"en";s:10:"Close Date";}}}'),
(16, 'OpportunityEditAndDetailsView', 'a:5:{s:7:"toolbar";a:1:{s:8:"elements";a:6:{i:0;a:2:{s:4:"type";s:10:"SaveButton";s:10:"renderType";s:4:"Edit";}i:1;a:2:{s:4:"type";s:10:"CancelLink";s:10:"renderType";s:4:"Edit";}i:2;a:2:{s:4:"type";s:8:"EditLink";s:10:"renderType";s:7:"Details";}i:3;a:2:{s:4:"type";s:24:"AuditEventsModalListLink";s:10:"renderType";s:7:"Details";}i:4;a:2:{s:4:"type";s:8:"CopyLink";s:10:"renderType";s:7:"Details";}i:5;a:2:{s:4:"type";s:21:"OpportunityDeleteLink";s:10:"renderType";s:7:"Details";}}}s:21:"derivedAttributeTypes";a:0:{}s:26:"nonPlaceableAttributeNames";a:1:{i:0;s:5:"owner";}s:17:"panelsDisplayType";i:1;s:6:"panels";a:1:{i:0;a:2:{s:5:"title";s:0:"";s:4:"rows";a:14:{i:0;a:1:{s:5:"cells";a:1:{i:0;a:1:{s:8:"elements";a:1:{i:0;a:2:{s:13:"attributeName";s:4:"name";s:4:"type";s:4:"Text";}}}}}i:1;a:1:{s:5:"cells";a:2:{i:0;a:1:{s:8:"elements";a:1:{i:0;a:3:{s:13:"attributeName";s:5:"stage";s:4:"type";s:8:"DropDown";s:8:"addBlank";b:1;}}}i:1;a:1:{s:8:"elements";a:1:{i:0;a:2:{s:13:"attributeName";s:11:"probability";s:4:"type";s:7:"Integer";}}}}}i:2;a:1:{s:5:"cells";a:1:{i:0;a:1:{s:8:"elements";a:1:{i:0;a:3:{s:13:"attributeName";s:16:"bulkservprCsCstm";s:4:"type";s:19:"MultiSelectDropDown";s:8:"addBlank";b:1;}}}}}i:3;a:1:{s:5:"cells";a:1:{i:0;a:1:{s:8:"elements";a:1:{i:0;a:2:{s:13:"attributeName";s:16:"proposedinfCCstm";s:4:"type";s:4:"Text";}}}}}i:4;a:1:{s:5:"cells";a:1:{i:0;a:1:{s:8:"elements";a:1:{i:0;a:3:{s:13:"attributeName";s:16:"contractlengCstm";s:4:"type";s:8:"DropDown";s:8:"addBlank";b:1;}}}}}i:5;a:1:{s:5:"cells";a:2:{i:0;a:1:{s:8:"elements";a:1:{i:0;a:2:{s:13:"attributeName";s:16:"vidpricingCsCstm";s:4:"type";s:13:"CurrencyValue";}}}i:1;a:1:{s:8:"elements";a:1:{i:0;a:2:{s:13:"attributeName";s:16:"internetbulkCstm";s:4:"type";s:13:"CurrencyValue";}}}}}i:6;a:1:{s:5:"cells";a:2:{i:0;a:1:{s:8:"elements";a:1:{i:0;a:2:{s:13:"attributeName";s:16:"phonebulkCstCstm";s:4:"type";s:13:"CurrencyValue";}}}i:1;a:1:{s:8:"elements";a:1:{i:0;a:2:{s:13:"attributeName";s:16:"alarmbulkCstCstm";s:4:"type";s:13:"CurrencyValue";}}}}}i:7;a:1:{s:5:"cells";a:1:{i:0;a:1:{s:8:"elements";a:1:{i:0;a:2:{s:13:"attributeName";s:16:"totalbulkpriCstm";s:4:"type";s:13:"CurrencyValue";}}}}}i:8;a:1:{s:5:"cells";a:1:{i:0;a:1:{s:8:"elements";a:1:{i:0;a:2:{s:13:"attributeName";s:12:"tprmonreCstm";s:4:"type";s:13:"CurrencyValue";}}}}}i:9;a:1:{s:5:"cells";a:1:{i:0;a:1:{s:8:"elements";a:1:{i:0;a:3:{s:13:"attributeName";s:16:"consrequestCCstm";s:4:"type";s:8:"DropDown";s:8:"addBlank";b:1;}}}}}i:10;a:1:{s:5:"cells";a:1:{i:0;a:1:{s:8:"elements";a:1:{i:0;a:2:{s:13:"attributeName";s:16:"constructcosCstm";s:4:"type";s:13:"CurrencyValue";}}}}}i:11;a:1:{s:5:"cells";a:1:{i:0;a:1:{s:8:"elements";a:1:{i:0;a:2:{s:13:"attributeName";s:6:"amount";s:4:"type";s:13:"CurrencyValue";}}}}}i:12;a:1:{s:5:"cells";a:1:{i:0;a:1:{s:8:"elements";a:1:{i:0;a:3:{s:13:"attributeName";s:10:"rampupCstm";s:4:"type";s:8:"DropDown";s:8:"addBlank";b:1;}}}}}i:13;a:1:{s:5:"cells";a:1:{i:0;a:1:{s:8:"elements";a:1:{i:0;a:2:{s:13:"attributeName";s:9:"closeDate";s:4:"type";s:4:"Date";}}}}}}}}}'),
(17, 'OpportunitiesModule', 'a:7:{s:17:"designerMenuItems";a:4:{s:14:"showFieldsLink";b:1;s:15:"showGeneralLink";b:1;s:15:"showLayoutsLink";b:1;s:13:"showMenusLink";b:1;}s:26:"globalSearchAttributeNames";a:1:{i:0;s:4:"name";}s:25:"stageToProbabilityMapping";a:6:{s:11:"Prospecting";i:10;s:13:"Qualification";i:25;s:11:"Negotiating";i:50;s:6:"Verbal";i:75;s:10:"Closed Won";i:100;s:11:"Closed Lost";i:0;}s:35:"automaticProbabilityMappingDisabled";b:0;s:12:"tabMenuItems";a:1:{i:0;a:4:{s:5:"label";s:90:"eval:Zurmo::t(''OpportunitiesModule'', ''OpportunitiesModulePluralLabel'', $translationParams)";s:3:"url";a:1:{i:0;s:22:"/opportunities/default";}s:5:"right";s:24:"Access Opportunities Tab";s:6:"mobile";b:1;}}s:24:"shortcutsCreateMenuItems";a:1:{i:0;a:4:{s:5:"label";s:92:"eval:Zurmo::t(''OpportunitiesModule'', ''OpportunitiesModuleSingularLabel'', $translationParams)";s:3:"url";a:1:{i:0;s:29:"/opportunities/default/create";}s:5:"right";s:20:"Create Opportunities";s:6:"mobile";b:1;}}s:61:"OpportunityEditAndDetailsView_layoutMissingRequiredAttributes";N;}'),
(18, 'ContractsForOpportunityRelatedListView', 'a:4:{s:7:"toolbar";a:1:{s:8:"elements";a:1:{i:0;a:3:{s:4:"type";s:25:"CreateFromRelatedListLink";s:13:"routeModuleId";s:20:"eval:$this->moduleId";s:15:"routeParameters";s:42:"eval:$this->getCreateLinkRouteParameters()";}}}s:7:"rowMenu";a:1:{s:8:"elements";a:3:{i:0;a:1:{s:4:"type";s:8:"EditLink";}i:1;a:1:{s:4:"type";s:17:"RelatedDeleteLink";}i:2;a:5:{s:4:"type";s:13:"RelatedUnlink";s:22:"relationModelClassName";s:46:"eval:get_class($this->params["relationModel"])";s:15:"relationModelId";s:39:"eval:$this->params["relationModel"]->id";s:25:"relationModelRelationName";s:9:"contracts";s:25:"userHasRelatedModelAccess";s:93:"eval:ActionSecurityUtil::canCurrentUserPerformAction( "Edit", $this->params["relationModel"])";}}}s:12:"gridViewType";i:2;s:6:"panels";a:1:{i:0;a:1:{s:4:"rows";a:4:{i:0;a:1:{s:5:"cells";a:1:{i:0;a:1:{s:8:"elements";a:1:{i:0;a:3:{s:13:"attributeName";s:4:"name";s:4:"type";s:4:"Text";s:6:"isLink";b:1;}}}}}i:1;a:1:{s:5:"cells";a:1:{i:0;a:1:{s:8:"elements";a:1:{i:0;a:2:{s:13:"attributeName";s:16:"monthlynetCsCstm";s:4:"type";s:13:"CurrencyValue";}}}}}i:2;a:1:{s:5:"cells";a:1:{i:0;a:1:{s:8:"elements";a:1:{i:0;a:2:{s:13:"attributeName";s:5:"stage";s:4:"type";s:8:"DropDown";}}}}}i:3;a:1:{s:5:"cells";a:1:{i:0;a:1:{s:8:"elements";a:1:{i:0;a:2:{s:13:"attributeName";s:9:"closeDate";s:4:"type";s:4:"Date";}}}}}}}}}'),
(19, 'ContractsMassEditView', 'a:4:{s:7:"toolbar";a:1:{s:8:"elements";a:2:{i:0;a:1:{s:4:"type";s:10:"SaveButton";}i:1;a:1:{s:4:"type";s:10:"CancelLink";}}}s:26:"nonPlaceableAttributeNames";a:2:{i:0;s:4:"name";i:1;s:11:"probability";}s:17:"panelsDisplayType";i:1;s:6:"panels";a:1:{i:0;a:1:{s:4:"rows";a:4:{i:0;a:1:{s:5:"cells";a:1:{i:0;a:1:{s:8:"elements";a:1:{i:0;a:3:{s:13:"attributeName";s:16:"contractTypeCstm";s:4:"type";s:8:"DropDown";s:8:"addBlank";b:1;}}}}}i:1;a:1:{s:5:"cells";a:1:{i:0;a:1:{s:8:"elements";a:1:{i:0;a:3:{s:13:"attributeName";s:5:"stage";s:4:"type";s:8:"DropDown";s:8:"addBlank";b:1;}}}}}i:2;a:1:{s:5:"cells";a:1:{i:0;a:1:{s:8:"elements";a:1:{i:0;a:3:{s:13:"attributeName";s:6:"source";s:4:"type";s:8:"DropDown";s:8:"addBlank";b:1;}}}}}i:3;a:1:{s:5:"cells";a:1:{i:0;a:1:{s:8:"elements";a:1:{i:0;a:2:{s:13:"attributeName";s:9:"closeDate";s:4:"type";s:4:"Date";}}}}}}}}}'),
(20, 'OpportunitiesMassEditView', 'a:4:{s:7:"toolbar";a:1:{s:8:"elements";a:2:{i:0;a:1:{s:4:"type";s:10:"SaveButton";}i:1;a:1:{s:4:"type";s:10:"CancelLink";}}}s:26:"nonPlaceableAttributeNames";a:2:{i:0;s:4:"name";i:1;s:11:"probability";}s:17:"panelsDisplayType";i:1;s:6:"panels";a:1:{i:0;a:1:{s:4:"rows";a:6:{i:0;a:1:{s:5:"cells";a:1:{i:0;a:1:{s:8:"elements";a:1:{i:0;a:2:{s:13:"attributeName";s:5:"owner";s:4:"type";s:4:"User";}}}}}i:1;a:1:{s:5:"cells";a:1:{i:0;a:1:{s:8:"elements";a:1:{i:0;a:3:{s:13:"attributeName";s:5:"stage";s:4:"type";s:8:"DropDown";s:8:"addBlank";b:1;}}}}}i:2;a:1:{s:5:"cells";a:1:{i:0;a:1:{s:8:"elements";a:1:{i:0;a:3:{s:13:"attributeName";s:6:"source";s:4:"type";s:8:"DropDown";s:8:"addBlank";b:1;}}}}}i:3;a:1:{s:5:"cells";a:1:{i:0;a:1:{s:8:"elements";a:1:{i:0;a:2:{s:13:"attributeName";s:9:"closeDate";s:4:"type";s:4:"Date";}}}}}i:4;a:1:{s:5:"cells";a:1:{i:0;a:1:{s:8:"elements";a:1:{i:0;a:3:{s:13:"attributeName";s:16:"contractlengCstm";s:4:"type";s:8:"DropDown";s:8:"addBlank";b:1;}}}}}i:5;a:1:{s:5:"cells";a:1:{i:0;a:1:{s:8:"elements";a:1:{i:0;a:3:{s:13:"attributeName";s:10:"rampupCstm";s:4:"type";s:8:"DropDown";s:8:"addBlank";b:1;}}}}}}}}}'),
(21, 'ContractsListView', 'a:1:{s:6:"panels";a:1:{i:0;a:1:{s:4:"rows";a:4:{i:0;a:1:{s:5:"cells";a:1:{i:0;a:1:{s:8:"elements";a:1:{i:0;a:3:{s:13:"attributeName";s:4:"name";s:4:"type";s:4:"Text";s:6:"isLink";b:1;}}}}}i:1;a:1:{s:5:"cells";a:1:{i:0;a:1:{s:8:"elements";a:1:{i:0;a:2:{s:13:"attributeName";s:16:"contractTypeCstm";s:4:"type";s:8:"DropDown";}}}}}i:2;a:1:{s:5:"cells";a:1:{i:0;a:1:{s:8:"elements";a:1:{i:0;a:2:{s:13:"attributeName";s:9:"closeDate";s:4:"type";s:4:"Date";}}}}}i:3;a:1:{s:5:"cells";a:1:{i:0;a:1:{s:8:"elements";a:1:{i:0;a:2:{s:13:"attributeName";s:5:"owner";s:4:"type";s:4:"User";}}}}}}}}}');

-- --------------------------------------------------------

--
-- Table structure for table `imagefilemodel`
--

CREATE TABLE IF NOT EXISTS `imagefilemodel` (
`id` int(11) unsigned NOT NULL,
  `isshared` tinyint(1) unsigned DEFAULT NULL,
  `width` int(11) DEFAULT NULL,
  `height` int(11) DEFAULT NULL,
  `inactive` tinyint(1) unsigned DEFAULT NULL,
  `filemodel_id` int(11) unsigned DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `import`
--

CREATE TABLE IF NOT EXISTS `import` (
`id` int(11) unsigned NOT NULL,
  `item_id` int(11) unsigned DEFAULT NULL,
  `serializeddata` text COLLATE utf8_unicode_ci
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

--
-- Dumping data for table `import`
--

INSERT INTO `import` (`id`, `item_id`, `serializeddata`) VALUES
(1, 638, 'a:7:{s:15:"importRulesType";s:8:"Accounts";s:14:"fileUploadData";a:3:{s:4:"name";s:19:"Accounts Import.csv";s:4:"type";s:24:"application/vnd.ms-excel";s:4:"size";i:1327;}s:18:"rowColumnDelimiter";s:1:",";s:18:"rowColumnEnclosure";s:1:""";s:19:"firstRowIsHeaderRow";s:1:"1";s:11:"mappingData";a:3:{s:8:"column_0";a:3:{s:27:"attributeIndexOrDerivedType";s:4:"name";s:4:"type";s:12:"importColumn";s:16:"mappingRulesData";a:2:{s:41:"DefaultValueModelAttributeMappingRuleForm";a:1:{s:12:"defaultValue";s:0:"";}s:39:"NameModelAttributeDedupeMappingRuleForm";a:1:{s:10:"dedupeRule";a:1:{s:5:"value";s:1:"1";}}}}s:8:"column_1";a:3:{s:27:"attributeIndexOrDerivedType";s:13:"unitsCstmCstm";s:4:"type";s:12:"importColumn";s:16:"mappingRulesData";a:1:{s:41:"DefaultValueModelAttributeMappingRuleForm";a:1:{s:12:"defaultValue";s:0:"";}}}s:8:"column_2";a:3:{s:27:"attributeIndexOrDerivedType";s:15:"comtypeCstmCstm";s:4:"type";s:11:"extraColumn";s:16:"mappingRulesData";a:1:{s:49:"DefaultValueDropDownModelAttributeMappingRuleForm";a:1:{s:12:"defaultValue";s:14:"Low Rise Condo";}}}}s:33:"explicitReadWriteModelPermissions";N;}'),
(2, 701, 'a:7:{s:15:"importRulesType";s:13:"Opportunities";s:14:"fileUploadData";a:3:{s:4:"name";s:17:"opportunities.csv";s:4:"type";s:24:"application/vnd.ms-excel";s:4:"size";i:7169;}s:18:"rowColumnDelimiter";s:1:",";s:18:"rowColumnEnclosure";s:1:""";s:19:"firstRowIsHeaderRow";s:1:"1";s:11:"mappingData";a:35:{s:8:"column_0";a:3:{s:27:"attributeIndexOrDerivedType";s:0:"";s:4:"type";s:12:"importColumn";s:16:"mappingRulesData";a:0:{}}s:8:"column_1";a:3:{s:27:"attributeIndexOrDerivedType";s:0:"";s:4:"type";s:12:"importColumn";s:16:"mappingRulesData";a:0:{}}s:8:"column_2";a:3:{s:27:"attributeIndexOrDerivedType";s:0:"";s:4:"type";s:12:"importColumn";s:16:"mappingRulesData";a:0:{}}s:8:"column_3";a:3:{s:27:"attributeIndexOrDerivedType";s:0:"";s:4:"type";s:12:"importColumn";s:16:"mappingRulesData";a:0:{}}s:8:"column_4";a:3:{s:27:"attributeIndexOrDerivedType";s:0:"";s:4:"type";s:12:"importColumn";s:16:"mappingRulesData";a:0:{}}s:8:"column_5";a:3:{s:27:"attributeIndexOrDerivedType";s:0:"";s:4:"type";s:12:"importColumn";s:16:"mappingRulesData";a:0:{}}s:8:"column_6";a:3:{s:27:"attributeIndexOrDerivedType";s:9:"closeDate";s:4:"type";s:12:"importColumn";s:16:"mappingRulesData";a:2:{s:41:"DefaultValueModelAttributeMappingRuleForm";a:1:{s:12:"defaultValue";s:10:"2016-01-01";}s:26:"ValueFormatMappingRuleForm";a:1:{s:6:"format";s:10:"yyyy-MM-dd";}}}s:8:"column_7";a:3:{s:27:"attributeIndexOrDerivedType";s:0:"";s:4:"type";s:12:"importColumn";s:16:"mappingRulesData";a:0:{}}s:8:"column_8";a:3:{s:27:"attributeIndexOrDerivedType";s:4:"name";s:4:"type";s:12:"importColumn";s:16:"mappingRulesData";a:2:{s:41:"DefaultValueModelAttributeMappingRuleForm";a:1:{s:12:"defaultValue";s:0:"";}s:39:"NameModelAttributeDedupeMappingRuleForm";a:1:{s:10:"dedupeRule";a:1:{s:5:"value";s:1:"1";}}}}s:8:"column_9";a:3:{s:27:"attributeIndexOrDerivedType";s:0:"";s:4:"type";s:12:"importColumn";s:16:"mappingRulesData";a:0:{}}s:9:"column_10";a:3:{s:27:"attributeIndexOrDerivedType";s:0:"";s:4:"type";s:12:"importColumn";s:16:"mappingRulesData";a:0:{}}s:9:"column_11";a:3:{s:27:"attributeIndexOrDerivedType";s:7:"account";s:4:"type";s:12:"importColumn";s:16:"mappingRulesData";a:2:{s:33:"DefaultModelNameIdMappingRuleForm";a:2:{s:14:"defaultModelId";s:0:"";s:27:"defaultModelStringifiedName";s:0:"";}s:36:"RelatedModelValueTypeMappingRuleForm";a:1:{s:4:"type";s:1:"1";}}}s:9:"column_12";a:3:{s:27:"attributeIndexOrDerivedType";s:0:"";s:4:"type";s:12:"importColumn";s:16:"mappingRulesData";a:0:{}}s:9:"column_13";a:3:{s:27:"attributeIndexOrDerivedType";s:0:"";s:4:"type";s:12:"importColumn";s:16:"mappingRulesData";a:0:{}}s:9:"column_14";a:3:{s:27:"attributeIndexOrDerivedType";s:5:"stage";s:4:"type";s:12:"importColumn";s:16:"mappingRulesData";a:1:{s:49:"DefaultValueDropDownModelAttributeMappingRuleForm";a:1:{s:12:"defaultValue";s:0:"";}}}s:9:"column_15";a:3:{s:27:"attributeIndexOrDerivedType";s:0:"";s:4:"type";s:12:"importColumn";s:16:"mappingRulesData";a:0:{}}s:9:"column_16";a:3:{s:27:"attributeIndexOrDerivedType";s:0:"";s:4:"type";s:12:"importColumn";s:16:"mappingRulesData";a:0:{}}s:9:"column_17";a:3:{s:27:"attributeIndexOrDerivedType";s:0:"";s:4:"type";s:12:"importColumn";s:16:"mappingRulesData";a:0:{}}s:9:"column_18";a:3:{s:27:"attributeIndexOrDerivedType";s:0:"";s:4:"type";s:12:"importColumn";s:16:"mappingRulesData";a:0:{}}s:9:"column_19";a:3:{s:27:"attributeIndexOrDerivedType";s:0:"";s:4:"type";s:12:"importColumn";s:16:"mappingRulesData";a:0:{}}s:9:"column_20";a:3:{s:27:"attributeIndexOrDerivedType";s:0:"";s:4:"type";s:12:"importColumn";s:16:"mappingRulesData";a:0:{}}s:9:"column_21";a:3:{s:27:"attributeIndexOrDerivedType";s:0:"";s:4:"type";s:12:"importColumn";s:16:"mappingRulesData";a:0:{}}s:9:"column_22";a:3:{s:27:"attributeIndexOrDerivedType";s:0:"";s:4:"type";s:12:"importColumn";s:16:"mappingRulesData";a:0:{}}s:9:"column_23";a:3:{s:27:"attributeIndexOrDerivedType";s:0:"";s:4:"type";s:12:"importColumn";s:16:"mappingRulesData";a:0:{}}s:9:"column_24";a:3:{s:27:"attributeIndexOrDerivedType";s:0:"";s:4:"type";s:12:"importColumn";s:16:"mappingRulesData";a:0:{}}s:9:"column_25";a:3:{s:27:"attributeIndexOrDerivedType";s:0:"";s:4:"type";s:12:"importColumn";s:16:"mappingRulesData";a:0:{}}s:9:"column_26";a:3:{s:27:"attributeIndexOrDerivedType";s:0:"";s:4:"type";s:12:"importColumn";s:16:"mappingRulesData";a:0:{}}s:9:"column_27";a:3:{s:27:"attributeIndexOrDerivedType";s:0:"";s:4:"type";s:12:"importColumn";s:16:"mappingRulesData";a:0:{}}s:9:"column_28";a:3:{s:27:"attributeIndexOrDerivedType";s:0:"";s:4:"type";s:12:"importColumn";s:16:"mappingRulesData";a:0:{}}s:9:"column_29";a:3:{s:27:"attributeIndexOrDerivedType";s:12:"tprmonreCstm";s:4:"type";s:12:"importColumn";s:16:"mappingRulesData";a:3:{s:41:"DefaultValueModelAttributeMappingRuleForm";a:1:{s:12:"defaultValue";s:1:"1";}s:39:"CurrencyIdModelAttributeMappingRuleForm";a:1:{s:2:"id";s:1:"1";}s:47:"CurrencyRateToBaseModelAttributeMappingRuleForm";a:1:{s:10:"rateToBase";s:1:"1";}}}s:9:"column_30";a:3:{s:27:"attributeIndexOrDerivedType";s:0:"";s:4:"type";s:12:"importColumn";s:16:"mappingRulesData";a:0:{}}s:9:"column_31";a:3:{s:27:"attributeIndexOrDerivedType";s:0:"";s:4:"type";s:12:"importColumn";s:16:"mappingRulesData";a:0:{}}s:9:"column_32";a:3:{s:27:"attributeIndexOrDerivedType";s:0:"";s:4:"type";s:12:"importColumn";s:16:"mappingRulesData";a:0:{}}s:9:"column_33";a:3:{s:27:"attributeIndexOrDerivedType";s:6:"amount";s:4:"type";s:12:"importColumn";s:16:"mappingRulesData";a:3:{s:41:"DefaultValueModelAttributeMappingRuleForm";a:1:{s:12:"defaultValue";s:1:"1";}s:39:"CurrencyIdModelAttributeMappingRuleForm";a:1:{s:2:"id";s:1:"1";}s:47:"CurrencyRateToBaseModelAttributeMappingRuleForm";a:1:{s:10:"rateToBase";s:1:"1";}}}s:9:"column_34";a:3:{s:27:"attributeIndexOrDerivedType";s:0:"";s:4:"type";s:12:"importColumn";s:16:"mappingRulesData";a:0:{}}}s:33:"explicitReadWriteModelPermissions";N;}'),
(3, 761, 'a:7:{s:15:"importRulesType";s:9:"Contracts";s:14:"fileUploadData";a:3:{s:4:"name";s:80:"HOW INFORMATION MUST BE IMPORTED IN AND THE DIFFERENT REPORTS MUST BE PULLED.csv";s:4:"type";s:24:"application/vnd.ms-excel";s:4:"size";i:10343;}s:18:"rowColumnDelimiter";s:1:",";s:18:"rowColumnEnclosure";s:1:""";s:19:"firstRowIsHeaderRow";s:1:"1";s:11:"mappingData";a:23:{s:8:"column_0";a:3:{s:27:"attributeIndexOrDerivedType";s:4:"name";s:4:"type";s:12:"importColumn";s:16:"mappingRulesData";a:2:{s:41:"DefaultValueModelAttributeMappingRuleForm";a:1:{s:12:"defaultValue";s:0:"";}s:39:"NameModelAttributeDedupeMappingRuleForm";a:1:{s:10:"dedupeRule";a:1:{s:5:"value";s:1:"1";}}}}s:8:"column_1";a:3:{s:27:"attributeIndexOrDerivedType";s:0:"";s:4:"type";s:12:"importColumn";s:16:"mappingRulesData";a:0:{}}s:8:"column_2";a:3:{s:27:"attributeIndexOrDerivedType";s:0:"";s:4:"type";s:12:"importColumn";s:16:"mappingRulesData";a:0:{}}s:8:"column_3";a:3:{s:27:"attributeIndexOrDerivedType";s:0:"";s:4:"type";s:12:"importColumn";s:16:"mappingRulesData";a:0:{}}s:8:"column_4";a:3:{s:27:"attributeIndexOrDerivedType";s:0:"";s:4:"type";s:12:"importColumn";s:16:"mappingRulesData";a:0:{}}s:8:"column_5";a:3:{s:27:"attributeIndexOrDerivedType";s:0:"";s:4:"type";s:12:"importColumn";s:16:"mappingRulesData";a:0:{}}s:8:"column_6";a:3:{s:27:"attributeIndexOrDerivedType";s:0:"";s:4:"type";s:12:"importColumn";s:16:"mappingRulesData";a:0:{}}s:8:"column_7";a:3:{s:27:"attributeIndexOrDerivedType";s:0:"";s:4:"type";s:12:"importColumn";s:16:"mappingRulesData";a:0:{}}s:8:"column_8";a:3:{s:27:"attributeIndexOrDerivedType";s:15:"blendedbulkCstm";s:4:"type";s:12:"importColumn";s:16:"mappingRulesData";a:1:{s:41:"DefaultValueModelAttributeMappingRuleForm";a:1:{s:12:"defaultValue";s:0:"";}}}s:8:"column_9";a:3:{s:27:"attributeIndexOrDerivedType";s:0:"";s:4:"type";s:12:"importColumn";s:16:"mappingRulesData";a:0:{}}s:9:"column_10";a:3:{s:27:"attributeIndexOrDerivedType";s:0:"";s:4:"type";s:12:"importColumn";s:16:"mappingRulesData";a:0:{}}s:9:"column_11";a:3:{s:27:"attributeIndexOrDerivedType";s:0:"";s:4:"type";s:12:"importColumn";s:16:"mappingRulesData";a:0:{}}s:9:"column_12";a:3:{s:27:"attributeIndexOrDerivedType";s:0:"";s:4:"type";s:12:"importColumn";s:16:"mappingRulesData";a:0:{}}s:9:"column_13";a:3:{s:27:"attributeIndexOrDerivedType";s:11:"roiCstmCstm";s:4:"type";s:12:"importColumn";s:16:"mappingRulesData";a:1:{s:41:"DefaultValueModelAttributeMappingRuleForm";a:1:{s:12:"defaultValue";s:0:"";}}}s:9:"column_14";a:3:{s:27:"attributeIndexOrDerivedType";s:0:"";s:4:"type";s:12:"importColumn";s:16:"mappingRulesData";a:0:{}}s:9:"column_15";a:3:{s:27:"attributeIndexOrDerivedType";s:0:"";s:4:"type";s:12:"importColumn";s:16:"mappingRulesData";a:0:{}}s:9:"column_16";a:3:{s:27:"attributeIndexOrDerivedType";s:0:"";s:4:"type";s:12:"importColumn";s:16:"mappingRulesData";a:0:{}}s:9:"column_17";a:3:{s:27:"attributeIndexOrDerivedType";s:0:"";s:4:"type";s:12:"importColumn";s:16:"mappingRulesData";a:0:{}}s:9:"column_18";a:3:{s:27:"attributeIndexOrDerivedType";s:16:"monthlynetCsCstm";s:4:"type";s:11:"extraColumn";s:16:"mappingRulesData";a:3:{s:41:"DefaultValueModelAttributeMappingRuleForm";a:1:{s:12:"defaultValue";s:3:"100";}s:39:"CurrencyIdModelAttributeMappingRuleForm";a:1:{s:2:"id";s:1:"1";}s:47:"CurrencyRateToBaseModelAttributeMappingRuleForm";a:1:{s:10:"rateToBase";s:1:"1";}}}s:9:"column_19";a:3:{s:27:"attributeIndexOrDerivedType";s:15:"doorfeeCstmCstm";s:4:"type";s:11:"extraColumn";s:16:"mappingRulesData";a:3:{s:41:"DefaultValueModelAttributeMappingRuleForm";a:1:{s:12:"defaultValue";s:3:"100";}s:39:"CurrencyIdModelAttributeMappingRuleForm";a:1:{s:2:"id";s:1:"1";}s:47:"CurrencyRateToBaseModelAttributeMappingRuleForm";a:1:{s:10:"rateToBase";s:1:"1";}}}s:9:"column_20";a:3:{s:27:"attributeIndexOrDerivedType";s:6:"amount";s:4:"type";s:11:"extraColumn";s:16:"mappingRulesData";a:3:{s:41:"DefaultValueModelAttributeMappingRuleForm";a:1:{s:12:"defaultValue";s:3:"100";}s:39:"CurrencyIdModelAttributeMappingRuleForm";a:1:{s:2:"id";s:1:"1";}s:47:"CurrencyRateToBaseModelAttributeMappingRuleForm";a:1:{s:10:"rateToBase";s:1:"1";}}}s:9:"column_21";a:3:{s:27:"attributeIndexOrDerivedType";s:16:"propbillCstmCstm";s:4:"type";s:11:"extraColumn";s:16:"mappingRulesData";a:1:{s:41:"DefaultValueModelAttributeMappingRuleForm";a:1:{s:12:"defaultValue";s:10:"2016-01-01";}}}s:9:"column_22";a:3:{s:27:"attributeIndexOrDerivedType";s:9:"closeDate";s:4:"type";s:11:"extraColumn";s:16:"mappingRulesData";a:1:{s:41:"DefaultValueModelAttributeMappingRuleForm";a:1:{s:12:"defaultValue";s:10:"2016-01-01";}}}}s:33:"explicitReadWriteModelPermissions";N;}'),
(4, 764, 'a:7:{s:15:"importRulesType";s:9:"Contracts";s:14:"fileUploadData";a:3:{s:4:"name";s:13:"Contracts.csv";s:4:"type";s:24:"application/vnd.ms-excel";s:4:"size";i:1898;}s:18:"rowColumnDelimiter";s:1:",";s:18:"rowColumnEnclosure";s:1:""";s:19:"firstRowIsHeaderRow";s:1:"1";s:11:"mappingData";a:9:{s:8:"column_0";a:3:{s:27:"attributeIndexOrDerivedType";s:4:"name";s:4:"type";s:12:"importColumn";s:16:"mappingRulesData";a:2:{s:41:"DefaultValueModelAttributeMappingRuleForm";a:1:{s:12:"defaultValue";s:0:"";}s:39:"NameModelAttributeDedupeMappingRuleForm";a:1:{s:10:"dedupeRule";a:1:{s:5:"value";s:1:"1";}}}}s:8:"column_1";a:3:{s:27:"attributeIndexOrDerivedType";s:16:"propbillCstmCstm";s:4:"type";s:11:"extraColumn";s:16:"mappingRulesData";a:1:{s:41:"DefaultValueModelAttributeMappingRuleForm";a:1:{s:12:"defaultValue";s:10:"2016-01-01";}}}s:8:"column_2";a:3:{s:27:"attributeIndexOrDerivedType";s:9:"closeDate";s:4:"type";s:11:"extraColumn";s:16:"mappingRulesData";a:1:{s:41:"DefaultValueModelAttributeMappingRuleForm";a:1:{s:12:"defaultValue";s:10:"2016-01-01";}}}s:8:"column_3";a:3:{s:27:"attributeIndexOrDerivedType";s:15:"blendedbulkCstm";s:4:"type";s:11:"extraColumn";s:16:"mappingRulesData";a:1:{s:41:"DefaultValueModelAttributeMappingRuleForm";a:1:{s:12:"defaultValue";s:3:"100";}}}s:8:"column_4";a:3:{s:27:"attributeIndexOrDerivedType";s:11:"roiCstmCstm";s:4:"type";s:11:"extraColumn";s:16:"mappingRulesData";a:1:{s:41:"DefaultValueModelAttributeMappingRuleForm";a:1:{s:12:"defaultValue";s:2:"10";}}}s:8:"column_5";a:3:{s:27:"attributeIndexOrDerivedType";s:6:"amount";s:4:"type";s:11:"extraColumn";s:16:"mappingRulesData";a:3:{s:41:"DefaultValueModelAttributeMappingRuleForm";a:1:{s:12:"defaultValue";s:2:"10";}s:39:"CurrencyIdModelAttributeMappingRuleForm";a:1:{s:2:"id";s:1:"1";}s:47:"CurrencyRateToBaseModelAttributeMappingRuleForm";a:1:{s:10:"rateToBase";s:1:"1";}}}s:8:"column_6";a:3:{s:27:"attributeIndexOrDerivedType";s:0:"";s:4:"type";s:11:"extraColumn";s:16:"mappingRulesData";a:0:{}}s:8:"column_7";a:3:{s:27:"attributeIndexOrDerivedType";s:16:"monthlynetCsCstm";s:4:"type";s:11:"extraColumn";s:16:"mappingRulesData";a:3:{s:41:"DefaultValueModelAttributeMappingRuleForm";a:1:{s:12:"defaultValue";s:3:"100";}s:39:"CurrencyIdModelAttributeMappingRuleForm";a:1:{s:2:"id";s:1:"1";}s:47:"CurrencyRateToBaseModelAttributeMappingRuleForm";a:1:{s:10:"rateToBase";s:1:"1";}}}s:8:"column_8";a:3:{s:27:"attributeIndexOrDerivedType";s:15:"doorfeeCstmCstm";s:4:"type";s:11:"extraColumn";s:16:"mappingRulesData";a:3:{s:41:"DefaultValueModelAttributeMappingRuleForm";a:1:{s:12:"defaultValue";s:2:"10";}s:39:"CurrencyIdModelAttributeMappingRuleForm";a:1:{s:2:"id";s:1:"4";}s:47:"CurrencyRateToBaseModelAttributeMappingRuleForm";a:1:{s:10:"rateToBase";s:1:"1";}}}}s:33:"explicitReadWriteModelPermissions";N;}');

-- --------------------------------------------------------

--
-- Table structure for table `importtable1`
--

CREATE TABLE IF NOT EXISTS `importtable1` (
`id` int(11) unsigned NOT NULL,
  `column_0` varchar(48) COLLATE utf8_unicode_ci DEFAULT NULL,
  `column_1` varchar(5) COLLATE utf8_unicode_ci DEFAULT NULL,
  `status` int(11) unsigned DEFAULT NULL,
  `serializedMessages` text COLLATE utf8_unicode_ci,
  `analysisStatus` int(11) unsigned DEFAULT NULL,
  `serializedAnalysisMessages` text COLLATE utf8_unicode_ci
) ENGINE=InnoDB AUTO_INCREMENT=60 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

--
-- Dumping data for table `importtable1`
--

INSERT INTO `importtable1` (`id`, `column_0`, `column_1`, `status`, `serializedMessages`, `analysisStatus`, `serializedAnalysisMessages`) VALUES
(1, 'Name', 'Units', NULL, NULL, NULL, NULL),
(2, 'Strada 315 (Video)', '117', 2, 'a:1:{i:0;s:149:"Account saved correctly: <a class="simple-link" target="blank" href="/opticaltel/app/index.php/accounts/default/details?id=13">Strada 315 (Video)</a>";}', 1, NULL),
(3, 'Strada 315 (Data)', '117', 2, 'a:1:{i:0;s:148:"Account saved correctly: <a class="simple-link" target="blank" href="/opticaltel/app/index.php/accounts/default/details?id=14">Strada 315 (Data)</a>";}', 1, NULL),
(4, 'Sunset Bay (Data)', '308', 2, 'a:1:{i:0;s:148:"Account saved correctly: <a class="simple-link" target="blank" href="/opticaltel/app/index.php/accounts/default/details?id=15">Sunset Bay (Data)</a>";}', 1, NULL),
(5, 'Sunset Bay (Video)', '308', 2, 'a:1:{i:0;s:149:"Account saved correctly: <a class="simple-link" target="blank" href="/opticaltel/app/index.php/accounts/default/details?id=16">Sunset Bay (Video)</a>";}', 1, NULL),
(6, 'Cypress Trails', '364', 2, 'a:1:{i:0;s:145:"Account saved correctly: <a class="simple-link" target="blank" href="/opticaltel/app/index.php/accounts/default/details?id=17">Cypress Trails</a>";}', 1, NULL),
(7, 'Isles at Grand Bay', '2000', 2, 'a:1:{i:0;s:149:"Account saved correctly: <a class="simple-link" target="blank" href="/opticaltel/app/index.php/accounts/default/details?id=18">Isles at Grand Bay</a>";}', 1, NULL),
(8, 'The Summit (Net)', '567', 2, 'a:1:{i:0;s:147:"Account saved correctly: <a class="simple-link" target="blank" href="/opticaltel/app/index.php/accounts/default/details?id=19">The Summit (Net)</a>";}', 1, NULL),
(9, 'Key Largo', '285', 2, 'a:1:{i:0;s:140:"Account saved correctly: <a class="simple-link" target="blank" href="/opticaltel/app/index.php/accounts/default/details?id=20">Key Largo</a>";}', 1, NULL),
(10, 'Garden Estates (Net)', '445', 2, 'a:1:{i:0;s:151:"Account saved correctly: <a class="simple-link" target="blank" href="/opticaltel/app/index.php/accounts/default/details?id=21">Garden Estates (Net)</a>";}', 1, NULL),
(11, 'Aventi', '180', 2, 'a:1:{i:0;s:137:"Account saved correctly: <a class="simple-link" target="blank" href="/opticaltel/app/index.php/accounts/default/details?id=22">Aventi</a>";}', 1, NULL),
(12, 'Kenilworth (Net)', '158', 2, 'a:1:{i:0;s:147:"Account saved correctly: <a class="simple-link" target="blank" href="/opticaltel/app/index.php/accounts/default/details?id=23">Kenilworth (Net)</a>";}', 1, NULL),
(13, '400 Association (Data)', '64', 2, 'a:1:{i:0;s:153:"Account saved correctly: <a class="simple-link" target="blank" href="/opticaltel/app/index.php/accounts/default/details?id=24">400 Association (Data)</a>";}', 1, NULL),
(14, 'Marina Village (Net)', '349', 2, 'a:1:{i:0;s:151:"Account saved correctly: <a class="simple-link" target="blank" href="/opticaltel/app/index.php/accounts/default/details?id=25">Marina Village (Net)</a>";}', 1, NULL),
(15, 'Tropic Harbor', '225', 2, 'a:1:{i:0;s:144:"Account saved correctly: <a class="simple-link" target="blank" href="/opticaltel/app/index.php/accounts/default/details?id=26">Tropic Harbor</a>";}', 1, NULL),
(16, 'Midtown Doral', '1700', 2, 'a:1:{i:0;s:144:"Account saved correctly: <a class="simple-link" target="blank" href="/opticaltel/app/index.php/accounts/default/details?id=27">Midtown Doral</a>";}', 1, NULL),
(17, 'Midtown Retail', '150', 2, 'a:1:{i:0;s:145:"Account saved correctly: <a class="simple-link" target="blank" href="/opticaltel/app/index.php/accounts/default/details?id=28">Midtown Retail</a>";}', 1, NULL),
(18, 'Meadowbrook # 4', '244', 2, 'a:1:{i:0;s:146:"Account saved correctly: <a class="simple-link" target="blank" href="/opticaltel/app/index.php/accounts/default/details?id=29">Meadowbrook # 4</a>";}', 1, NULL),
(19, 'Parker Plaza', '520', 2, 'a:1:{i:0;s:143:"Account saved correctly: <a class="simple-link" target="blank" href="/opticaltel/app/index.php/accounts/default/details?id=30">Parker Plaza</a>";}', 1, NULL),
(20, 'Topaz North', '84', 2, 'a:1:{i:0;s:142:"Account saved correctly: <a class="simple-link" target="blank" href="/opticaltel/app/index.php/accounts/default/details?id=31">Topaz North</a>";}', 1, NULL),
(21, 'Northern Star (Net)', '22', 2, 'a:1:{i:0;s:150:"Account saved correctly: <a class="simple-link" target="blank" href="/opticaltel/app/index.php/accounts/default/details?id=32">Northern Star (Net)</a>";}', 1, NULL),
(22, 'Emerald (Net)', '108', 2, 'a:1:{i:0;s:144:"Account saved correctly: <a class="simple-link" target="blank" href="/opticaltel/app/index.php/accounts/default/details?id=33">Emerald (Net)</a>";}', 1, NULL),
(23, 'Cloisters (Net)', '140', 2, 'a:1:{i:0;s:146:"Account saved correctly: <a class="simple-link" target="blank" href="/opticaltel/app/index.php/accounts/default/details?id=34">Cloisters (Net)</a>";}', 1, NULL),
(24, '3360 Condo', '90', 2, 'a:1:{i:0;s:141:"Account saved correctly: <a class="simple-link" target="blank" href="/opticaltel/app/index.php/accounts/default/details?id=35">3360 Condo</a>";}', 1, NULL),
(25, 'Lake Worth Towers', '199', 2, 'a:1:{i:0;s:148:"Account saved correctly: <a class="simple-link" target="blank" href="/opticaltel/app/index.php/accounts/default/details?id=36">Lake Worth Towers</a>";}', 1, NULL),
(26, 'Point East Condo', '1270', 2, 'a:1:{i:0;s:147:"Account saved correctly: <a class="simple-link" target="blank" href="/opticaltel/app/index.php/accounts/default/details?id=37">Point East Condo</a>";}', 1, NULL),
(27, 'Pine Ridge Condo', '462', 2, 'a:1:{i:0;s:147:"Account saved correctly: <a class="simple-link" target="blank" href="/opticaltel/app/index.php/accounts/default/details?id=38">Pine Ridge Condo</a>";}', 1, NULL),
(28, 'Christopher House', '96', 2, 'a:1:{i:0;s:148:"Account saved correctly: <a class="simple-link" target="blank" href="/opticaltel/app/index.php/accounts/default/details?id=39">Christopher House</a>";}', 1, NULL),
(29, 'The Residences on Hollywood Beach Proposal (Net)', '534', 2, 'a:1:{i:0;s:179:"Account saved correctly: <a class="simple-link" target="blank" href="/opticaltel/app/index.php/accounts/default/details?id=40">The Residences on Hollywood Beach Proposal (Net)</a>";}', 1, NULL),
(30, 'Pinehurst Club (Net)', '197', 2, 'a:1:{i:0;s:151:"Account saved correctly: <a class="simple-link" target="blank" href="/opticaltel/app/index.php/accounts/default/details?id=41">Pinehurst Club (Net)</a>";}', 1, NULL),
(31, 'Harbour House', '192', 2, 'a:1:{i:0;s:144:"Account saved correctly: <a class="simple-link" target="blank" href="/opticaltel/app/index.php/accounts/default/details?id=42">Harbour House</a>";}', 1, NULL),
(32, 'Mystic Point', '482', 2, 'a:1:{i:0;s:143:"Account saved correctly: <a class="simple-link" target="blank" href="/opticaltel/app/index.php/accounts/default/details?id=43">Mystic Point</a>";}', 1, NULL),
(33, 'Glades Country Club (Net)', '1255', 2, 'a:1:{i:0;s:156:"Account saved correctly: <a class="simple-link" target="blank" href="/opticaltel/app/index.php/accounts/default/details?id=44">Glades Country Club (Net)</a>";}', 1, NULL),
(34, '9 Island (Net)', '271', 2, 'a:1:{i:0;s:145:"Account saved correctly: <a class="simple-link" target="blank" href="/opticaltel/app/index.php/accounts/default/details?id=45">9 Island (Net)</a>";}', 1, NULL),
(35, 'Seamark (Net)', '39', 2, 'a:1:{i:0;s:144:"Account saved correctly: <a class="simple-link" target="blank" href="/opticaltel/app/index.php/accounts/default/details?id=46">Seamark (Net)</a>";}', 1, NULL),
(36, 'Balmoral Condo', '423', 2, 'a:1:{i:0;s:145:"Account saved correctly: <a class="simple-link" target="blank" href="/opticaltel/app/index.php/accounts/default/details?id=47">Balmoral Condo</a>";}', 1, NULL),
(37, 'Artesia', '1000', 2, 'a:1:{i:0;s:138:"Account saved correctly: <a class="simple-link" target="blank" href="/opticaltel/app/index.php/accounts/default/details?id=48">Artesia</a>";}', 1, NULL),
(38, 'Mayfair House Condo', '223', 2, 'a:1:{i:0;s:150:"Account saved correctly: <a class="simple-link" target="blank" href="/opticaltel/app/index.php/accounts/default/details?id=49">Mayfair House Condo</a>";}', 1, NULL),
(39, 'OceanView Place', '591', 2, 'a:1:{i:0;s:146:"Account saved correctly: <a class="simple-link" target="blank" href="/opticaltel/app/index.php/accounts/default/details?id=50">OceanView Place</a>";}', 1, NULL),
(40, 'River Bridge', '1100', 2, 'a:1:{i:0;s:143:"Account saved correctly: <a class="simple-link" target="blank" href="/opticaltel/app/index.php/accounts/default/details?id=51">River Bridge</a>";}', 1, NULL),
(41, 'Ocean Place', '256', 2, 'a:1:{i:0;s:142:"Account saved correctly: <a class="simple-link" target="blank" href="/opticaltel/app/index.php/accounts/default/details?id=52">Ocean Place</a>";}', 1, NULL),
(42, 'The Tides @ Bridgeside Square', '246', 2, 'a:1:{i:0;s:160:"Account saved correctly: <a class="simple-link" target="blank" href="/opticaltel/app/index.php/accounts/default/details?id=53">The Tides @ Bridgeside Square</a>";}', 1, NULL),
(43, 'OakBridge', '279', 2, 'a:1:{i:0;s:140:"Account saved correctly: <a class="simple-link" target="blank" href="/opticaltel/app/index.php/accounts/default/details?id=54">OakBridge</a>";}', 1, NULL),
(44, 'Sand Pebble Beach Condominiums', '242', 2, 'a:1:{i:0;s:161:"Account saved correctly: <a class="simple-link" target="blank" href="/opticaltel/app/index.php/accounts/default/details?id=55">Sand Pebble Beach Condominiums</a>";}', 1, NULL),
(45, 'The Atriums', '106', 2, 'a:1:{i:0;s:142:"Account saved correctly: <a class="simple-link" target="blank" href="/opticaltel/app/index.php/accounts/default/details?id=56">The Atriums</a>";}', 1, NULL),
(46, 'Plaza of Bal Harbour', '302', 2, 'a:1:{i:0;s:151:"Account saved correctly: <a class="simple-link" target="blank" href="/opticaltel/app/index.php/accounts/default/details?id=57">Plaza of Bal Harbour</a>";}', 1, NULL),
(47, 'Nirvana Condos', '385', 2, 'a:1:{i:0;s:145:"Account saved correctly: <a class="simple-link" target="blank" href="/opticaltel/app/index.php/accounts/default/details?id=58">Nirvana Condos</a>";}', 1, NULL),
(48, 'Commodore Plaza', '654', 2, 'a:1:{i:0;s:146:"Account saved correctly: <a class="simple-link" target="blank" href="/opticaltel/app/index.php/accounts/default/details?id=59">Commodore Plaza</a>";}', 1, NULL),
(49, 'Fairways of Tamarac', '174', 2, 'a:1:{i:0;s:150:"Account saved correctly: <a class="simple-link" target="blank" href="/opticaltel/app/index.php/accounts/default/details?id=60">Fairways of Tamarac</a>";}', 1, NULL),
(50, 'Patrician of the Palm Beaches', '224', 2, 'a:1:{i:0;s:160:"Account saved correctly: <a class="simple-link" target="blank" href="/opticaltel/app/index.php/accounts/default/details?id=61">Patrician of the Palm Beaches</a>";}', 1, NULL),
(51, 'Alexander Hotel/Condo', '230', 2, 'a:1:{i:0;s:152:"Account saved correctly: <a class="simple-link" target="blank" href="/opticaltel/app/index.php/accounts/default/details?id=62">Alexander Hotel/Condo</a>";}', 1, NULL),
(52, 'Las Verdes', '1232', 2, 'a:1:{i:0;s:141:"Account saved correctly: <a class="simple-link" target="blank" href="/opticaltel/app/index.php/accounts/default/details?id=63">Las Verdes</a>";}', 1, NULL),
(53, 'Lakes of Savannah', '242', 2, 'a:1:{i:0;s:148:"Account saved correctly: <a class="simple-link" target="blank" href="/opticaltel/app/index.php/accounts/default/details?id=64">Lakes of Savannah</a>";}', 1, NULL),
(54, 'East Pointe Towers', '274', 2, 'a:1:{i:0;s:149:"Account saved correctly: <a class="simple-link" target="blank" href="/opticaltel/app/index.php/accounts/default/details?id=65">East Pointe Towers</a>";}', 1, NULL),
(55, 'Bravura 1 Condo', '192', 2, 'a:1:{i:0;s:146:"Account saved correctly: <a class="simple-link" target="blank" href="/opticaltel/app/index.php/accounts/default/details?id=66">Bravura 1 Condo</a>";}', 1, NULL),
(56, 'TOWERS OF KENDAL LAKES', '180', 2, 'a:1:{i:0;s:153:"Account saved correctly: <a class="simple-link" target="blank" href="/opticaltel/app/index.php/accounts/default/details?id=67">TOWERS OF KENDAL LAKES</a>";}', 1, NULL),
(57, 'Commodore Club South', '186', 2, 'a:1:{i:0;s:151:"Account saved correctly: <a class="simple-link" target="blank" href="/opticaltel/app/index.php/accounts/default/details?id=68">Commodore Club South</a>";}', 1, NULL),
(58, 'Oceanfront Plaza', '193', 2, 'a:1:{i:0;s:147:"Account saved correctly: <a class="simple-link" target="blank" href="/opticaltel/app/index.php/accounts/default/details?id=69">Oceanfront Plaza</a>";}', 1, NULL),
(59, 'Hillsboro Cove', '318', 2, 'a:1:{i:0;s:145:"Account saved correctly: <a class="simple-link" target="blank" href="/opticaltel/app/index.php/accounts/default/details?id=70">Hillsboro Cove</a>";}', 1, NULL);

-- --------------------------------------------------------

--
-- Table structure for table `importtable2`
--

CREATE TABLE IF NOT EXISTS `importtable2` (
`id` int(11) unsigned NOT NULL,
  `column_0` varchar(2) COLLATE utf8_unicode_ci DEFAULT NULL,
  `column_1` varchar(17) COLLATE utf8_unicode_ci DEFAULT NULL,
  `column_2` varchar(18) COLLATE utf8_unicode_ci DEFAULT NULL,
  `column_3` varchar(15) COLLATE utf8_unicode_ci DEFAULT NULL,
  `column_4` varchar(16) COLLATE utf8_unicode_ci DEFAULT NULL,
  `column_5` varchar(5) COLLATE utf8_unicode_ci DEFAULT NULL,
  `column_6` varchar(10) COLLATE utf8_unicode_ci DEFAULT NULL,
  `column_7` varchar(11) COLLATE utf8_unicode_ci DEFAULT NULL,
  `column_8` varchar(48) COLLATE utf8_unicode_ci DEFAULT NULL,
  `column_9` varchar(11) COLLATE utf8_unicode_ci DEFAULT NULL,
  `column_10` varchar(23) COLLATE utf8_unicode_ci DEFAULT NULL,
  `column_11` varchar(48) COLLATE utf8_unicode_ci DEFAULT NULL,
  `column_12` varchar(18) COLLATE utf8_unicode_ci DEFAULT NULL,
  `column_13` varchar(27) COLLATE utf8_unicode_ci DEFAULT NULL,
  `column_14` varchar(18) COLLATE utf8_unicode_ci DEFAULT NULL,
  `column_15` varchar(6) COLLATE utf8_unicode_ci DEFAULT NULL,
  `column_16` varchar(23) COLLATE utf8_unicode_ci DEFAULT NULL,
  `column_17` varchar(15) COLLATE utf8_unicode_ci DEFAULT NULL,
  `column_18` varchar(36) COLLATE utf8_unicode_ci DEFAULT NULL,
  `column_19` varchar(45) COLLATE utf8_unicode_ci DEFAULT NULL,
  `column_20` varchar(36) COLLATE utf8_unicode_ci DEFAULT NULL,
  `column_21` varchar(45) COLLATE utf8_unicode_ci DEFAULT NULL,
  `column_22` varchar(39) COLLATE utf8_unicode_ci DEFAULT NULL,
  `column_23` varchar(48) COLLATE utf8_unicode_ci DEFAULT NULL,
  `column_24` varchar(36) COLLATE utf8_unicode_ci DEFAULT NULL,
  `column_25` varchar(45) COLLATE utf8_unicode_ci DEFAULT NULL,
  `column_26` varchar(27) COLLATE utf8_unicode_ci DEFAULT NULL,
  `column_27` varchar(36) COLLATE utf8_unicode_ci DEFAULT NULL,
  `column_28` varchar(32) COLLATE utf8_unicode_ci DEFAULT NULL,
  `column_29` varchar(41) COLLATE utf8_unicode_ci DEFAULT NULL,
  `column_30` varchar(25) COLLATE utf8_unicode_ci DEFAULT NULL,
  `column_31` varchar(36) COLLATE utf8_unicode_ci DEFAULT NULL,
  `column_32` varchar(45) COLLATE utf8_unicode_ci DEFAULT NULL,
  `column_33` varchar(18) COLLATE utf8_unicode_ci DEFAULT NULL,
  `column_34` varchar(27) COLLATE utf8_unicode_ci DEFAULT NULL,
  `status` int(11) unsigned DEFAULT NULL,
  `serializedMessages` text COLLATE utf8_unicode_ci,
  `analysisStatus` int(11) unsigned DEFAULT NULL,
  `serializedAnalysisMessages` text COLLATE utf8_unicode_ci
) ENGINE=InnoDB AUTO_INCREMENT=61 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

--
-- Dumping data for table `importtable2`
--

INSERT INTO `importtable2` (`id`, `column_0`, `column_1`, `column_2`, `column_3`, `column_4`, `column_5`, `column_6`, `column_7`, `column_8`, `column_9`, `column_10`, `column_11`, `column_12`, `column_13`, `column_14`, `column_15`, `column_16`, `column_17`, `column_18`, `column_19`, `column_20`, `column_21`, `column_22`, `column_23`, `column_24`, `column_25`, `column_26`, `column_27`, `column_28`, `column_29`, `column_30`, `column_31`, `column_32`, `column_33`, `column_34`, `status`, `serializedMessages`, `analysisStatus`, `serializedAnalysisMessages`) VALUES
(1, 'Id', 'Created Date Time', 'Modified Date Time', 'Created By User', 'Modified By User', 'Owner', 'Close Date', 'Description', 'Opportunity Name', 'Probability', 'Proposed Infrastructure', 'Account - Name', 'Total Project Cost', 'Total Project Cost Currency', 'Stage', 'Source', 'Requested Bulk Services', 'Contract Length', 'Video Proposed Bulk Pricing Per Unit', 'Video Proposed Bulk Pricing Per Unit Currency', 'Alarm Proposed Bulk Pricing Per Unit', 'Alarm Proposed Bulk Pricing Per Unit Currency', 'Internet Proposed Bulk Pricing Per Unit', 'Internet Proposed Bulk Pricing Per Unit Currency', 'Phone Proposed Bulk Pricing Per Unit', 'Phone Proposed Bulk Pricing Per Unit Currency', 'Total Bulk Pricing Per Unit', 'Total Bulk Pricing Per Unit Currency', 'Total Proposed Monthly Recurring', 'Total Proposed Monthly Recurring Currency', 'Construction Cost Request', 'Estimated Construction Cost Per Unit', 'Estimated Construction Cost Per Unit Currency', 'Total Project Cost', 'Total Project Cost Currency', NULL, NULL, NULL, NULL),
(2, '', '', '', '', '', '', '', '', '400 Association (Data)', '', '', '400 Association (Data)', '', '', 'Under Construction', '', 'Video', '', '$28.95', 'USD', '', '', '', '', '', '', '', '', '', '', 'Yes', '250', '', '', '', 2, 'a:1:{i:0;s:162:"Opportunity saved correctly: <a class="simple-link" target="blank" href="/opticaltel/app/index.php/opportunities/default/details?id=23">400 Association (Data)</a>";}', 3, 'a:1:{s:9:"column_11";a:1:{i:0;s:57:"Was not found and this row will be skipped during import.";}}'),
(3, '', '', '', '', '', '', '', '', '9 Island (Net)', '', '', '9 Island (Net)', '', '', 'Under Construction', '', 'Video', '', '$5.95', 'USD', '', '', '', '', '', '', '', '', '', '', 'Yes', '250', '', '', '', 2, 'a:1:{i:0;s:154:"Opportunity saved correctly: <a class="simple-link" target="blank" href="/opticaltel/app/index.php/opportunities/default/details?id=24">9 Island (Net)</a>";}', 3, 'a:1:{s:9:"column_11";a:1:{i:0;s:57:"Was not found and this row will be skipped during import.";}}'),
(4, '', '', '', '', '', '', '', '', 'Alexander Hotel/Condo', '', '', 'Alexander Hotel/Condo', '', '', 'Under Construction', '', 'Video', '', '$44.95', 'USD', '', '', '', '', '', '', '', '', '', '', 'Yes', '250', '', '', '', 2, 'a:1:{i:0;s:161:"Opportunity saved correctly: <a class="simple-link" target="blank" href="/opticaltel/app/index.php/opportunities/default/details?id=25">Alexander Hotel/Condo</a>";}', 3, 'a:1:{s:9:"column_11";a:1:{i:0;s:57:"Was not found and this row will be skipped during import.";}}'),
(5, '', '', '', '', '', '', '', '', 'Artesia', '', '', 'Artesia', '', '', 'Under Construction', '', 'Video', '', '$68.95', 'USD', '', '', '', '', '', '', '', '', '', '', 'Yes', '250', '', '', '', 2, 'a:1:{i:0;s:147:"Opportunity saved correctly: <a class="simple-link" target="blank" href="/opticaltel/app/index.php/opportunities/default/details?id=26">Artesia</a>";}', 3, 'a:1:{s:9:"column_11";a:1:{i:0;s:57:"Was not found and this row will be skipped during import.";}}'),
(6, '', '', '', '', '', '', '', '', 'Aventi', '', '', 'Aventi', '', '', 'Under Construction', '', 'Video', '', '$72.61', 'USD', '', '', '', '', '', '', '', '', '', '', 'Yes', '250', '', '', '', 2, 'a:1:{i:0;s:146:"Opportunity saved correctly: <a class="simple-link" target="blank" href="/opticaltel/app/index.php/opportunities/default/details?id=27">Aventi</a>";}', 3, 'a:1:{s:9:"column_11";a:1:{i:0;s:57:"Was not found and this row will be skipped during import.";}}'),
(7, '', '', '', '', '', '', '', '', 'Balmoral Condo', '', '', 'Balmoral Condo', '', '', 'Under Construction', '', 'Video', '', '$69.95', 'USD', '', '', '', '', '', '', '', '', '', '', 'Yes', '250', '', '', '', 2, 'a:1:{i:0;s:154:"Opportunity saved correctly: <a class="simple-link" target="blank" href="/opticaltel/app/index.php/opportunities/default/details?id=28">Balmoral Condo</a>";}', 3, 'a:1:{s:9:"column_11";a:1:{i:0;s:57:"Was not found and this row will be skipped during import.";}}'),
(8, '', '', '', '', '', '', '', '', 'Bravura 1 Condo', '', '', 'Bravura 1 Condo', '', '', 'Under Construction', '', 'Video', '', '$54.95', 'USD', '', '', '', '', '', '', '', '', '', '', 'Yes', '250', '', '', '', 2, 'a:1:{i:0;s:155:"Opportunity saved correctly: <a class="simple-link" target="blank" href="/opticaltel/app/index.php/opportunities/default/details?id=29">Bravura 1 Condo</a>";}', 3, 'a:1:{s:9:"column_11";a:1:{i:0;s:57:"Was not found and this row will be skipped during import.";}}'),
(9, '', '', '', '', '', '', '', '', 'Christopher House', '', '', 'Christopher House', '', '', 'Under Construction', '', 'Video', '', '$69.95', 'USD', '', '', '', '', '', '', '', '', '', '', 'Yes', '250', '', '', '', 2, 'a:1:{i:0;s:157:"Opportunity saved correctly: <a class="simple-link" target="blank" href="/opticaltel/app/index.php/opportunities/default/details?id=30">Christopher House</a>";}', 3, 'a:1:{s:9:"column_11";a:1:{i:0;s:57:"Was not found and this row will be skipped during import.";}}'),
(10, '', '', '', '', '', '', '', '', 'Cloisters (Net)', '', '', 'Cloisters (Net)', '', '', 'Under Construction', '', 'Video', '', '$16.67', 'USD', '', '', '', '', '', '', '', '', '', '', 'Yes', '250', '', '', '', 2, 'a:1:{i:0;s:155:"Opportunity saved correctly: <a class="simple-link" target="blank" href="/opticaltel/app/index.php/opportunities/default/details?id=31">Cloisters (Net)</a>";}', 3, 'a:1:{s:9:"column_11";a:1:{i:0;s:57:"Was not found and this row will be skipped during import.";}}'),
(11, '', '', '', '', '', '', '', '', 'Commodore Club South', '', '', 'Commodore Club South', '', '', 'Under Construction', '', 'Video', '', '$64.95', 'USD', '', '', '', '', '', '', '', '', '', '', 'Yes', '250', '', '', '', 2, 'a:1:{i:0;s:160:"Opportunity saved correctly: <a class="simple-link" target="blank" href="/opticaltel/app/index.php/opportunities/default/details?id=32">Commodore Club South</a>";}', 3, 'a:1:{s:9:"column_11";a:1:{i:0;s:57:"Was not found and this row will be skipped during import.";}}'),
(12, '', '', '', '', '', '', '', '', 'Commodore Plaza', '', '', 'Commodore Plaza', '', '', 'Under Construction', '', 'Video', '', '$59.95', 'USD', '', '', '', '', '', '', '', '', '', '', 'Yes', '250', '', '', '', 2, 'a:1:{i:0;s:155:"Opportunity saved correctly: <a class="simple-link" target="blank" href="/opticaltel/app/index.php/opportunities/default/details?id=33">Commodore Plaza</a>";}', 3, 'a:1:{s:9:"column_11";a:1:{i:0;s:57:"Was not found and this row will be skipped during import.";}}'),
(13, '', '', '', '', '', '', '', '', 'Cypress Trails', '', '', 'Cypress Trails', '', '', 'Under Construction', '', 'Video', '', '$46.95', 'USD', '', '', '', '', '', '', '', '', '', '', 'Yes', '250', '', '', '', 2, 'a:1:{i:0;s:154:"Opportunity saved correctly: <a class="simple-link" target="blank" href="/opticaltel/app/index.php/opportunities/default/details?id=34">Cypress Trails</a>";}', 3, 'a:1:{s:9:"column_11";a:1:{i:0;s:57:"Was not found and this row will be skipped during import.";}}'),
(14, '', '', '', '', '', '', '', '', 'East Pointe Towers', '', '', 'East Pointe Towers', '', '', 'Under Construction', '', 'Video', '', '$52.95', 'USD', '', '', '', '', '', '', '', '', '', '', 'Yes', '250', '', '', '', 2, 'a:1:{i:0;s:158:"Opportunity saved correctly: <a class="simple-link" target="blank" href="/opticaltel/app/index.php/opportunities/default/details?id=35">East Pointe Towers</a>";}', 3, 'a:1:{s:9:"column_11";a:1:{i:0;s:57:"Was not found and this row will be skipped during import.";}}'),
(15, '', '', '', '', '', '', '', '', 'Emerald (Net)', '', '', 'Emerald (Net)', '', '', 'Under Construction', '', 'Video', '', '$8.17', 'USD', '', '', '', '', '', '', '', '', '', '', 'Yes', '250', '', '', '', 2, 'a:1:{i:0;s:153:"Opportunity saved correctly: <a class="simple-link" target="blank" href="/opticaltel/app/index.php/opportunities/default/details?id=36">Emerald (Net)</a>";}', 3, 'a:1:{s:9:"column_11";a:1:{i:0;s:57:"Was not found and this row will be skipped during import.";}}'),
(16, '', '', '', '', '', '', '', '', 'Fairways of Tamarac', '', '', 'Fairways of Tamarac', '', '', 'Under Construction', '', 'Video', '', '$34.95', 'USD', '', '', '', '', '', '', '', '', '', '', 'Yes', '250', '', '', '', 2, 'a:1:{i:0;s:159:"Opportunity saved correctly: <a class="simple-link" target="blank" href="/opticaltel/app/index.php/opportunities/default/details?id=37">Fairways of Tamarac</a>";}', 3, 'a:1:{s:9:"column_11";a:1:{i:0;s:57:"Was not found and this row will be skipped during import.";}}'),
(17, '', '', '', '', '', '', '', '', 'Garden Estates (Net)', '', '', 'Garden Estates (Net)', '', '', 'Under Construction', '', 'Video', '', '$4.00', 'USD', '', '', '', '', '', '', '', '', '', '', 'Yes', '250', '', '', '', 2, 'a:1:{i:0;s:160:"Opportunity saved correctly: <a class="simple-link" target="blank" href="/opticaltel/app/index.php/opportunities/default/details?id=38">Garden Estates (Net)</a>";}', 3, 'a:1:{s:9:"column_11";a:1:{i:0;s:57:"Was not found and this row will be skipped during import.";}}'),
(18, '', '', '', '', '', '', '', '', 'Glades Country Club (Net)', '', '', 'Glades Country Club (Net)', '', '', 'Under Construction', '', 'Video', '', '$34.57', 'USD', '', '', '', '', '', '', '', '', '', '', 'Yes', '250', '', '', '', 2, 'a:1:{i:0;s:165:"Opportunity saved correctly: <a class="simple-link" target="blank" href="/opticaltel/app/index.php/opportunities/default/details?id=39">Glades Country Club (Net)</a>";}', 3, 'a:1:{s:9:"column_11";a:1:{i:0;s:57:"Was not found and this row will be skipped during import.";}}'),
(19, '', '', '', '', '', '', '', '', 'Harbour House', '', '', 'Harbour House', '', '', 'Under Construction', '', 'Video', '', '$59.95', 'USD', '', '', '', '', '', '', '', '', '', '', 'Yes', '250', '', '', '', 2, 'a:1:{i:0;s:153:"Opportunity saved correctly: <a class="simple-link" target="blank" href="/opticaltel/app/index.php/opportunities/default/details?id=40">Harbour House</a>";}', 3, 'a:1:{s:9:"column_11";a:1:{i:0;s:57:"Was not found and this row will be skipped during import.";}}'),
(20, '', '', '', '', '', '', '', '', 'Hillsboro Cove', '', '', 'Hillsboro Cove', '', '', 'Under Construction', '', 'Video', '', '$37.95', 'USD', '', '', '', '', '', '', '', '', '', '', 'Yes', '250', '', '', '', 2, 'a:1:{i:0;s:154:"Opportunity saved correctly: <a class="simple-link" target="blank" href="/opticaltel/app/index.php/opportunities/default/details?id=41">Hillsboro Cove</a>";}', 3, 'a:1:{s:9:"column_11";a:1:{i:0;s:57:"Was not found and this row will be skipped during import.";}}'),
(21, '', '', '', '', '', '', '', '', 'Isles at Grand Bay', '', '', 'Isles at Grand Bay', '', '', 'Under Construction', '', 'Video', '', '$0.00', 'USD', '', '', '', '', '', '', '', '', '', '', 'Yes', '250', '', '', '', 2, 'a:1:{i:0;s:158:"Opportunity saved correctly: <a class="simple-link" target="blank" href="/opticaltel/app/index.php/opportunities/default/details?id=42">Isles at Grand Bay</a>";}', 3, 'a:1:{s:9:"column_11";a:1:{i:0;s:57:"Was not found and this row will be skipped during import.";}}'),
(22, '', '', '', '', '', '', '', '', 'Kenilworth (Net)', '', '', 'Kenilworth (Net)', '', '', 'Under Construction', '', 'Video', '', '$31.45', 'USD', '', '', '', '', '', '', '', '', '', '', 'Yes', '250', '', '', '', 2, 'a:1:{i:0;s:156:"Opportunity saved correctly: <a class="simple-link" target="blank" href="/opticaltel/app/index.php/opportunities/default/details?id=43">Kenilworth (Net)</a>";}', 3, 'a:1:{s:9:"column_11";a:1:{i:0;s:57:"Was not found and this row will be skipped during import.";}}'),
(23, '', '', '', '', '', '', '', '', 'Key Largo', '', '', 'Key Largo', '', '', 'Under Construction', '', 'Video', '', '$43.95', 'USD', '', '', '', '', '', '', '', '', '', '', 'Yes', '250', '', '', '', 2, 'a:1:{i:0;s:149:"Opportunity saved correctly: <a class="simple-link" target="blank" href="/opticaltel/app/index.php/opportunities/default/details?id=44">Key Largo</a>";}', 3, 'a:1:{s:9:"column_11";a:1:{i:0;s:57:"Was not found and this row will be skipped during import.";}}'),
(24, '', '', '', '', '', '', '', '', 'Lake Worth Towers', '', '', 'Lake Worth Towers', '', '', 'Under Construction', '', 'Video', '', '$19.95', 'USD', '', '', '', '', '', '', '', '', '', '', 'Yes', '250', '', '', '', 2, 'a:1:{i:0;s:157:"Opportunity saved correctly: <a class="simple-link" target="blank" href="/opticaltel/app/index.php/opportunities/default/details?id=45">Lake Worth Towers</a>";}', 3, 'a:1:{s:9:"column_11";a:1:{i:0;s:57:"Was not found and this row will be skipped during import.";}}'),
(25, '', '', '', '', '', '', '', '', 'Lakes of Savannah', '', '', 'Lakes of Savannah', '', '', 'Under Construction', '', 'Video', '', '$37.95', 'USD', '', '', '', '', '', '', '', '', '', '', 'Yes', '250', '', '', '', 2, 'a:1:{i:0;s:157:"Opportunity saved correctly: <a class="simple-link" target="blank" href="/opticaltel/app/index.php/opportunities/default/details?id=46">Lakes of Savannah</a>";}', 3, 'a:1:{s:9:"column_11";a:1:{i:0;s:57:"Was not found and this row will be skipped during import.";}}'),
(26, '', '', '', '', '', '', '', '', 'Las Verdes', '', '', 'Las Verdes', '', '', 'Under Construction', '', 'Video', '', '$36.95', 'USD', '', '', '', '', '', '', '', '', '', '', 'Yes', '250', '', '', '', 2, 'a:1:{i:0;s:150:"Opportunity saved correctly: <a class="simple-link" target="blank" href="/opticaltel/app/index.php/opportunities/default/details?id=47">Las Verdes</a>";}', 3, 'a:1:{s:9:"column_11";a:1:{i:0;s:57:"Was not found and this row will be skipped during import.";}}'),
(27, '', '', '', '', '', '', '', '', 'Marina Village (Net)', '', '', 'Marina Village (Net)', '', '', 'Under Construction', '', 'Video', '', '$19.43', 'USD', '', '', '', '', '', '', '', '', '', '', 'Yes', '250', '', '', '', 2, 'a:1:{i:0;s:160:"Opportunity saved correctly: <a class="simple-link" target="blank" href="/opticaltel/app/index.php/opportunities/default/details?id=48">Marina Village (Net)</a>";}', 3, 'a:1:{s:9:"column_11";a:1:{i:0;s:57:"Was not found and this row will be skipped during import.";}}'),
(28, '', '', '', '', '', '', '', '', 'Mayfair House Condo', '', '', 'Mayfair House Condo', '', '', 'Under Construction', '', 'Video', '', '$55.95', 'USD', '', '', '', '', '', '', '', '', '', '', 'Yes', '250', '', '', '', 2, 'a:1:{i:0;s:159:"Opportunity saved correctly: <a class="simple-link" target="blank" href="/opticaltel/app/index.php/opportunities/default/details?id=49">Mayfair House Condo</a>";}', 3, 'a:1:{s:9:"column_11";a:1:{i:0;s:57:"Was not found and this row will be skipped during import.";}}'),
(29, '', '', '', '', '', '', '', '', 'Meadowbrook # 4', '', '', 'Meadowbrook # 4', '', '', 'Under Construction', '', 'Video', '', '$36.95', 'USD', '', '', '', '', '', '', '', '', '', '', 'Yes', '250', '', '', '', 2, 'a:1:{i:0;s:155:"Opportunity saved correctly: <a class="simple-link" target="blank" href="/opticaltel/app/index.php/opportunities/default/details?id=50">Meadowbrook # 4</a>";}', 3, 'a:1:{s:9:"column_11";a:1:{i:0;s:57:"Was not found and this row will be skipped during import.";}}'),
(30, '', '', '', '', '', '', '', '', 'Midtown Doral', '', '', 'Midtown Doral', '', '', 'Under Construction', '', 'Video', '', '$69.95', 'USD', '', '', '', '', '', '', '', '', '', '', 'Yes', '250', '', '', '', 2, 'a:1:{i:0;s:153:"Opportunity saved correctly: <a class="simple-link" target="blank" href="/opticaltel/app/index.php/opportunities/default/details?id=51">Midtown Doral</a>";}', 3, 'a:1:{s:9:"column_11";a:1:{i:0;s:57:"Was not found and this row will be skipped during import.";}}'),
(31, '', '', '', '', '', '', '', '', 'Midtown Retail', '', '', 'Midtown Retail', '', '', 'Under Construction', '', 'Video', '', '$0.00', 'USD', '', '', '', '', '', '', '', '', '', '', 'Yes', '250', '', '', '', 2, 'a:1:{i:0;s:154:"Opportunity saved correctly: <a class="simple-link" target="blank" href="/opticaltel/app/index.php/opportunities/default/details?id=52">Midtown Retail</a>";}', 3, 'a:1:{s:9:"column_11";a:1:{i:0;s:57:"Was not found and this row will be skipped during import.";}}'),
(32, '', '', '', '', '', '', '', '', 'Mystic Point', '', '', 'Mystic Point', '', '', 'Under Construction', '', 'Video', '', '$77.95', 'USD', '', '', '', '', '', '', '', '', '', '', 'Yes', '250', '', '', '', 2, 'a:1:{i:0;s:152:"Opportunity saved correctly: <a class="simple-link" target="blank" href="/opticaltel/app/index.php/opportunities/default/details?id=53">Mystic Point</a>";}', 3, 'a:1:{s:9:"column_11";a:1:{i:0;s:57:"Was not found and this row will be skipped during import.";}}'),
(33, '', '', '', '', '', '', '', '', 'Nirvana Condos', '', '', 'Nirvana Condos', '', '', 'Under Construction', '', 'Video', '', '$49.95', 'USD', '', '', '', '', '', '', '', '', '', '', 'Yes', '250', '', '', '', 2, 'a:1:{i:0;s:154:"Opportunity saved correctly: <a class="simple-link" target="blank" href="/opticaltel/app/index.php/opportunities/default/details?id=54">Nirvana Condos</a>";}', 3, 'a:1:{s:9:"column_11";a:1:{i:0;s:57:"Was not found and this row will be skipped during import.";}}'),
(34, '', '', '', '', '', '', '', '', 'Northern Star (Net)', '', '', 'Northern Star (Net)', '', '', 'Under Construction', '', 'Video', '', '$19.03', 'USD', '', '', '', '', '', '', '', '', '', '', 'Yes', '250', '', '', '', 2, 'a:1:{i:0;s:159:"Opportunity saved correctly: <a class="simple-link" target="blank" href="/opticaltel/app/index.php/opportunities/default/details?id=55">Northern Star (Net)</a>";}', 3, 'a:1:{s:9:"column_11";a:1:{i:0;s:57:"Was not found and this row will be skipped during import.";}}'),
(35, '', '', '', '', '', '', '', '', 'OakBridge', '', '', 'OakBridge', '', '', 'Under Construction', '', 'Video', '', '$69.95', 'USD', '', '', '', '', '', '', '', '', '', '', 'Yes', '250', '', '', '', 2, 'a:1:{i:0;s:149:"Opportunity saved correctly: <a class="simple-link" target="blank" href="/opticaltel/app/index.php/opportunities/default/details?id=56">OakBridge</a>";}', 3, 'a:1:{s:9:"column_11";a:1:{i:0;s:57:"Was not found and this row will be skipped during import.";}}'),
(36, '', '', '', '', '', '', '', '', 'Ocean Place', '', '', 'Ocean Place', '', '', 'Under Construction', '', 'Video', '', '$49.95', 'USD', '', '', '', '', '', '', '', '', '', '', 'Yes', '250', '', '', '', 2, 'a:1:{i:0;s:151:"Opportunity saved correctly: <a class="simple-link" target="blank" href="/opticaltel/app/index.php/opportunities/default/details?id=57">Ocean Place</a>";}', 3, 'a:1:{s:9:"column_11";a:1:{i:0;s:57:"Was not found and this row will be skipped during import.";}}'),
(37, '', '', '', '', '', '', '', '', 'Oceanfront Plaza', '', '', 'Oceanfront Plaza', '', '', 'Under Construction', '', 'Video', '', '$52.95', 'USD', '', '', '', '', '', '', '', '', '', '', 'Yes', '250', '', '', '', 2, 'a:1:{i:0;s:156:"Opportunity saved correctly: <a class="simple-link" target="blank" href="/opticaltel/app/index.php/opportunities/default/details?id=58">Oceanfront Plaza</a>";}', 3, 'a:1:{s:9:"column_11";a:1:{i:0;s:57:"Was not found and this row will be skipped during import.";}}'),
(38, '', '', '', '', '', '', '', '', 'OceanView Place', '', '', 'OceanView Place', '', '', 'Under Construction', '', 'Video', '', '$49.95', 'USD', '', '', '', '', '', '', '', '', '', '', 'Yes', '250', '', '', '', 2, 'a:1:{i:0;s:155:"Opportunity saved correctly: <a class="simple-link" target="blank" href="/opticaltel/app/index.php/opportunities/default/details?id=59">OceanView Place</a>";}', 3, 'a:1:{s:9:"column_11";a:1:{i:0;s:57:"Was not found and this row will be skipped during import.";}}'),
(39, '', '', '', '', '', '', '', '', 'Parker Plaza', '', '', 'Parker Plaza', '', '', 'Under Construction', '', 'Video', '', '$48.95', 'USD', '', '', '', '', '', '', '', '', '', '', 'Yes', '250', '', '', '', 2, 'a:1:{i:0;s:152:"Opportunity saved correctly: <a class="simple-link" target="blank" href="/opticaltel/app/index.php/opportunities/default/details?id=60">Parker Plaza</a>";}', 3, 'a:1:{s:9:"column_11";a:1:{i:0;s:57:"Was not found and this row will be skipped during import.";}}'),
(40, '', '', '', '', '', '', '', '', 'Patrician of the Palm Beaches', '', '', 'Patrician of the Palm Beaches', '', '', 'Under Construction', '', 'Video', '', '$38.95', 'USD', '', '', '', '', '', '', '', '', '', '', 'Yes', '250', '', '', '', 2, 'a:1:{i:0;s:169:"Opportunity saved correctly: <a class="simple-link" target="blank" href="/opticaltel/app/index.php/opportunities/default/details?id=61">Patrician of the Palm Beaches</a>";}', 3, 'a:1:{s:9:"column_11";a:1:{i:0;s:57:"Was not found and this row will be skipped during import.";}}'),
(41, '', '', '', '', '', '', '', '', 'Pine Ridge Condo', '', '', 'Pine Ridge Condo', '', '', 'Under Construction', '', 'Video', '', '$52.95', 'USD', '', '', '', '', '', '', '', '', '', '', 'Yes', '250', '', '', '', 2, 'a:1:{i:0;s:156:"Opportunity saved correctly: <a class="simple-link" target="blank" href="/opticaltel/app/index.php/opportunities/default/details?id=62">Pine Ridge Condo</a>";}', 3, 'a:1:{s:9:"column_11";a:1:{i:0;s:57:"Was not found and this row will be skipped during import.";}}'),
(42, '', '', '', '', '', '', '', '', 'Pinehurst Club (Net)', '', '', 'Pinehurst Club (Net)', '', '', 'Under Construction', '', 'Video', '', '$0.00', 'USD', '', '', '', '', '', '', '', '', '', '', 'Yes', '250', '', '', '', 2, 'a:1:{i:0;s:160:"Opportunity saved correctly: <a class="simple-link" target="blank" href="/opticaltel/app/index.php/opportunities/default/details?id=63">Pinehurst Club (Net)</a>";}', 3, 'a:1:{s:9:"column_11";a:1:{i:0;s:57:"Was not found and this row will be skipped during import.";}}'),
(43, '', '', '', '', '', '', '', '', 'Plaza of Bal Harbour', '', '', 'Plaza of Bal Harbour', '', '', 'Under Construction', '', 'Video', '', '$46.95', 'USD', '', '', '', '', '', '', '', '', '', '', 'Yes', '250', '', '', '', 2, 'a:1:{i:0;s:160:"Opportunity saved correctly: <a class="simple-link" target="blank" href="/opticaltel/app/index.php/opportunities/default/details?id=64">Plaza of Bal Harbour</a>";}', 3, 'a:1:{s:9:"column_11";a:1:{i:0;s:57:"Was not found and this row will be skipped during import.";}}'),
(44, '', '', '', '', '', '', '', '', 'Point East Condo', '', '', 'Point East Condo', '', '', 'Under Construction', '', 'Video', '', '$39.95', 'USD', '', '', '', '', '', '', '', '', '', '', 'Yes', '250', '', '', '', 2, 'a:1:{i:0;s:156:"Opportunity saved correctly: <a class="simple-link" target="blank" href="/opticaltel/app/index.php/opportunities/default/details?id=65">Point East Condo</a>";}', 3, 'a:1:{s:9:"column_11";a:1:{i:0;s:57:"Was not found and this row will be skipped during import.";}}'),
(45, '', '', '', '', '', '', '', '', 'River Bridge', '', '', 'River Bridge', '', '', 'Under Construction', '', 'Video', '', '$69.95', 'USD', '', '', '', '', '', '', '', '', '', '', 'Yes', '250', '', '', '', 2, 'a:1:{i:0;s:152:"Opportunity saved correctly: <a class="simple-link" target="blank" href="/opticaltel/app/index.php/opportunities/default/details?id=66">River Bridge</a>";}', 3, 'a:1:{s:9:"column_11";a:1:{i:0;s:57:"Was not found and this row will be skipped during import.";}}'),
(46, '', '', '', '', '', '', '', '', 'Sand Pebble Beach Condominiums', '', '', 'Sand Pebble Beach Condominiums', '', '', 'Under Construction', '', 'Video', '', '$79.95', 'USD', '', '', '', '', '', '', '', '', '', '', 'Yes', '250', '', '', '', 2, 'a:1:{i:0;s:170:"Opportunity saved correctly: <a class="simple-link" target="blank" href="/opticaltel/app/index.php/opportunities/default/details?id=67">Sand Pebble Beach Condominiums</a>";}', 3, 'a:1:{s:9:"column_11";a:1:{i:0;s:57:"Was not found and this row will be skipped during import.";}}'),
(47, '', '', '', '', '', '', '', '', 'Seamark (Net)', '', '', 'Seamark (Net)', '', '', 'Under Construction', '', 'Video', '', '$49.52', 'USD', '', '', '', '', '', '', '', '', '', '', 'Yes', '250', '', '', '', 2, 'a:1:{i:0;s:153:"Opportunity saved correctly: <a class="simple-link" target="blank" href="/opticaltel/app/index.php/opportunities/default/details?id=68">Seamark (Net)</a>";}', 3, 'a:1:{s:9:"column_11";a:1:{i:0;s:57:"Was not found and this row will be skipped during import.";}}'),
(48, '', '', '', '', '', '', '', '', 'Strada 315 (Data)', '', '', 'Strada 315 (Data)', '', '', 'Under Construction', '', 'Video', '', '$17.98', 'USD', '', '', '', '', '', '', '', '', '', '', 'Yes', '250', '', '', '', 2, 'a:1:{i:0;s:157:"Opportunity saved correctly: <a class="simple-link" target="blank" href="/opticaltel/app/index.php/opportunities/default/details?id=69">Strada 315 (Data)</a>";}', 3, 'a:1:{s:9:"column_11";a:1:{i:0;s:57:"Was not found and this row will be skipped during import.";}}'),
(49, '', '', '', '', '', '', '', '', 'Strada 315 (Video)', '', '', 'Strada 315 (Video)', '', '', 'Under Construction', '', 'Video', '', '$31.99', 'USD', '', '', '', '', '', '', '', '', '', '', 'Yes', '250', '', '', '', 2, 'a:1:{i:0;s:158:"Opportunity saved correctly: <a class="simple-link" target="blank" href="/opticaltel/app/index.php/opportunities/default/details?id=70">Strada 315 (Video)</a>";}', 3, 'a:1:{s:9:"column_11";a:1:{i:0;s:57:"Was not found and this row will be skipped during import.";}}'),
(50, '', '', '', '', '', '', '', '', 'Sunset Bay (Data)', '', '', 'Sunset Bay (Data)', '', '', 'Under Construction', '', 'Video', '', '$19.95', 'USD', '', '', '', '', '', '', '', '', '', '', 'Yes', '250', '', '', '', 2, 'a:1:{i:0;s:157:"Opportunity saved correctly: <a class="simple-link" target="blank" href="/opticaltel/app/index.php/opportunities/default/details?id=71">Sunset Bay (Data)</a>";}', 3, 'a:1:{s:9:"column_11";a:1:{i:0;s:57:"Was not found and this row will be skipped during import.";}}'),
(51, '', '', '', '', '', '', '', '', 'Sunset Bay (Video)', '', '', 'Sunset Bay (Video)', '', '', 'Under Construction', '', 'Video', '', '$14.19', 'USD', '', '', '', '', '', '', '', '', '', '', 'Yes', '250', '', '', '', 2, 'a:1:{i:0;s:158:"Opportunity saved correctly: <a class="simple-link" target="blank" href="/opticaltel/app/index.php/opportunities/default/details?id=72">Sunset Bay (Video)</a>";}', 3, 'a:1:{s:9:"column_11";a:1:{i:0;s:57:"Was not found and this row will be skipped during import.";}}'),
(52, '', '', '', '', '', '', '', '', 'The Atriums', '', '', 'The Atriums', '', '', 'Under Construction', '', 'Video', '', '$69.95', 'USD', '', '', '', '', '', '', '', '', '', '', 'Yes', '250', '', '', '', 2, 'a:1:{i:0;s:151:"Opportunity saved correctly: <a class="simple-link" target="blank" href="/opticaltel/app/index.php/opportunities/default/details?id=73">The Atriums</a>";}', 3, 'a:1:{s:9:"column_11";a:1:{i:0;s:57:"Was not found and this row will be skipped during import.";}}'),
(53, '', '', '', '', '', '', '', '', 'The Residences on Hollywood Beach Proposal (Net)', '', '', 'The Residences on Hollywood Beach Proposal (Net)', '', '', 'Under Construction', '', 'Video', '', '$25.39', 'USD', '', '', '', '', '', '', '', '', '', '', 'Yes', '250', '', '', '', 2, 'a:1:{i:0;s:188:"Opportunity saved correctly: <a class="simple-link" target="blank" href="/opticaltel/app/index.php/opportunities/default/details?id=74">The Residences on Hollywood Beach Proposal (Net)</a>";}', 3, 'a:1:{s:9:"column_11";a:1:{i:0;s:57:"Was not found and this row will be skipped during import.";}}'),
(54, '', '', '', '', '', '', '', '', 'The Summit (Net)', '', '', 'The Summit (Net)', '', '', 'Under Construction', '', 'Video', '', '$5.00', 'USD', '', '', '', '', '', '', '', '', '', '', 'Yes', '250', '', '', '', 2, 'a:1:{i:0;s:156:"Opportunity saved correctly: <a class="simple-link" target="blank" href="/opticaltel/app/index.php/opportunities/default/details?id=75">The Summit (Net)</a>";}', 3, 'a:1:{s:9:"column_11";a:1:{i:0;s:57:"Was not found and this row will be skipped during import.";}}'),
(55, '', '', '', '', '', '', '', '', 'The Tides @ Bridgeside Square', '', '', 'The Tides @ Bridgeside Square', '', '', 'Under Construction', '', 'Video', '', '$69.95', 'USD', '', '', '', '', '', '', '', '', '', '', 'Yes', '250', '', '', '', 2, 'a:1:{i:0;s:169:"Opportunity saved correctly: <a class="simple-link" target="blank" href="/opticaltel/app/index.php/opportunities/default/details?id=76">The Tides @ Bridgeside Square</a>";}', 3, 'a:1:{s:9:"column_11";a:1:{i:0;s:57:"Was not found and this row will be skipped during import.";}}'),
(56, '', '', '', '', '', '', '', '', 'Topaz North', '', '', 'Topaz North', '', '', 'Under Construction', '', 'Video', '', '$34.39', 'USD', '', '', '', '', '', '', '', '', '', '', 'Yes', '250', '', '', '', 2, 'a:1:{i:0;s:151:"Opportunity saved correctly: <a class="simple-link" target="blank" href="/opticaltel/app/index.php/opportunities/default/details?id=77">Topaz North</a>";}', 3, 'a:1:{s:9:"column_11";a:1:{i:0;s:57:"Was not found and this row will be skipped during import.";}}'),
(57, '', '', '', '', '', '', '', '', 'TOWERS OF KENDAL LAKES', '', '', 'TOWERS OF KENDAL LAKES', '', '', 'Under Construction', '', 'Video', '', '$37.95', 'USD', '', '', '', '', '', '', '', '', '', '', 'Yes', '250', '', '', '', 2, 'a:1:{i:0;s:162:"Opportunity saved correctly: <a class="simple-link" target="blank" href="/opticaltel/app/index.php/opportunities/default/details?id=78">TOWERS OF KENDAL LAKES</a>";}', 3, 'a:1:{s:9:"column_11";a:1:{i:0;s:57:"Was not found and this row will be skipped during import.";}}'),
(58, '', '', '', '', '', '', '', '', 'Tropic Harbor', '', '', 'Tropic Harbor', '', '', 'Under Construction', '', 'Video', '', '$29.43', 'USD', '', '', '', '', '', '', '', '', '', '', 'Yes', '250', '', '', '', 2, 'a:1:{i:0;s:153:"Opportunity saved correctly: <a class="simple-link" target="blank" href="/opticaltel/app/index.php/opportunities/default/details?id=79">Tropic Harbor</a>";}', 3, 'a:1:{s:9:"column_11";a:1:{i:0;s:57:"Was not found and this row will be skipped during import.";}}'),
(59, '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', 'Yes', '250', '', '', '', 3, 'a:4:{i:0;s:108:"Opportunity - Opportunity Name This field is required and neither a value nor a default value was specified.";i:1;s:58:"Opportunity - Stage Pick list value required, but missing.";i:2;s:66:"Opportunity - Opportunity Name - Opportunity Name cannot be blank.";i:3;s:44:"Opportunity - Stage - Stage cannot be blank.";}', 3, 'a:2:{s:8:"column_8";a:1:{i:0;s:13:"Is  required.";}s:9:"column_14";a:1:{i:0;s:13:"Is  required.";}}'),
(60, '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', 'Yes', '250', '', '', '', 3, 'a:4:{i:0;s:108:"Opportunity - Opportunity Name This field is required and neither a value nor a default value was specified.";i:1;s:58:"Opportunity - Stage Pick list value required, but missing.";i:2;s:66:"Opportunity - Opportunity Name - Opportunity Name cannot be blank.";i:3;s:44:"Opportunity - Stage - Stage cannot be blank.";}', 3, 'a:2:{s:8:"column_8";a:1:{i:0;s:13:"Is  required.";}s:9:"column_14";a:1:{i:0;s:13:"Is  required.";}}');

-- --------------------------------------------------------

--
-- Table structure for table `importtable3`
--

CREATE TABLE IF NOT EXISTS `importtable3` (
`id` int(11) unsigned NOT NULL,
  `column_0` varchar(65) COLLATE utf8_unicode_ci DEFAULT NULL,
  `column_1` varchar(5) COLLATE utf8_unicode_ci DEFAULT NULL,
  `column_2` varchar(7) COLLATE utf8_unicode_ci DEFAULT NULL,
  `column_3` varchar(16) COLLATE utf8_unicode_ci DEFAULT NULL,
  `column_4` varchar(13) COLLATE utf8_unicode_ci DEFAULT NULL,
  `column_5` varchar(13) COLLATE utf8_unicode_ci DEFAULT NULL,
  `column_6` varchar(16) COLLATE utf8_unicode_ci DEFAULT NULL,
  `column_7` varchar(14) COLLATE utf8_unicode_ci DEFAULT NULL,
  `column_8` varchar(13) COLLATE utf8_unicode_ci DEFAULT NULL,
  `column_9` varchar(16) COLLATE utf8_unicode_ci DEFAULT NULL,
  `column_10` varchar(15) COLLATE utf8_unicode_ci DEFAULT NULL,
  `column_11` varchar(15) COLLATE utf8_unicode_ci DEFAULT NULL,
  `column_12` varchar(14) COLLATE utf8_unicode_ci DEFAULT NULL,
  `column_13` varchar(4) COLLATE utf8_unicode_ci DEFAULT NULL,
  `column_14` varchar(5) COLLATE utf8_unicode_ci DEFAULT NULL,
  `column_15` varchar(11) COLLATE utf8_unicode_ci DEFAULT NULL,
  `column_16` varchar(15) COLLATE utf8_unicode_ci DEFAULT NULL,
  `column_17` varchar(11) COLLATE utf8_unicode_ci DEFAULT NULL,
  `status` int(11) unsigned DEFAULT NULL,
  `serializedMessages` text COLLATE utf8_unicode_ci,
  `analysisStatus` int(11) unsigned DEFAULT NULL,
  `serializedAnalysisMessages` text COLLATE utf8_unicode_ci
) ENGINE=InnoDB AUTO_INCREMENT=62 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

--
-- Dumping data for table `importtable3`
--

INSERT INTO `importtable3` (`id`, `column_0`, `column_1`, `column_2`, `column_3`, `column_4`, `column_5`, `column_6`, `column_7`, `column_8`, `column_9`, `column_10`, `column_11`, `column_12`, `column_13`, `column_14`, `column_15`, `column_16`, `column_17`, `status`, `serializedMessages`, `analysisStatus`, `serializedAnalysisMessages`) VALUES
(1, 'Name', 'Units', 'Closed', 'Proposed Billing', 'Bulk Services', 'Contract Type', 'Price Per Unit', 'Bulk Revenue', 'Bulk Margin', 'Retail Revenue', 'Retail Margin', 'Total Revenue', 'Total Margin', 'Term', 'Build', 'CapX', 'Salesman', 'Sales Stage', NULL, NULL, NULL, NULL),
(2, '3360 Condo-New Contract', '90', '2015-Q4', '2016-Q3', 'Double Bulk', 'New', '$69.95', '$6,296', '$3,652', '$1,350', '$675', '$7,646', '$10,906', '8', 'RF', '$120,000', 'Bob Allecca', 'UC', 3, 'a:1:{i:0;s:81:"Contract - Blended Bulk Margin - Blended Bulk Margin is too big (maximum is 100).";}', 3, 'a:1:{s:8:"column_8";a:1:{i:0;s:11:"Is invalid.";}}'),
(3, '400 Association (Data)-Renewal Contract', '64', '2015-Q1', '2015-Q2', 'Double Bulk', 'Renewal', '$28.95', '$1,853', '$1,600', '$960', '$480', '$2,813', '$25,961', '7', 'RF', '$48,000', 'Bob/Dee', 'UC', 3, 'a:1:{i:0;s:81:"Contract - Blended Bulk Margin - Blended Bulk Margin is too big (maximum is 100).";}', 3, 'a:1:{s:8:"column_8";a:1:{i:0;s:11:"Is invalid.";}}'),
(4, '9 Island (Net)-Renewal Contract', '271', 'N/A', 'N/A', 'Single Bulk', 'Renewal', '$5.95', '$1,612.45', '$1,200.00', '$7,692.30', '$3,869.58', '$9,304.75', '$14,566.54', '7', 'RF', '$100,000', 'Bob/Dee', 'FP', 3, 'a:2:{i:0;s:54:"Contract - Blended Bulk Margin Invalid integer format.";i:1;s:69:"Contract - Blended Bulk Margin - Blended Bulk Margin cannot be blank.";}', 3, 'a:1:{s:8:"column_8";a:1:{i:0;s:11:"Is invalid.";}}'),
(5, 'Alexander Hotel/Condo-New Contract', '230', 'N/A', 'N/A', 'Double Bulk', 'New', '$44.95', '$10,338.50', '$7,003.47', '$2,457.84', '$1,155.00', '$12,796.34', '$6,045.00', '7', 'RF', '$149,500', 'Bob/Antoinette', 'FP', 3, 'a:2:{i:0;s:54:"Contract - Blended Bulk Margin Invalid integer format.";i:1;s:69:"Contract - Blended Bulk Margin - Blended Bulk Margin cannot be blank.";}', 3, 'a:1:{s:8:"column_8";a:1:{i:0;s:11:"Is invalid.";}}'),
(6, 'Artesia-New Contract', '1000', 'N/A', 'N/A', 'Double Bulk', 'New', '$68.95', '$68,950.00', '$47,947.83', '$5,114.88', '$1,744.96', '$74,064.88', '$8,927.27', '10', 'FTTU', '$1,726,122', 'CJ/Bob', 'FP', 3, 'a:2:{i:0;s:54:"Contract - Blended Bulk Margin Invalid integer format.";i:1;s:69:"Contract - Blended Bulk Margin - Blended Bulk Margin cannot be blank.";}', 3, 'a:1:{s:8:"column_8";a:1:{i:0;s:11:"Is invalid.";}}'),
(7, 'Aventi-New Contract', '180', '2014-Q3', '2015-Q1', 'Double Bulk', 'New', '$72.61', '$13,070', '$8,389', '$2,700', '$1,350', '$15,770', '$2,920', '7', 'FTTU', '$225,000', 'Eric/Alfredo', 'CR', 3, 'a:1:{i:0;s:81:"Contract - Blended Bulk Margin - Blended Bulk Margin is too big (maximum is 100).";}', 3, 'a:1:{s:8:"column_8";a:1:{i:0;s:11:"Is invalid.";}}'),
(8, 'Balmoral Condo-New Contract', '423', 'N/A', 'N/A', 'Double Bulk', 'New', '$69.95', '$29,588.85', '$18,007.26', '$7,806.42', '$0.00', '$37,395.27', '$15,464.40', '10', 'FTTU', '$650,000', 'CJ/Bob', 'FP', 3, 'a:2:{i:0;s:54:"Contract - Blended Bulk Margin Invalid integer format.";i:1;s:69:"Contract - Blended Bulk Margin - Blended Bulk Margin cannot be blank.";}', 3, 'a:1:{s:8:"column_8";a:1:{i:0;s:11:"Is invalid.";}}'),
(9, 'Bravura 1 Condo-New Contract', '192', 'N/A', 'N/A', 'Double Bulk', 'New', '$54.95', '$10,550.40', '$6,435.74', '$1,134.00', '$4,252.50', '$11,684.40', '$5,386.50', '8', 'RF', '$144,000', 'Bob/Antoinette', 'IC', 3, 'a:2:{i:0;s:54:"Contract - Blended Bulk Margin Invalid integer format.";i:1;s:69:"Contract - Blended Bulk Margin - Blended Bulk Margin cannot be blank.";}', 3, 'a:1:{s:8:"column_8";a:1:{i:0;s:11:"Is invalid.";}}'),
(10, 'Christopher House-New Contract', '96', '2015-Q3', '2016-Q3', 'Double Bulk', 'New', '$69.95', '$6,715.20', '$4,096.12', '$2,712.43', '$2,617.50', '$9,427.63', '$8,899.50', '10', 'FTTU', '$100,000', 'C.J.', 'UC', 3, 'a:2:{i:0;s:54:"Contract - Blended Bulk Margin Invalid integer format.";i:1;s:69:"Contract - Blended Bulk Margin - Blended Bulk Margin cannot be blank.";}', 3, 'a:1:{s:8:"column_8";a:1:{i:0;s:11:"Is invalid.";}}'),
(11, 'Cloisters (Net)-Renewal Contract', '140', 'N/A', 'N/A', 'Single Bulk', 'Renewal', '$16.67', '$2,334', '$1,870', '$2,100', '$1,050', '$4,434', '$5,365', '8', 'RF', '$100,000', 'Bob Allecca', 'CN', 3, 'a:1:{i:0;s:81:"Contract - Blended Bulk Margin - Blended Bulk Margin is too big (maximum is 100).";}', 3, 'a:1:{s:8:"column_8";a:1:{i:0;s:11:"Is invalid.";}}'),
(12, 'Commodore Club South-New Contract', '186', 'N/A', 'N/A', 'Double Bulk', 'New', '$64.95', '$12,080.70', '$7,610.84', '$1,155.50', '$630.00', '$13,236.20', '$2,507.00', '8', 'RF', '$139,500', 'Bob/Antoinette', 'IC', 3, 'a:2:{i:0;s:54:"Contract - Blended Bulk Margin Invalid integer format.";i:1;s:69:"Contract - Blended Bulk Margin - Blended Bulk Margin cannot be blank.";}', 3, 'a:1:{s:8:"column_8";a:1:{i:0;s:11:"Is invalid.";}}'),
(13, 'Commodore Plaza-New Contract', '654', 'N/A', 'N/A', 'Double Bulk', 'New', '$59.95', '$39,207.30', '$25,876.82', '$772.51', '$83.73', '$39,979.81', '$1,323.77', '10', 'FTTU', '$784,800', 'Bob', 'FP', 3, 'a:2:{i:0;s:54:"Contract - Blended Bulk Margin Invalid integer format.";i:1;s:69:"Contract - Blended Bulk Margin - Blended Bulk Margin cannot be blank.";}', 3, 'a:1:{s:8:"column_8";a:1:{i:0;s:11:"Is invalid.";}}'),
(14, 'Cypress Trails-New Contract', '364', '2013-Q2', 'Ramp Up', 'Double Bulk', 'New', '$46.95', '$17,090', '$12,817', '$5,460', '$2,730', '$22,550', '$49,693', '15', 'RF', '$475,355', 'Luis', 'UC', 3, 'a:1:{i:0;s:81:"Contract - Blended Bulk Margin - Blended Bulk Margin is too big (maximum is 100).";}', 3, 'a:1:{s:8:"column_8";a:1:{i:0;s:11:"Is invalid.";}}'),
(15, 'East Pointe Towers-New Contract', '274', 'N/A', 'N/A', 'Double Bulk', 'New', '$52.95', '$14,508.30', '$8,918.25', '$5,423.30', '$2,495.37', '$19,931.60', '$11,905.20', '8', 'RF', '$205,500', 'Bob', 'FP', 3, 'a:2:{i:0;s:54:"Contract - Blended Bulk Margin Invalid integer format.";i:1;s:69:"Contract - Blended Bulk Margin - Blended Bulk Margin cannot be blank.";}', 3, 'a:1:{s:8:"column_8";a:1:{i:0;s:11:"Is invalid.";}}'),
(16, 'Emerald (Net)-Renewal Contract', '108', '2015-Q1', '2015-Q4', 'Single Bulk', 'Renewal', '$8.17', '$882', '$700', '$1,620', '$810', '$2,502', '$112,500', '8', 'RF', '$100,000', 'Bob/Dee', 'UC', 3, 'a:1:{i:0;s:81:"Contract - Blended Bulk Margin - Blended Bulk Margin is too big (maximum is 100).";}', 3, 'a:1:{s:8:"column_8";a:1:{i:0;s:11:"Is invalid.";}}'),
(17, 'Fairways of Tamarac-New Contract', '174', 'N/A', 'N/A', 'Single Bulk', 'New', '$34.95', '$6,081.30', '$3,749.73', '$841.46', '$438.75', '$6,922.76', '$2,308.41', '8', 'RF', '$113,100', 'Bob', 'FP', 3, 'a:2:{i:0;s:54:"Contract - Blended Bulk Margin Invalid integer format.";i:1;s:69:"Contract - Blended Bulk Margin - Blended Bulk Margin cannot be blank.";}', 3, 'a:1:{s:8:"column_8";a:1:{i:0;s:11:"Is invalid.";}}'),
(18, 'Garden Estates (Net)-Renewal Contract', '445', '2014-Q3', 'Ramp Up', 'Double Bulk', 'Renewal', '$4.00', '$1,780', '$1,780', '$6,675', '$3,338', '$8,455', '$6,714', '10', 'FTTU', '$63,000', 'Eric/Dee', 'CR', 3, 'a:1:{i:0;s:81:"Contract - Blended Bulk Margin - Blended Bulk Margin is too big (maximum is 100).";}', 3, 'a:1:{s:8:"column_8";a:1:{i:0;s:11:"Is invalid.";}}'),
(19, 'Glades Country Club (Net)-Renewal Contract', '1255', 'N/A', 'N/A', 'Double Bulk', 'Renewal', '$34.57', '$43,385.35', '$37,500.00', '$0.00', '$0.00', '$43,385.35', '$68,151.80', '8', 'RF', '$350,000', 'Eric/Bob/Dee', 'LP', 3, 'a:2:{i:0;s:54:"Contract - Blended Bulk Margin Invalid integer format.";i:1;s:69:"Contract - Blended Bulk Margin - Blended Bulk Margin cannot be blank.";}', 3, 'a:1:{s:8:"column_8";a:1:{i:0;s:11:"Is invalid.";}}'),
(20, 'Harbour House-New Contract', '192', 'N/A', 'N/A', 'Single Bulk', 'New', '$59.95', '$11,510.40', '$7,021.34', '$47,566.00', '$12,750.00', '$59,076.40', '$95,175.00', '10', 'FTTU', '$250,000', 'CJ/Bob', 'FP', 3, 'a:2:{i:0;s:54:"Contract - Blended Bulk Margin Invalid integer format.";i:1;s:69:"Contract - Blended Bulk Margin - Blended Bulk Margin cannot be blank.";}', 3, 'a:1:{s:8:"column_8";a:1:{i:0;s:11:"Is invalid.";}}'),
(21, 'Hillsboro Cove-New Contract', '318', 'N/A', 'N/A', 'Single Bulk', 'New', '$37.95', '$12,068.10', '$7,723.58', '$2,648.70', '$1,687.50', '$14,716.80', '$6,322.50', '8', 'RF', '$238,500', 'Bob', 'IC', 3, 'a:2:{i:0;s:54:"Contract - Blended Bulk Margin Invalid integer format.";i:1;s:69:"Contract - Blended Bulk Margin - Blended Bulk Margin cannot be blank.";}', 3, 'a:1:{s:8:"column_8";a:1:{i:0;s:11:"Is invalid.";}}'),
(22, 'Isles at Grand Bay-New Contract', '2000', '2013-Q3', 'Ramp Up', 'Retail', 'New', '$0.00', '$0', '$0', '$150,000', '$112,500', '$150,000', '$112,500', 'N/A', 'FTTH', '$2,250,000', 'Mario Sr./Luis', 'UC', 3, 'a:2:{i:0;s:62:"Contract - ROI Total Months Calculator Invalid integer format.";i:1;s:85:"Contract - ROI Total Months Calculator - ROI Total Months Calculator cannot be blank.";}', 3, 'a:2:{s:8:"column_8";a:1:{i:0;s:11:"Is invalid.";}s:9:"column_13";a:1:{i:0;s:11:"Is invalid.";}}'),
(23, 'Kenilworth (Net)-Renewal Contract', '158', '2015-Q2', '2015-Q3', 'Double Bulk', 'Renewal', '$31.45', '$4,969', '$4,180', '$2,370', '$1,185', '$7,339', '$8,241', '6', 'FTTU', '$210,000', 'Eric/Dee', 'UC', 3, 'a:1:{i:0;s:81:"Contract - Blended Bulk Margin - Blended Bulk Margin is too big (maximum is 100).";}', 3, 'a:1:{s:8:"column_8";a:1:{i:0;s:11:"Is invalid.";}}'),
(24, 'Key Largo-New Contract', '285', '2014-Q1', 'Ramp Up', 'Double Bulk', 'New', '$43.95', '$12,526', '$8,768', '$4,275', '$2,138', '$16,801', '$10,688', '7', 'RF', '$279,904', 'Mario Jr', 'UC', 3, 'a:1:{i:0;s:81:"Contract - Blended Bulk Margin - Blended Bulk Margin is too big (maximum is 100).";}', 3, 'a:1:{s:8:"column_8";a:1:{i:0;s:11:"Is invalid.";}}'),
(25, 'Lake Worth Towers-Renewal Contract', '199', 'N/A', 'N/A', 'Single Bulk', 'Renewal', '$19.95', '$3,970', '$3,112', '$2,985', '$1,493', '$6,955', '$4,605', '10', 'RF', '$194,000', 'Bob/Dee', 'AD', 3, 'a:1:{i:0;s:81:"Contract - Blended Bulk Margin - Blended Bulk Margin is too big (maximum is 100).";}', 3, 'a:1:{s:8:"column_8";a:1:{i:0;s:11:"Is invalid.";}}'),
(26, 'Lakes of Savannah -New Contract', '242', 'N/A', 'N/A', 'Single Bulk', 'New', '$37.95', '$9,183.90', '$5,510.34', '$2,965.88', '$10,147.30', '$12,149.78', '$13,973.82', '8', 'RF', '$229,900', 'Bob/Dee', 'IC', 3, 'a:2:{i:0;s:54:"Contract - Blended Bulk Margin Invalid integer format.";i:1;s:69:"Contract - Blended Bulk Margin - Blended Bulk Margin cannot be blank.";}', 3, 'a:1:{s:8:"column_8";a:1:{i:0;s:11:"Is invalid.";}}'),
(27, 'Las Verdes-New Contract', '1232', 'N/A', 'N/A', 'Single Bulk', 'New', '$36.95', '$45,522.40', '$27,313.44', '$1,748.21', '$2,310.00', '$47,270.61', '$5,756.52', '8', 'RF', '$924,000', 'Bob', 'FP', 3, 'a:2:{i:0;s:54:"Contract - Blended Bulk Margin Invalid integer format.";i:1;s:69:"Contract - Blended Bulk Margin - Blended Bulk Margin cannot be blank.";}', 3, 'a:1:{s:8:"column_8";a:1:{i:0;s:11:"Is invalid.";}}'),
(28, 'Marina Village (Net)-Renewal Contract', '349', '2015-Q1', '2015-Q3', 'Double Bulk', 'Renewal', '$19.43', '$6,781', '$6,282', '$5,235', '$2,618', '$12,016', '$15,547', '8', 'FTTU', '$375,000', 'Bob/Dee', 'UC', 3, 'a:1:{i:0;s:81:"Contract - Blended Bulk Margin - Blended Bulk Margin is too big (maximum is 100).";}', 3, 'a:1:{s:8:"column_8";a:1:{i:0;s:11:"Is invalid.";}}'),
(29, 'Mayfair House Condo-New Contract', '223', 'N/A', 'N/A', 'Double Bulk', 'New', '$55.95', '$12,476.85', '$7,610.88', '$4,087.74', '$1,366.20', '$16,564.59', '$9,573.15', '8', 'RF', '$273,992', 'Bob', 'CN', 3, 'a:2:{i:0;s:54:"Contract - Blended Bulk Margin Invalid integer format.";i:1;s:69:"Contract - Blended Bulk Margin - Blended Bulk Margin cannot be blank.";}', 3, 'a:1:{s:8:"column_8";a:1:{i:0;s:11:"Is invalid.";}}'),
(30, 'Meadowbrook # 4-New Contract', '244', '2015-Q1', '2015-Q4', 'Single Bulk', 'New', '$36.95', '$9,016', '$6,727', '$3,660', '$1,830', '$12,676', '$5,118', '10', 'RF', '$201,300', 'Bob/Dee', 'UC', 3, 'a:1:{i:0;s:81:"Contract - Blended Bulk Margin - Blended Bulk Margin is too big (maximum is 100).";}', 3, 'a:1:{s:8:"column_8";a:1:{i:0;s:11:"Is invalid.";}}'),
(31, 'Midtown Doral-New Contract', '1700', 'N/A', 'Ramp Up', 'Triple Bulk', 'New', '$69.95', '$118,915', '$82,425', '$25,500', '$12,750', '$144,415', '$1,510', '10', 'FTTU', '$1,700,000', 'Mario Sr./Luis', 'UC', 3, 'a:1:{i:0;s:81:"Contract - Blended Bulk Margin - Blended Bulk Margin is too big (maximum is 100).";}', 3, 'a:1:{s:8:"column_8";a:1:{i:0;s:11:"Is invalid.";}}'),
(32, 'Midtown Retail-New Contract', '150', 'N/A', 'Ramp Up', 'Retail', 'New', '$0.00', '$0', '$0', '$90,000', '$58,000', '$90,000', '$58,000', '10', 'FTTU', '$165,000', 'Mario Sr./Luis', 'UC', 2, 'a:1:{i:0;s:160:"Contract saved correctly: <a class="simple-link" target="blank" href="/opticaltel/app/index.php/contracts/default/details?id=13">Midtown Retail-New Contract</a>";}', 3, 'a:1:{s:8:"column_8";a:1:{i:0;s:11:"Is invalid.";}}'),
(33, 'Mystic Point-New Contract', '482', 'N/A', 'N/A', 'Double Bulk', 'New', '$77.95', '$37,571.90', '$23,151.80', '$0.00', '$45,000.00', '$37,571.90', '$58,000.00', '10', 'FTTU', '$860,000', 'CJ/Bob', 'FP', 3, 'a:2:{i:0;s:54:"Contract - Blended Bulk Margin Invalid integer format.";i:1;s:69:"Contract - Blended Bulk Margin - Blended Bulk Margin cannot be blank.";}', 3, 'a:1:{s:8:"column_8";a:1:{i:0;s:11:"Is invalid.";}}'),
(34, 'Nirvana Condos -New Contract', '385', 'N/A', 'N/A', 'Double Bulk', 'New', '$49.95', '$19,230.75', '$11,730.76', '$7,739.16', '$2,835.78', '$26,969.91', '$28,158.61', '8', 'RF', '$30,800', 'Bob/Antoinette', 'FP', 3, 'a:2:{i:0;s:54:"Contract - Blended Bulk Margin Invalid integer format.";i:1;s:69:"Contract - Blended Bulk Margin - Blended Bulk Margin cannot be blank.";}', 3, 'a:1:{s:8:"column_8";a:1:{i:0;s:11:"Is invalid.";}}'),
(35, 'Northern Star (Net)-Renewal Contract', '22', '2015-Q2', '2015-Q4', 'Double Bulk', 'Renewal', '$19.03', '$419', '$580', '$330', '$165', '$749', '$9,411', '8', 'RF', '$70,000', 'Bob Allecca', 'UC', 3, 'a:1:{i:0;s:81:"Contract - Blended Bulk Margin - Blended Bulk Margin is too big (maximum is 100).";}', 3, 'a:1:{s:8:"column_8";a:1:{i:0;s:11:"Is invalid.";}}'),
(36, 'OakBridge-New Contract', '279', 'N/A', 'N/A', 'Double Bulk', 'New', '$69.95', '$19,516.05', '$13,661.24', '$0.00', '$1,803.16', '$19,516.05', '$1,830.00', '10', 'FTTH', '$320,850', 'Bob/Antoinette', 'FP', 3, 'a:2:{i:0;s:54:"Contract - Blended Bulk Margin Invalid integer format.";i:1;s:69:"Contract - Blended Bulk Margin - Blended Bulk Margin cannot be blank.";}', 3, 'a:1:{s:8:"column_8";a:1:{i:0;s:11:"Is invalid.";}}'),
(37, 'Ocean Place-New Contract', '256', 'N/A', 'N/A', 'Double Bulk', 'New', '$49.95', '$12,787.20', '$8,178.70', '$3,489.92', '$748.57', '$16,277.12', '$6,286.88', '10', 'FTTU', '$153,600', 'CJ/Bob', 'FP', 3, 'a:2:{i:0;s:54:"Contract - Blended Bulk Margin Invalid integer format.";i:1;s:69:"Contract - Blended Bulk Margin - Blended Bulk Margin cannot be blank.";}', 3, 'a:1:{s:8:"column_8";a:1:{i:0;s:11:"Is invalid.";}}'),
(38, 'Oceanfront Plaza-New Contract', '193', 'N/A', 'N/A', 'Double Bulk', 'New', '$52.95', '$10,219.35', '$6,131.61', '$2,732.40', '$3,441.54', '$12,951.75', '$9,264.42', '8', 'RF', '$144,750', 'Bob/Antoinette', 'IC', 3, 'a:2:{i:0;s:54:"Contract - Blended Bulk Margin Invalid integer format.";i:1;s:69:"Contract - Blended Bulk Margin - Blended Bulk Margin cannot be blank.";}', 3, 'a:1:{s:8:"column_8";a:1:{i:0;s:11:"Is invalid.";}}'),
(39, 'OceanView Place-New Contract', '591', 'N/A', 'N/A', 'Double Bulk', 'New', '$49.95', '$29,520.45', '$19,483.50', '$11,808.18', '$5,904.09', '$41,328.63', '$25,387.59', '8', 'RF', '$168,300', 'Bob/ Antoniette', 'FP', 3, 'a:2:{i:0;s:54:"Contract - Blended Bulk Margin Invalid integer format.";i:1;s:69:"Contract - Blended Bulk Margin - Blended Bulk Margin cannot be blank.";}', 3, 'a:1:{s:8:"column_8";a:1:{i:0;s:11:"Is invalid.";}}'),
(40, 'Parker Plaza-New Contract', '520', 'N/A', 'N/A', 'Double Bulk', 'New', '$48.95', '$25,454', '$19,091', '$7,800', '$3,900', '$33,254', '$37,500', '8', 'FTTU', '$268,000', 'Bob/Antoinette', 'FP', 3, 'a:1:{i:0;s:81:"Contract - Blended Bulk Margin - Blended Bulk Margin is too big (maximum is 100).";}', 3, 'a:1:{s:8:"column_8";a:1:{i:0;s:11:"Is invalid.";}}'),
(41, 'Patrician of the Palm Beaches-New Contract', '224', 'N/A', 'N/A', 'Single Bulk', 'New', '$38.95', '$8,724.80', '$5,409.38', '$1,497.13', '$877.50', '$10,221.93', '$2,936.06', '8', 'RF', '$123,200', 'Bob', 'FP', 3, 'a:2:{i:0;s:54:"Contract - Blended Bulk Margin Invalid integer format.";i:1;s:69:"Contract - Blended Bulk Margin - Blended Bulk Margin cannot be blank.";}', 3, 'a:1:{s:8:"column_8";a:1:{i:0;s:11:"Is invalid.";}}'),
(42, 'Pine Ridge Condo-New Contract', '462', 'N/A', 'N/A', 'Double Bulk', 'New', '$52.95', '$24,462.90', '$15,900.88', '$18,208.96', '$874.10', '$42,671.86', '$29,623.44', '8', 'FTTU', '$460,000', 'Bob Allecca', 'IC', 3, 'a:2:{i:0;s:54:"Contract - Blended Bulk Margin Invalid integer format.";i:1;s:69:"Contract - Blended Bulk Margin - Blended Bulk Margin cannot be blank.";}', 3, 'a:1:{s:8:"column_8";a:1:{i:0;s:11:"Is invalid.";}}'),
(43, 'Pinehurst Club (Net)-Renewal Contract', '197', '2015-Q4', '2015-Q4', 'Double Bulk', 'Renewal', '$0.00', '$0.00', '$0.00', '$3,606.32', '$1,830.00', '$3,606.32', '$8,557.00', '8', 'FTTU', '$250,000', 'Bob/Dee', 'UC', 3, 'a:2:{i:0;s:54:"Contract - Blended Bulk Margin Invalid integer format.";i:1;s:69:"Contract - Blended Bulk Margin - Blended Bulk Margin cannot be blank.";}', 3, 'a:1:{s:8:"column_8";a:1:{i:0;s:11:"Is invalid.";}}'),
(44, 'Plaza of Bal Harbour-New Contract', '302', 'N/A', 'N/A', 'Double Bulk', 'New', '$46.95', '$14,178.90', '$8,507.34', '$30,778.00', '$5,090.80', '$44,956.90', '$56,222.60', '8', 'RF', '$90,600', 'Bob/Antoinette', 'FP', 3, 'a:2:{i:0;s:54:"Contract - Blended Bulk Margin Invalid integer format.";i:1;s:69:"Contract - Blended Bulk Margin - Blended Bulk Margin cannot be blank.";}', 3, 'a:1:{s:8:"column_8";a:1:{i:0;s:11:"Is invalid.";}}'),
(45, 'Point East Condo-New Contract', '1270', 'N/A', 'N/A', 'Double Bulk', 'New', '$39.95', '$50,737', '$30,442', '$19,050', '$9,525', '$69,787', '$15,658', '8', 'RF', '$950,000', 'Bob Allecca', 'AD', 3, 'a:1:{i:0;s:81:"Contract - Blended Bulk Margin - Blended Bulk Margin is too big (maximum is 100).";}', 3, 'a:1:{s:8:"column_8";a:1:{i:0;s:11:"Is invalid.";}}'),
(46, 'River Bridge-New Contract', '1100', 'N/A', 'N/A', 'Double Bulk', 'New', '$69.95', '$76,945.00', '$52,322.60', '$10,181.60', '$3,900.00', '$87,126.60', '$22,990.50', '10', 'FTTH', '$1,815,000', 'CJ/Bob', 'FP', 3, 'a:2:{i:0;s:54:"Contract - Blended Bulk Margin Invalid integer format.";i:1;s:69:"Contract - Blended Bulk Margin - Blended Bulk Margin cannot be blank.";}', 3, 'a:1:{s:8:"column_8";a:1:{i:0;s:11:"Is invalid.";}}'),
(47, 'Sand Pebble Beach Condominiums-New Contract', '242', 'N/A', 'N/A', 'Double Bulk', 'New', '$79.95', '$19,347.90', '$12,769.61', '$5,671.56', '$15,389.00', '$25,019.46', '$13,598.14', '10', 'FTTH', '$399,300', 'CJ/Bob', 'FP', 3, 'a:2:{i:0;s:54:"Contract - Blended Bulk Margin Invalid integer format.";i:1;s:69:"Contract - Blended Bulk Margin - Blended Bulk Margin cannot be blank.";}', 3, 'a:1:{s:8:"column_8";a:1:{i:0;s:11:"Is invalid.";}}'),
(48, 'Seamark (Net)-Renewal Contract', '39', '2015-Q3', '2016-Q1', 'Double Bulk', 'Renewal', '$49.52', '$1,931.28', '$1,158.77', '$167.46', '$165.00', '$2,098.74', '$745.00', '8', 'RF', '$45,000', 'Bob/Dee', 'UC', 3, 'a:2:{i:0;s:54:"Contract - Blended Bulk Margin Invalid integer format.";i:1;s:69:"Contract - Blended Bulk Margin - Blended Bulk Margin cannot be blank.";}', 3, 'a:1:{s:8:"column_8";a:1:{i:0;s:11:"Is invalid.";}}'),
(49, 'Strada 315 (Data)-New Contract', '117', '2014-Q1', '2015-Q1', 'Double Bulk', 'New', '$17.98', '$2,104', '$1,870', '$878', '$439', '$2,981', '$2,080', '6', 'RF', '$73,125', 'Eric/Jonathan', 'CR', 3, 'a:1:{i:0;s:81:"Contract - Blended Bulk Margin - Blended Bulk Margin is too big (maximum is 100).";}', 3, 'a:1:{s:8:"column_8";a:1:{i:0;s:11:"Is invalid.";}}'),
(50, 'Strada 315 (Video)-New Contract', '117', '2014-Q1', '2014-Q3', 'Double Bulk', 'New', '$31.99', '$3,743', '$2,059', '$1,755', '$878', '$5,498', '$2,936', '6', 'RF', '$73,125', 'Eric/Jonathan', 'CR', 3, 'a:1:{i:0;s:81:"Contract - Blended Bulk Margin - Blended Bulk Margin is too big (maximum is 100).";}', 3, 'a:1:{s:8:"column_8";a:1:{i:0;s:11:"Is invalid.";}}'),
(51, 'Sunset Bay (Data)-New Contract', '308', '2014-Q2', '2014-Q4', 'Double Bulk', 'New', '$19.95', '$6,145', '$4,890', '$2,310', '$1,155', '$8,455', '$6,045', '7', 'RF', '$185,000', 'Jorge/Ruben', 'CR', 3, 'a:1:{i:0;s:81:"Contract - Blended Bulk Margin - Blended Bulk Margin is too big (maximum is 100).";}', 3, 'a:1:{s:8:"column_8";a:1:{i:0;s:11:"Is invalid.";}}'),
(52, 'Sunset Bay (Video)-New Contract', '308', '2014-Q3', '2015-Q2', 'Double Bulk', 'New', '$14.19', '$4,371', '$3,447', '$4,620', '$2,310', '$8,991', '$8,158', '7', 'RF', '$110,000', 'Eric/Dee', 'UC', 3, 'a:1:{i:0;s:81:"Contract - Blended Bulk Margin - Blended Bulk Margin is too big (maximum is 100).";}', 3, 'a:1:{s:8:"column_8";a:1:{i:0;s:11:"Is invalid.";}}'),
(53, 'The Atriums-New Contract', '106', 'N/A', 'N/A', 'Double Bulk', 'New', '$69.95', '$7,414.70', '$4,448.82', '$20,294.60', '$9,525.00', '$27,709.30', '$39,967.20', '8', 'RF', '$42,400', 'Bob', 'FP', 3, 'a:2:{i:0;s:54:"Contract - Blended Bulk Margin Invalid integer format.";i:1;s:69:"Contract - Blended Bulk Margin - Blended Bulk Margin cannot be blank.";}', 3, 'a:1:{s:8:"column_8";a:1:{i:0;s:11:"Is invalid.";}}'),
(54, 'The Residences on Hollywood Beach Proposal (Net)-Renewal Contract', '534', 'N/A', 'N/A', 'Double Bulk', 'Renewal', '$25.39', '$13,558.26', '$9,861.33', '$4,990.74', '$2,043.87', '$18,549.00', '$8,977.08', '8', 'RF', '$280,000', 'Bob/Dee', 'AD', 3, 'a:2:{i:0;s:54:"Contract - Blended Bulk Margin Invalid integer format.";i:1;s:69:"Contract - Blended Bulk Margin - Blended Bulk Margin cannot be blank.";}', 3, 'a:2:{s:8:"column_0";a:1:{i:0;s:73:"Is too long. Maximum length is 64. This value will truncated upon import.";}s:8:"column_8";a:1:{i:0;s:11:"Is invalid.";}}'),
(55, 'The Summit (Net)-Renewal Contract', '567', '2013-Q3', '2015-Q3', 'Single Bulk', 'Renewal', '$5.00', '$2,835', '$1,134', '$8,505', '$4,253', '$11,340', '$18,007', '5', 'FTTU', '$507,010', 'Luis', 'UC', 3, 'a:1:{i:0;s:81:"Contract - Blended Bulk Margin - Blended Bulk Margin is too big (maximum is 100).";}', 3, 'a:1:{s:8:"column_8";a:1:{i:0;s:11:"Is invalid.";}}'),
(56, 'The Tides @ Bridgeside Square-New Contract', '246', 'N/A', 'N/A', 'Double Bulk', 'New', '$69.95', '$17,207.70', '$11,873.31', '$9,785.16', '$9,104.48', '$26,992.86', '$16,774.98', '10', 'FTTU', '$295,200', 'Bob/Antoinette', 'FP', 3, 'a:2:{i:0;s:54:"Contract - Blended Bulk Margin Invalid integer format.";i:1;s:69:"Contract - Blended Bulk Margin - Blended Bulk Margin cannot be blank.";}', 3, 'a:1:{s:8:"column_8";a:1:{i:0;s:11:"Is invalid.";}}'),
(57, 'Topaz North-New Contract', '84', '2015-Q1', '2015-Q4', 'Single Bulk', 'New', '$34.39', '$2,889', '$1,877', '$1,260', '$630', '$4,149', '$19,771', '8', 'RF', '$105,000', 'Bob/CJ', 'UC', 3, 'a:1:{i:0;s:81:"Contract - Blended Bulk Margin - Blended Bulk Margin is too big (maximum is 100).";}', 3, 'a:1:{s:8:"column_8";a:1:{i:0;s:11:"Is invalid.";}}'),
(58, 'TOWERS OF KENDAL LAKES-New Contract', '180', 'N/A', 'N/A', 'Double Bulk', 'New', '$37.95', '$6,831.00', '$4,371.84', '$6,883.08', '$4,892.58', '$13,714.08', '$20,977.79', '8', 'RF', '$13,500', 'Bob/Antoinette', 'IC', 3, 'a:2:{i:0;s:54:"Contract - Blended Bulk Margin Invalid integer format.";i:1;s:69:"Contract - Blended Bulk Margin - Blended Bulk Margin cannot be blank.";}', 3, 'a:1:{s:8:"column_8";a:1:{i:0;s:11:"Is invalid.";}}'),
(59, 'Tropic Harbor-New Contract', '225', '2015-Q1', '2015-Q3', 'Single Bulk', 'New', '$29.43', '$6,622', '$4,635', '$3,375', '$1,688', '$9,997', '$11,414', '8', 'RF', '$157,500', 'Bob/Dee', 'UC', 3, 'a:1:{i:0;s:81:"Contract - Blended Bulk Margin - Blended Bulk Margin is too big (maximum is 100).";}', 3, 'a:1:{s:8:"column_8";a:1:{i:0;s:11:"Is invalid.";}}'),
(60, '', '', '', '', '', '', '', '$0.00', '', '$0.00', '$0.00', '$0.00', '$0.00', '', '', '', '', '', 3, 'a:6:{i:0;s:93:"Contract - Name This field is required and neither a value nor a default value was specified.";i:1;s:108:"Contract - Blended Bulk Margin This field is required and neither a value nor a default value was specified.";i:2;s:116:"Contract - ROI Total Months Calculator This field is required and neither a value nor a default value was specified.";i:3;s:39:"Contract - Name - Name cannot be blank.";i:4;s:69:"Contract - Blended Bulk Margin - Blended Bulk Margin cannot be blank.";i:5;s:85:"Contract - ROI Total Months Calculator - ROI Total Months Calculator cannot be blank.";}', 3, 'a:3:{s:8:"column_0";a:1:{i:0;s:13:"Is  required.";}s:8:"column_8";a:1:{i:0;s:13:"Is  required.";}s:9:"column_13";a:1:{i:0;s:13:"Is  required.";}}'),
(61, '', '', '', '', '', '', '', '$0.00', '', '$0.00', '$0.00', '$0.00', '$0.00', '', '', '$0', '', '', 3, 'a:6:{i:0;s:93:"Contract - Name This field is required and neither a value nor a default value was specified.";i:1;s:108:"Contract - Blended Bulk Margin This field is required and neither a value nor a default value was specified.";i:2;s:116:"Contract - ROI Total Months Calculator This field is required and neither a value nor a default value was specified.";i:3;s:39:"Contract - Name - Name cannot be blank.";i:4;s:69:"Contract - Blended Bulk Margin - Blended Bulk Margin cannot be blank.";i:5;s:85:"Contract - ROI Total Months Calculator - ROI Total Months Calculator cannot be blank.";}', 3, 'a:3:{s:8:"column_0";a:1:{i:0;s:13:"Is  required.";}s:8:"column_8";a:1:{i:0;s:13:"Is  required.";}s:9:"column_13";a:1:{i:0;s:13:"Is  required.";}}');

-- --------------------------------------------------------

--
-- Table structure for table `importtable4`
--

CREATE TABLE IF NOT EXISTS `importtable4` (
`id` int(11) unsigned NOT NULL,
  `column_0` varchar(65) COLLATE utf8_unicode_ci DEFAULT NULL,
  `status` int(11) unsigned DEFAULT NULL,
  `serializedMessages` text COLLATE utf8_unicode_ci,
  `analysisStatus` int(11) unsigned DEFAULT NULL,
  `serializedAnalysisMessages` text COLLATE utf8_unicode_ci
) ENGINE=InnoDB AUTO_INCREMENT=60 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

--
-- Dumping data for table `importtable4`
--

INSERT INTO `importtable4` (`id`, `column_0`, `status`, `serializedMessages`, `analysisStatus`, `serializedAnalysisMessages`) VALUES
(1, 'Name', NULL, NULL, NULL, NULL),
(2, '3360 Condo-New Contract', 2, 'a:1:{i:0;s:156:"Contract saved correctly: <a class="simple-link" target="blank" href="/opticaltel/app/index.php/contracts/default/details?id=14">3360 Condo-New Contract</a>";}', 1, NULL),
(3, '400 Association (Data)-Renewal Contract', 2, 'a:1:{i:0;s:172:"Contract saved correctly: <a class="simple-link" target="blank" href="/opticaltel/app/index.php/contracts/default/details?id=15">400 Association (Data)-Renewal Contract</a>";}', 1, NULL),
(4, '9 Island (Net)-Renewal Contract', 2, 'a:1:{i:0;s:164:"Contract saved correctly: <a class="simple-link" target="blank" href="/opticaltel/app/index.php/contracts/default/details?id=16">9 Island (Net)-Renewal Contract</a>";}', 1, NULL),
(5, 'Alexander Hotel/Condo-New Contract', 2, 'a:1:{i:0;s:167:"Contract saved correctly: <a class="simple-link" target="blank" href="/opticaltel/app/index.php/contracts/default/details?id=17">Alexander Hotel/Condo-New Contract</a>";}', 1, NULL),
(6, 'Artesia-New Contract', 2, 'a:1:{i:0;s:153:"Contract saved correctly: <a class="simple-link" target="blank" href="/opticaltel/app/index.php/contracts/default/details?id=18">Artesia-New Contract</a>";}', 1, NULL),
(7, 'Aventi-New Contract', 2, 'a:1:{i:0;s:152:"Contract saved correctly: <a class="simple-link" target="blank" href="/opticaltel/app/index.php/contracts/default/details?id=19">Aventi-New Contract</a>";}', 1, NULL),
(8, 'Balmoral Condo-New Contract', 2, 'a:1:{i:0;s:160:"Contract saved correctly: <a class="simple-link" target="blank" href="/opticaltel/app/index.php/contracts/default/details?id=20">Balmoral Condo-New Contract</a>";}', 1, NULL),
(9, 'Bravura 1 Condo-New Contract', 2, 'a:1:{i:0;s:161:"Contract saved correctly: <a class="simple-link" target="blank" href="/opticaltel/app/index.php/contracts/default/details?id=21">Bravura 1 Condo-New Contract</a>";}', 1, NULL),
(10, 'Christopher House-New Contract', 2, 'a:1:{i:0;s:163:"Contract saved correctly: <a class="simple-link" target="blank" href="/opticaltel/app/index.php/contracts/default/details?id=22">Christopher House-New Contract</a>";}', 1, NULL),
(11, 'Cloisters (Net)-Renewal Contract', 2, 'a:1:{i:0;s:165:"Contract saved correctly: <a class="simple-link" target="blank" href="/opticaltel/app/index.php/contracts/default/details?id=23">Cloisters (Net)-Renewal Contract</a>";}', 1, NULL),
(12, 'Commodore Club South-New Contract', 2, 'a:1:{i:0;s:166:"Contract saved correctly: <a class="simple-link" target="blank" href="/opticaltel/app/index.php/contracts/default/details?id=24">Commodore Club South-New Contract</a>";}', 1, NULL),
(13, 'Commodore Plaza-New Contract', 2, 'a:1:{i:0;s:161:"Contract saved correctly: <a class="simple-link" target="blank" href="/opticaltel/app/index.php/contracts/default/details?id=25">Commodore Plaza-New Contract</a>";}', 1, NULL),
(14, 'Cypress Trails-New Contract', 2, 'a:1:{i:0;s:160:"Contract saved correctly: <a class="simple-link" target="blank" href="/opticaltel/app/index.php/contracts/default/details?id=26">Cypress Trails-New Contract</a>";}', 1, NULL),
(15, 'East Pointe Towers-New Contract', 2, 'a:1:{i:0;s:164:"Contract saved correctly: <a class="simple-link" target="blank" href="/opticaltel/app/index.php/contracts/default/details?id=27">East Pointe Towers-New Contract</a>";}', 1, NULL),
(16, 'Emerald (Net)-Renewal Contract', 2, 'a:1:{i:0;s:163:"Contract saved correctly: <a class="simple-link" target="blank" href="/opticaltel/app/index.php/contracts/default/details?id=28">Emerald (Net)-Renewal Contract</a>";}', 1, NULL),
(17, 'Fairways of Tamarac-New Contract', 2, 'a:1:{i:0;s:165:"Contract saved correctly: <a class="simple-link" target="blank" href="/opticaltel/app/index.php/contracts/default/details?id=29">Fairways of Tamarac-New Contract</a>";}', 1, NULL),
(18, 'Garden Estates (Net)-Renewal Contract', 2, 'a:1:{i:0;s:170:"Contract saved correctly: <a class="simple-link" target="blank" href="/opticaltel/app/index.php/contracts/default/details?id=30">Garden Estates (Net)-Renewal Contract</a>";}', 1, NULL),
(19, 'Glades Country Club (Net)-Renewal Contract', 2, 'a:1:{i:0;s:175:"Contract saved correctly: <a class="simple-link" target="blank" href="/opticaltel/app/index.php/contracts/default/details?id=31">Glades Country Club (Net)-Renewal Contract</a>";}', 1, NULL),
(20, 'Harbour House-New Contract', 2, 'a:1:{i:0;s:159:"Contract saved correctly: <a class="simple-link" target="blank" href="/opticaltel/app/index.php/contracts/default/details?id=32">Harbour House-New Contract</a>";}', 1, NULL),
(21, 'Hillsboro Cove-New Contract', 2, 'a:1:{i:0;s:160:"Contract saved correctly: <a class="simple-link" target="blank" href="/opticaltel/app/index.php/contracts/default/details?id=33">Hillsboro Cove-New Contract</a>";}', 1, NULL),
(22, 'Isles at Grand Bay-New Contract', 2, 'a:1:{i:0;s:164:"Contract saved correctly: <a class="simple-link" target="blank" href="/opticaltel/app/index.php/contracts/default/details?id=34">Isles at Grand Bay-New Contract</a>";}', 1, NULL),
(23, 'Kenilworth (Net)-Renewal Contract', 2, 'a:1:{i:0;s:166:"Contract saved correctly: <a class="simple-link" target="blank" href="/opticaltel/app/index.php/contracts/default/details?id=35">Kenilworth (Net)-Renewal Contract</a>";}', 1, NULL),
(24, 'Key Largo-New Contract', 2, 'a:1:{i:0;s:155:"Contract saved correctly: <a class="simple-link" target="blank" href="/opticaltel/app/index.php/contracts/default/details?id=36">Key Largo-New Contract</a>";}', 1, NULL),
(25, 'Lake Worth Towers-Renewal Contract', 2, 'a:1:{i:0;s:167:"Contract saved correctly: <a class="simple-link" target="blank" href="/opticaltel/app/index.php/contracts/default/details?id=37">Lake Worth Towers-Renewal Contract</a>";}', 1, NULL),
(26, 'Lakes of Savannah -New Contract', 2, 'a:1:{i:0;s:164:"Contract saved correctly: <a class="simple-link" target="blank" href="/opticaltel/app/index.php/contracts/default/details?id=38">Lakes of Savannah -New Contract</a>";}', 1, NULL),
(27, 'Las Verdes-New Contract', 2, 'a:1:{i:0;s:156:"Contract saved correctly: <a class="simple-link" target="blank" href="/opticaltel/app/index.php/contracts/default/details?id=39">Las Verdes-New Contract</a>";}', 1, NULL),
(28, 'Marina Village (Net)-Renewal Contract', 2, 'a:1:{i:0;s:170:"Contract saved correctly: <a class="simple-link" target="blank" href="/opticaltel/app/index.php/contracts/default/details?id=40">Marina Village (Net)-Renewal Contract</a>";}', 1, NULL),
(29, 'Mayfair House Condo-New Contract', 2, 'a:1:{i:0;s:165:"Contract saved correctly: <a class="simple-link" target="blank" href="/opticaltel/app/index.php/contracts/default/details?id=41">Mayfair House Condo-New Contract</a>";}', 1, NULL),
(30, 'Meadowbrook # 4-New Contract', 2, 'a:1:{i:0;s:161:"Contract saved correctly: <a class="simple-link" target="blank" href="/opticaltel/app/index.php/contracts/default/details?id=42">Meadowbrook # 4-New Contract</a>";}', 1, NULL),
(31, 'Midtown Doral-New Contract', 2, 'a:1:{i:0;s:159:"Contract saved correctly: <a class="simple-link" target="blank" href="/opticaltel/app/index.php/contracts/default/details?id=43">Midtown Doral-New Contract</a>";}', 1, NULL),
(32, 'Midtown Retail-New Contract', 2, 'a:1:{i:0;s:160:"Contract saved correctly: <a class="simple-link" target="blank" href="/opticaltel/app/index.php/contracts/default/details?id=44">Midtown Retail-New Contract</a>";}', 1, NULL),
(33, 'Mystic Point-New Contract', 2, 'a:1:{i:0;s:158:"Contract saved correctly: <a class="simple-link" target="blank" href="/opticaltel/app/index.php/contracts/default/details?id=45">Mystic Point-New Contract</a>";}', 1, NULL),
(34, 'Nirvana Condos -New Contract', 2, 'a:1:{i:0;s:161:"Contract saved correctly: <a class="simple-link" target="blank" href="/opticaltel/app/index.php/contracts/default/details?id=46">Nirvana Condos -New Contract</a>";}', 1, NULL),
(35, 'Northern Star (Net)-Renewal Contract', 2, 'a:1:{i:0;s:169:"Contract saved correctly: <a class="simple-link" target="blank" href="/opticaltel/app/index.php/contracts/default/details?id=47">Northern Star (Net)-Renewal Contract</a>";}', 1, NULL),
(36, 'OakBridge-New Contract', 2, 'a:1:{i:0;s:155:"Contract saved correctly: <a class="simple-link" target="blank" href="/opticaltel/app/index.php/contracts/default/details?id=48">OakBridge-New Contract</a>";}', 1, NULL),
(37, 'Ocean Place-New Contract', 2, 'a:1:{i:0;s:157:"Contract saved correctly: <a class="simple-link" target="blank" href="/opticaltel/app/index.php/contracts/default/details?id=49">Ocean Place-New Contract</a>";}', 1, NULL),
(38, 'Oceanfront Plaza-New Contract', 2, 'a:1:{i:0;s:162:"Contract saved correctly: <a class="simple-link" target="blank" href="/opticaltel/app/index.php/contracts/default/details?id=50">Oceanfront Plaza-New Contract</a>";}', 1, NULL),
(39, 'OceanView Place-New Contract', 2, 'a:1:{i:0;s:161:"Contract saved correctly: <a class="simple-link" target="blank" href="/opticaltel/app/index.php/contracts/default/details?id=51">OceanView Place-New Contract</a>";}', 1, NULL),
(40, 'Parker Plaza-New Contract', 2, 'a:1:{i:0;s:158:"Contract saved correctly: <a class="simple-link" target="blank" href="/opticaltel/app/index.php/contracts/default/details?id=52">Parker Plaza-New Contract</a>";}', 1, NULL),
(41, 'Patrician of the Palm Beaches-New Contract', 2, 'a:1:{i:0;s:175:"Contract saved correctly: <a class="simple-link" target="blank" href="/opticaltel/app/index.php/contracts/default/details?id=53">Patrician of the Palm Beaches-New Contract</a>";}', 1, NULL),
(42, 'Pine Ridge Condo-New Contract', 2, 'a:1:{i:0;s:162:"Contract saved correctly: <a class="simple-link" target="blank" href="/opticaltel/app/index.php/contracts/default/details?id=54">Pine Ridge Condo-New Contract</a>";}', 1, NULL),
(43, 'Pinehurst Club (Net)-Renewal Contract', 2, 'a:1:{i:0;s:170:"Contract saved correctly: <a class="simple-link" target="blank" href="/opticaltel/app/index.php/contracts/default/details?id=55">Pinehurst Club (Net)-Renewal Contract</a>";}', 1, NULL),
(44, 'Plaza of Bal Harbour-New Contract', 2, 'a:1:{i:0;s:166:"Contract saved correctly: <a class="simple-link" target="blank" href="/opticaltel/app/index.php/contracts/default/details?id=56">Plaza of Bal Harbour-New Contract</a>";}', 1, NULL),
(45, 'Point East Condo-New Contract', 2, 'a:1:{i:0;s:162:"Contract saved correctly: <a class="simple-link" target="blank" href="/opticaltel/app/index.php/contracts/default/details?id=57">Point East Condo-New Contract</a>";}', 1, NULL),
(46, 'River Bridge-New Contract', 2, 'a:1:{i:0;s:158:"Contract saved correctly: <a class="simple-link" target="blank" href="/opticaltel/app/index.php/contracts/default/details?id=58">River Bridge-New Contract</a>";}', 1, NULL),
(47, 'Sand Pebble Beach Condominiums-New Contract', 2, 'a:1:{i:0;s:176:"Contract saved correctly: <a class="simple-link" target="blank" href="/opticaltel/app/index.php/contracts/default/details?id=59">Sand Pebble Beach Condominiums-New Contract</a>";}', 1, NULL),
(48, 'Seamark (Net)-Renewal Contract', 2, 'a:1:{i:0;s:163:"Contract saved correctly: <a class="simple-link" target="blank" href="/opticaltel/app/index.php/contracts/default/details?id=60">Seamark (Net)-Renewal Contract</a>";}', 1, NULL),
(49, 'Strada 315 (Data)-New Contract', 2, 'a:1:{i:0;s:163:"Contract saved correctly: <a class="simple-link" target="blank" href="/opticaltel/app/index.php/contracts/default/details?id=61">Strada 315 (Data)-New Contract</a>";}', 1, NULL),
(50, 'Strada 315 (Video)-New Contract', 2, 'a:1:{i:0;s:164:"Contract saved correctly: <a class="simple-link" target="blank" href="/opticaltel/app/index.php/contracts/default/details?id=62">Strada 315 (Video)-New Contract</a>";}', 1, NULL),
(51, 'Sunset Bay (Data)-New Contract', 2, 'a:1:{i:0;s:163:"Contract saved correctly: <a class="simple-link" target="blank" href="/opticaltel/app/index.php/contracts/default/details?id=63">Sunset Bay (Data)-New Contract</a>";}', 1, NULL),
(52, 'Sunset Bay (Video)-New Contract', 2, 'a:1:{i:0;s:164:"Contract saved correctly: <a class="simple-link" target="blank" href="/opticaltel/app/index.php/contracts/default/details?id=64">Sunset Bay (Video)-New Contract</a>";}', 1, NULL),
(53, 'The Atriums-New Contract', 2, 'a:1:{i:0;s:157:"Contract saved correctly: <a class="simple-link" target="blank" href="/opticaltel/app/index.php/contracts/default/details?id=65">The Atriums-New Contract</a>";}', 1, NULL),
(54, 'The Residences on Hollywood Beach Proposal (Net)-Renewal Contract', 2, 'a:1:{i:0;s:197:"Contract saved correctly: <a class="simple-link" target="blank" href="/opticaltel/app/index.php/contracts/default/details?id=66">The Residences on Hollywood Beach Proposal (Net)-Renewal Contrac</a>";}', 2, 'a:1:{s:8:"column_0";a:1:{i:0;s:73:"Is too long. Maximum length is 64. This value will truncated upon import.";}}'),
(55, 'The Summit (Net)-Renewal Contract', 2, 'a:1:{i:0;s:166:"Contract saved correctly: <a class="simple-link" target="blank" href="/opticaltel/app/index.php/contracts/default/details?id=67">The Summit (Net)-Renewal Contract</a>";}', 1, NULL),
(56, 'The Tides @ Bridgeside Square-New Contract', 2, 'a:1:{i:0;s:175:"Contract saved correctly: <a class="simple-link" target="blank" href="/opticaltel/app/index.php/contracts/default/details?id=68">The Tides @ Bridgeside Square-New Contract</a>";}', 1, NULL),
(57, 'Topaz North-New Contract', 2, 'a:1:{i:0;s:157:"Contract saved correctly: <a class="simple-link" target="blank" href="/opticaltel/app/index.php/contracts/default/details?id=69">Topaz North-New Contract</a>";}', 1, NULL),
(58, 'TOWERS OF KENDAL LAKES-New Contract', 2, 'a:1:{i:0;s:168:"Contract saved correctly: <a class="simple-link" target="blank" href="/opticaltel/app/index.php/contracts/default/details?id=70">TOWERS OF KENDAL LAKES-New Contract</a>";}', 1, NULL),
(59, 'Tropic Harbor-New Contract', 2, 'a:1:{i:0;s:159:"Contract saved correctly: <a class="simple-link" target="blank" href="/opticaltel/app/index.php/contracts/default/details?id=71">Tropic Harbor-New Contract</a>";}', 1, NULL);

-- --------------------------------------------------------

--
-- Table structure for table `item`
--

CREATE TABLE IF NOT EXISTS `item` (
`id` int(11) unsigned NOT NULL,
  `createddatetime` datetime DEFAULT NULL,
  `modifieddatetime` datetime DEFAULT NULL,
  `createdbyuser__user_id` int(11) unsigned DEFAULT NULL,
  `modifiedbyuser__user_id` int(11) unsigned DEFAULT NULL
) ENGINE=InnoDB AUTO_INCREMENT=862 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

--
-- Dumping data for table `item`
--

INSERT INTO `item` (`id`, `createddatetime`, `modifieddatetime`, `createdbyuser__user_id`, `modifiedbyuser__user_id`) VALUES
(1, '2013-06-25 12:27:49', '2016-01-07 03:39:29', NULL, 1),
(2, '2013-06-25 12:27:49', '2016-01-05 10:33:37', 1, 1),
(52, '2013-06-25 12:29:36', '2013-06-25 12:29:36', 1, NULL),
(53, '2013-06-25 12:29:36', '2013-06-25 12:29:36', 1, 1),
(54, '2013-06-25 12:29:36', '2013-06-25 12:29:36', 1, 1),
(55, '2013-06-25 12:29:36', '2013-06-25 12:29:36', 1, 1),
(56, '2013-06-25 12:29:36', '2013-06-25 12:29:36', 1, 1),
(57, '2013-06-25 12:29:36', '2013-06-25 12:29:36', 1, 1),
(58, '2013-06-25 12:29:36', '2013-06-25 12:29:36', 1, 1),
(59, '2013-06-25 12:29:36', '2013-06-25 12:29:36', 1, 1),
(60, '2013-06-25 12:29:36', '2013-06-25 12:29:36', 1, 1),
(61, '2013-06-25 12:29:36', '2013-06-25 12:29:36', 1, 1),
(62, '2013-06-25 12:29:36', '2016-01-20 03:55:49', 1, 1),
(63, '2013-06-25 12:29:36', '2016-01-20 03:56:50', 1, 1),
(64, '2013-06-25 12:29:36', '2016-01-04 16:06:41', 1, 1),
(65, '2013-06-25 12:29:37', '2016-01-04 16:06:41', 1, 1),
(66, '2013-06-25 12:29:37', '2016-01-04 16:06:41', 1, 1),
(67, '2013-06-25 12:29:37', '2016-01-04 16:06:42', 1, 1),
(68, '2013-06-25 12:29:37', '2016-01-04 16:06:42', 1, 1),
(69, '2013-06-25 12:29:37', '2016-01-04 16:06:43', 1, 1),
(70, '2013-06-25 12:29:37', '2016-01-04 16:06:43', 1, 1),
(71, '2013-06-25 12:29:38', '2016-01-04 16:06:43', 1, 1),
(78, '2013-06-25 12:29:39', '2013-06-25 12:29:39', 1, 1),
(79, '2013-06-25 12:29:39', '2013-06-25 12:29:39', 1, 1),
(80, '2013-06-25 12:29:39', '2013-06-25 12:29:39', 1, 1),
(81, '2013-06-25 12:29:39', '2013-06-25 12:29:39', 1, 1),
(82, '2013-06-25 12:29:39', '2013-06-25 12:29:39', 1, 1),
(83, '2013-06-25 12:29:39', '2013-06-25 12:29:39', 1, 1),
(84, '2013-06-25 12:29:39', '2013-06-25 12:29:39', 1, 1),
(85, '2013-06-25 12:29:40', '2013-06-25 12:29:40', 1, 1),
(86, '2013-06-25 12:29:40', '2013-06-25 12:29:40', 1, 1),
(87, '2013-06-25 12:29:40', '2013-06-25 12:29:40', 1, 1),
(88, '2013-06-25 12:29:40', '2013-06-25 12:29:40', 1, 1),
(89, '2013-06-25 12:29:40', '2013-06-25 12:29:40', 1, 1),
(90, '2013-06-25 12:29:40', '2013-06-25 12:29:40', 1, 1),
(91, '2013-06-25 12:29:40', '2013-06-25 12:29:41', 1, 1),
(92, '2013-06-25 12:29:41', '2013-06-25 12:29:41', 1, 1),
(93, '2013-06-25 12:29:41', '2013-06-25 12:29:41', 1, 1),
(94, '2013-06-25 12:29:41', '2013-06-25 12:29:41', 1, 1),
(95, '2013-06-25 12:29:48', '2013-06-25 12:29:49', 1, 1),
(96, '2013-06-25 12:29:49', '2013-06-25 12:29:49', 1, 1),
(97, '2013-06-25 12:29:49', '2013-06-25 12:29:49', 1, 1),
(98, '2013-06-25 12:29:49', '2013-06-25 12:29:49', 1, 1),
(99, '2013-06-25 12:29:49', '2013-06-25 12:29:49', 1, 1),
(100, '2013-06-25 12:29:49', '2013-06-25 12:29:49', 1, 1),
(101, '2013-06-25 12:29:49', '2013-06-25 12:29:49', 1, 1),
(102, '2013-06-25 12:29:49', '2013-06-25 12:29:49', 1, 1),
(103, '2013-06-25 12:29:49', '2013-06-25 12:29:49', 1, 1),
(104, '2013-06-25 12:29:49', '2013-06-25 12:29:49', 1, 1),
(105, '2013-06-25 12:29:49', '2013-06-25 12:29:49', 1, 1),
(106, '2013-06-25 12:29:49', '2013-06-25 12:29:49', 1, 1),
(107, '2013-06-25 12:29:49', '2013-06-25 12:29:49', 1, 1),
(108, '2013-06-25 12:29:49', '2013-06-25 12:29:49', 1, 1),
(109, '2013-06-25 12:29:50', '2013-06-25 12:29:50', 1, 1),
(110, '2013-06-25 12:29:50', '2013-06-25 12:29:50', 1, 1),
(111, '2013-06-25 12:29:50', '2013-06-25 12:29:50', 1, 1),
(112, '2013-06-25 12:29:50', '2013-06-25 12:29:50', 1, 1),
(113, '2013-06-25 12:29:50', '2013-06-25 12:29:50', 1, 1),
(114, '2013-06-25 12:29:50', '2013-06-25 12:29:50', 1, 1),
(115, '2013-06-25 12:29:50', '2013-06-25 12:29:50', 1, 1),
(116, '2013-06-25 12:29:50', '2013-06-25 12:29:50', 1, 1),
(117, '2013-06-25 12:29:50', '2013-06-25 12:29:50', 1, 1),
(118, '2013-06-25 12:29:50', '2013-06-25 12:29:50', 1, 1),
(119, '2013-06-25 12:29:51', '2013-06-25 12:29:51', 1, 1),
(120, '2013-06-25 12:29:51', '2013-06-25 12:29:51', 1, 1),
(121, '2013-06-25 12:29:51', '2013-06-25 12:29:51', 1, 1),
(122, '2013-06-25 12:29:51', '2013-06-25 12:29:51', 1, 1),
(123, '2013-06-25 12:29:51', '2013-06-25 12:29:51', 1, 1),
(124, '2013-06-25 12:29:51', '2013-06-25 12:29:51', 1, 1),
(125, '2013-06-25 12:29:51', '2013-06-25 12:29:51', 1, 1),
(126, '2013-06-02 12:29:51', '2013-06-25 12:29:51', 1, 1),
(127, '2013-06-20 12:29:53', '2013-06-25 12:29:53', 1, 1),
(128, '2013-06-17 12:29:55', '2013-06-25 12:29:55', 1, 1),
(129, '2013-06-22 12:29:58', '2013-06-25 12:29:58', 1, 1),
(130, '2013-06-19 12:30:00', '2013-06-25 12:30:00', 1, 1),
(131, '2013-06-16 12:30:02', '2013-06-25 12:30:02', 1, 1),
(132, '2013-06-02 12:30:05', '2013-06-25 12:30:05', 1, 1),
(133, '2013-06-18 12:30:07', '2013-06-25 12:30:07', 1, 1),
(134, '2013-05-29 12:30:09', '2013-06-25 12:30:09', 1, 1),
(135, '2013-06-19 12:30:11', '2013-06-25 12:30:11', 1, 1),
(136, '2013-06-22 12:30:14', '2013-06-25 12:30:14', 1, 1),
(137, '2013-06-14 12:30:16', '2013-06-25 12:30:16', 1, 1),
(138, '2013-05-26 12:30:18', '2013-06-25 12:30:18', 1, 1),
(139, '2013-06-14 12:30:21', '2013-06-25 12:30:21', 1, 1),
(140, '2013-06-12 12:30:21', '2013-06-25 12:30:21', 1, 1),
(141, '2013-05-27 12:30:21', '2013-06-25 12:30:21', 1, 1),
(142, '2013-05-28 12:30:21', '2013-06-25 12:30:21', 1, 1),
(143, '2013-06-06 12:30:21', '2013-06-25 12:30:21', 1, 1),
(144, '2013-06-25 12:30:21', '2013-06-25 12:30:21', 1, 1),
(145, '2013-06-25 12:30:22', '2013-06-25 12:30:22', 1, 1),
(146, '2013-06-25 12:30:22', '2013-06-25 12:30:22', 1, 1),
(147, '2013-06-25 12:30:22', '2013-06-25 12:30:22', 1, 1),
(148, '2013-06-25 12:30:22', '2013-06-25 12:30:22', 1, 1),
(149, '2013-06-25 12:30:22', '2013-06-25 12:30:22', 1, 1),
(150, '2013-06-25 12:30:22', '2013-06-25 12:30:22', 1, 1),
(151, '2013-06-25 12:30:22', '2013-06-25 12:30:22', 1, 1),
(152, '2013-06-25 12:30:23', '2013-06-25 12:30:23', 1, 1),
(153, '2013-06-25 12:30:23', '2013-06-25 12:30:23', 1, 1),
(154, '2013-06-25 12:30:24', '2013-06-25 12:30:24', 1, 1),
(155, '2013-06-25 12:30:24', '2013-06-25 12:30:24', 1, 1),
(156, '2013-06-25 12:30:24', '2013-06-25 12:30:24', 1, 1),
(157, '2013-06-25 12:30:24', '2013-06-25 12:30:24', 1, 1),
(158, '2013-06-25 12:30:24', '2013-06-25 12:30:24', 1, 1),
(159, '2013-06-25 12:30:24', '2013-06-25 12:30:24', 1, 1),
(160, '2013-06-25 12:30:24', '2013-06-25 12:30:24', 1, 1),
(161, '2013-06-25 12:30:24', '2013-06-25 12:30:24', 1, 1),
(162, '2013-06-25 12:30:24', '2013-06-25 12:30:24', 1, 1),
(163, '2013-06-25 12:30:24', '2013-06-25 12:30:24', 1, 1),
(164, '2013-06-25 12:30:24', '2013-06-25 12:30:24', 1, 1),
(165, '2013-06-25 12:30:24', '2013-06-25 12:30:24', 1, 1),
(166, '2013-06-25 12:30:24', '2013-06-25 12:30:24', 1, 1),
(167, '2013-06-25 12:30:24', '2013-06-25 12:30:24', 1, 1),
(168, '2013-06-25 12:30:24', '2013-06-25 12:30:24', 1, 1),
(169, '2013-06-25 12:30:24', '2013-06-25 12:30:24', 1, 1),
(170, '2013-06-25 12:30:24', '2013-06-25 12:30:25', 1, 1),
(171, '2013-06-25 12:30:25', '2013-06-25 12:30:25', 1, 1),
(172, '2013-06-11 12:30:25', '2013-06-25 12:30:25', 1, 1),
(173, '2013-05-31 12:30:25', '2013-06-25 12:30:25', 1, 1),
(174, '2013-06-11 12:30:25', '2013-06-25 12:30:25', 1, 1),
(175, '2013-05-28 12:30:25', '2013-06-25 12:30:25', 1, 1),
(176, '2013-06-07 12:30:25', '2013-06-25 12:30:25', 1, 1),
(177, '2013-06-19 12:30:25', '2013-06-25 12:30:25', 1, 1),
(178, '2013-05-26 12:30:26', '2013-06-25 12:30:26', 1, 1),
(179, '2013-06-09 12:30:26', '2013-06-25 12:30:26', 1, 1),
(180, '2013-06-10 12:30:26', '2013-06-25 12:30:26', 1, 1),
(181, '2013-05-28 12:30:26', '2013-06-25 12:30:26', 1, 1),
(182, '2013-06-10 12:30:26', '2013-06-25 12:30:26', 1, 1),
(183, '2013-05-30 12:30:27', '2013-06-25 12:30:27', 1, 1),
(184, '2013-06-15 12:30:27', '2013-06-25 12:30:27', 1, 1),
(185, '2013-06-11 12:30:27', '2013-06-25 12:30:27', 1, 1),
(186, '2013-06-01 12:30:27', '2013-06-25 12:30:27', 1, 1),
(187, '2013-06-22 12:30:27', '2013-06-25 12:30:27', 1, 1),
(188, '2013-06-08 12:30:27', '2013-06-25 12:30:27', 1, 1),
(189, '2013-06-15 12:30:28', '2013-06-25 12:30:28', 1, 1),
(190, '2013-06-25 12:30:28', '2013-06-25 12:30:28', 5, 1),
(191, '2013-06-25 12:30:28', '2013-06-25 12:30:28', 5, 1),
(192, '2013-06-25 12:30:28', '2013-06-25 12:30:28', 4, 1),
(193, '2013-06-25 12:30:28', '2013-06-25 12:30:28', 9, 1),
(194, '2013-06-25 12:30:28', '2013-06-25 12:30:28', 4, 1),
(195, '2013-06-25 12:30:28', '2013-06-25 12:30:28', 1, 1),
(196, '2013-06-25 12:30:28', '2013-06-25 12:30:28', 5, 1),
(197, '2013-06-25 12:30:28', '2013-06-25 12:30:28', 9, 1),
(198, '2013-06-25 12:30:28', '2013-06-25 12:30:28', 7, 1),
(199, '2013-06-25 12:30:28', '2013-06-25 12:30:28', 3, 1),
(200, '2013-06-25 12:30:28', '2013-06-25 12:30:28', 1, 1),
(201, '2013-06-25 12:30:28', '2016-01-18 16:19:22', 6, 1),
(202, '2013-06-25 12:30:28', '2013-06-25 12:30:28', 7, 1),
(203, '2013-06-25 12:30:29', '2013-06-25 12:30:29', 3, 1),
(204, '2013-06-25 12:30:29', '2013-06-25 12:30:29', 9, 1),
(205, '2013-06-25 12:30:29', '2013-06-25 12:30:29', 4, 1),
(206, '2013-06-25 12:30:29', '2013-06-25 12:30:29', 6, 1),
(207, '2013-06-25 12:30:29', '2013-06-25 12:30:29', 1, 1),
(208, '2013-06-25 12:30:29', '2013-06-25 12:30:29', 1, 1),
(209, '2013-06-25 12:30:29', '2013-06-25 12:30:29', 1, 1),
(210, '2013-06-25 12:30:29', '2013-06-25 12:30:29', 1, 1),
(211, '2013-06-25 12:30:29', '2013-06-25 12:30:29', 1, 1),
(212, '2013-06-25 12:30:29', '2013-06-25 12:30:29', 1, 1),
(213, '2013-06-25 12:30:29', '2013-06-25 12:30:29', 1, 1),
(214, '2013-06-25 12:30:29', '2013-06-25 12:30:29', 1, 1),
(215, '2013-06-25 12:30:29', '2013-06-25 12:30:29', 1, 1),
(216, '2013-06-25 12:30:29', '2013-06-25 12:30:29', 1, 1),
(217, '2013-06-25 12:30:29', '2013-06-25 12:30:29', 1, 1),
(218, '2013-06-25 12:30:30', '2013-06-25 12:30:30', 1, 1),
(219, '2013-06-25 12:30:30', '2013-06-25 12:30:30', 1, 1),
(220, '2013-06-25 12:30:30', '2013-06-25 12:30:30', 1, 1),
(221, '2013-06-25 12:30:30', '2013-06-25 12:30:30', 1, 1),
(222, '2013-06-25 12:30:30', '2013-06-25 12:30:30', 1, 1),
(223, '2013-06-25 12:30:30', '2013-06-25 12:30:30', 1, 1),
(224, '2013-06-25 12:30:30', '2013-06-25 12:30:30', 1, 1),
(225, '2013-06-25 12:30:30', '2013-06-25 12:30:30', 1, 1),
(226, '2013-06-25 12:30:30', '2013-06-25 12:30:30', 1, 1),
(227, '2013-06-25 12:30:30', '2013-06-25 12:30:30', 1, 1),
(228, '2013-06-25 12:30:30', '2013-06-25 12:30:30', 1, 1),
(229, '2013-06-25 12:30:30', '2013-06-25 12:30:30', 1, 1),
(230, '2013-06-25 12:30:30', '2013-06-25 12:30:30', 1, 1),
(231, '2013-06-25 12:30:30', '2013-06-25 12:30:30', 1, 1),
(232, '2013-06-25 12:30:30', '2013-06-25 12:30:30', 1, 1),
(233, '2013-06-25 12:30:30', '2013-06-25 12:30:30', 1, 1),
(234, '2013-06-25 12:30:30', '2013-06-25 12:30:30', 1, 1),
(235, '2013-06-25 12:30:30', '2013-06-25 12:30:30', 1, 1),
(236, '2013-06-25 12:30:30', '2013-06-25 12:30:30', 1, 1),
(237, '2013-06-25 12:30:30', '2013-06-25 12:30:30', 1, 1),
(238, '2013-06-25 12:30:30', '2013-06-25 12:30:30', 1, 1),
(239, '2013-06-25 12:30:30', '2013-06-25 12:30:30', 1, 1),
(240, '2013-06-25 12:30:30', '2013-06-25 12:30:30', 1, 1),
(241, '2013-06-25 12:30:30', '2013-06-25 12:30:30', 1, 1),
(242, '2013-06-25 12:30:30', '2013-06-25 12:30:30', 1, 1),
(243, '2013-06-25 12:30:30', '2013-06-25 12:30:30', 1, 1),
(244, '2013-06-25 12:30:30', '2013-06-25 12:30:30', 1, 1),
(245, '2013-06-25 12:30:30', '2013-06-25 12:30:30', 1, 1),
(246, '2013-06-25 12:30:30', '2013-06-25 12:30:30', 1, 1),
(247, '2013-06-25 12:30:30', '2013-06-25 12:30:30', 1, 1),
(248, '2013-06-25 12:30:30', '2013-06-25 12:30:30', 1, 1),
(249, '2013-06-25 12:30:30', '2013-06-25 12:30:30', 1, 1),
(250, '2013-06-25 12:30:30', '2013-06-25 12:30:30', 1, 1),
(251, '2013-06-25 12:30:30', '2013-06-25 12:30:30', 1, 1),
(252, '2013-06-25 12:30:30', '2013-06-25 12:30:30', 1, 1),
(253, '2013-06-25 12:30:30', '2013-06-25 12:30:30', 1, 1),
(254, '2013-06-25 12:30:30', '2013-06-25 12:30:30', 1, 1),
(255, '2013-06-25 12:30:30', '2013-06-25 12:30:30', 1, 1),
(256, '2013-06-25 12:30:30', '2013-06-25 12:30:30', 1, 1),
(257, '2013-06-25 12:30:30', '2013-06-25 12:30:30', 1, 1),
(258, '2013-06-25 12:30:30', '2013-06-25 12:30:30', 1, 1),
(259, '2013-06-25 12:30:30', '2013-06-25 12:30:30', 1, 1),
(260, '2013-06-25 12:30:30', '2013-06-25 12:30:30', 1, 1),
(261, '2013-06-25 12:30:30', '2013-06-25 12:30:30', 1, 1),
(262, '2013-06-25 12:30:30', '2013-06-25 12:30:30', 1, 1),
(263, '2013-06-25 12:30:31', '2013-06-25 12:30:31', 1, 1),
(264, '2013-06-25 12:30:31', '2013-06-25 12:30:31', 1, 1),
(265, '2013-06-25 12:30:31', '2013-06-25 12:30:31', 1, 1),
(266, '2013-06-25 12:30:31', '2013-06-25 12:30:31', 1, 1),
(267, '2013-06-25 12:30:31', '2013-06-25 12:30:31', 1, 1),
(268, '2013-06-25 12:30:31', '2013-06-25 12:30:31', 1, 1),
(269, '2013-06-25 12:30:31', '2013-06-25 12:30:31', 1, 1),
(270, '2013-06-25 12:30:31', '2013-06-25 12:30:31', 1, 1),
(271, '2013-06-25 12:30:31', '2013-06-25 12:30:31', 1, 1),
(272, '2013-06-25 12:30:31', '2013-06-25 12:30:31', 1, 1),
(273, '2013-06-25 12:30:31', '2013-06-25 12:30:31', 1, 1),
(274, '2013-06-25 12:30:31', '2013-06-25 12:30:31', 1, 1),
(275, '2013-06-25 12:30:31', '2013-06-25 12:30:31', 1, 1),
(276, '2013-06-25 12:30:31', '2013-06-25 12:30:31', 1, 1),
(277, '2013-06-25 12:30:31', '2013-06-25 12:30:31', 1, 1),
(278, '2013-06-25 12:30:31', '2016-01-19 20:32:02', 1, 1),
(279, '2013-06-25 12:30:31', '2013-06-25 12:30:31', 1, 1),
(280, '2013-06-25 12:30:31', '2016-01-19 19:43:58', 1, 1),
(281, '2013-06-25 12:30:31', '2013-06-25 12:30:31', 1, 1),
(282, '2013-06-25 12:30:31', '2016-01-14 16:25:11', 1, 1),
(283, '2013-06-25 12:30:31', '2013-06-25 12:30:31', 1, 1),
(284, '2013-06-25 12:30:31', '2016-01-19 18:15:05', 1, 1),
(285, '2013-06-25 12:30:31', '2013-06-25 12:30:31', 1, 1),
(286, '2013-06-25 12:30:31', '2013-06-25 12:30:31', 1, 1),
(287, '2013-06-25 12:30:31', '2013-06-25 12:30:31', 1, 1),
(288, '2013-06-25 12:30:31', '2013-06-25 12:30:31', 1, 1),
(289, '2013-06-25 12:30:31', '2013-06-25 12:30:31', 1, 1),
(290, '2013-06-25 12:30:31', '2013-06-25 12:30:32', 1, 1),
(291, '2013-06-25 12:30:32', '2013-06-25 12:30:32', 1, 1),
(292, '2013-06-25 12:30:32', '2013-06-25 12:30:32', 1, 1),
(293, '2013-06-25 12:30:32', '2013-06-25 12:30:32', 1, 1),
(294, '2013-06-25 12:30:32', '2013-06-25 12:30:32', 1, 1),
(295, '2013-06-25 12:30:32', '2013-06-25 12:30:32', 1, 1),
(296, '2013-06-25 12:30:32', '2013-06-25 12:30:32', 1, 1),
(297, '2013-06-25 12:30:32', '2013-06-25 12:30:32', 1, 1),
(310, '2013-06-25 12:30:33', '2013-06-25 12:30:33', 1, 1),
(311, '2013-06-25 12:30:33', '2013-06-25 12:30:33', 1, 1),
(312, '2013-06-25 12:30:33', '2013-06-25 12:30:33', 1, 1),
(313, '2013-06-25 12:30:33', '2013-06-25 12:30:33', 1, 1),
(314, '2013-06-25 12:30:33', '2013-06-25 12:30:34', 1, 1),
(315, '2013-06-25 12:30:34', '2013-06-25 12:30:34', 1, 1),
(316, '2013-06-25 12:30:34', '2013-06-25 12:30:34', 1, 1),
(317, '2013-06-25 12:30:34', '2013-06-25 12:30:34', 1, 1),
(318, '2013-06-25 12:30:34', '2013-06-25 12:30:34', 1, 1),
(319, '2013-06-25 12:30:34', '2013-06-25 12:30:34', 1, 1),
(320, '2013-06-25 12:30:34', '2013-06-25 12:30:34', 1, 1),
(321, '2013-06-25 12:30:34', '2013-06-25 12:30:34', 1, 1),
(322, '2013-06-25 12:30:34', '2013-06-25 12:30:34', 1, 1),
(323, '2013-06-25 12:30:34', '2013-06-25 12:30:34', 1, 1),
(324, '2013-06-25 12:30:34', '2013-06-25 12:30:34', 1, 1),
(325, '2013-06-25 12:30:34', '2013-06-25 12:30:34', 1, 1),
(326, '2013-06-25 12:30:34', '2013-06-25 12:30:34', 1, 1),
(327, '2013-06-25 12:30:34', '2013-06-25 12:30:34', 1, 1),
(328, '2013-06-25 12:30:34', '2013-06-25 12:30:34', 1, 1),
(329, '2013-06-25 12:30:34', '2013-06-25 12:30:34', 1, 1),
(330, '2013-06-25 12:30:34', '2013-06-25 12:30:34', 1, 1),
(331, '2013-06-25 12:30:34', '2013-06-25 12:30:34', 1, 1),
(332, '2013-06-25 12:30:34', '2013-06-25 12:30:34', 1, 1),
(333, '2013-06-25 12:30:34', '2013-06-25 12:30:34', 1, 1),
(334, '2013-06-25 12:30:34', '2013-06-25 12:30:35', 1, 1),
(335, '2013-06-25 12:30:35', '2013-06-25 12:30:35', 1, 1),
(336, '2013-06-25 12:30:35', '2013-06-25 12:30:35', 1, 1),
(337, '2013-06-25 12:30:35', '2013-06-25 12:30:35', 1, 1),
(338, '2013-06-25 12:30:35', '2013-06-25 12:30:35', 1, 1),
(339, '2013-06-25 12:30:35', '2013-06-25 12:30:35', 1, 1),
(340, '2013-06-25 12:30:35', '2013-06-25 12:30:35', 1, 1),
(341, '2013-06-25 12:30:35', '2013-06-25 12:30:35', 1, 1),
(342, '2013-06-25 12:30:35', '2013-06-25 12:30:35', 1, 1),
(343, '2013-06-25 12:30:35', '2013-06-25 12:30:35', 1, 1),
(344, '2013-06-25 12:30:35', '2013-06-25 12:30:35', 1, 1),
(345, '2013-06-25 12:30:35', '2013-06-25 12:30:35', 1, 1),
(346, '2013-06-25 12:30:35', '2013-06-25 12:30:35', 5, 1),
(347, '2013-06-25 12:30:35', '2013-06-25 12:30:35', 7, 1),
(348, '2013-06-25 12:30:35', '2013-06-25 12:30:35', 8, 1),
(349, '2013-06-25 12:30:35', '2013-06-25 12:30:35', 5, 1),
(350, '2013-06-25 12:30:35', '2013-06-25 12:30:35', 4, 1),
(351, '2013-06-25 12:30:35', '2013-06-25 12:30:35', 10, 1),
(352, '2013-06-25 12:30:35', '2013-06-25 12:30:35', 8, 1),
(353, '2013-06-25 12:30:35', '2013-06-25 12:30:35', 6, 1),
(354, '2013-06-25 12:30:35', '2013-06-25 12:30:35', 8, 1),
(355, '2013-06-25 12:30:35', '2013-06-25 12:30:35', 3, 1),
(356, '2013-06-25 12:30:36', '2013-06-25 12:30:36', 4, 1),
(357, '2013-06-25 12:30:36', '2013-06-25 12:30:36', 5, 1),
(358, '2013-06-25 12:30:36', '2013-06-25 12:30:36', 3, 1),
(359, '2013-06-25 12:30:36', '2013-06-25 12:30:36', 1, 1),
(360, '2013-06-25 12:30:36', '2013-06-25 12:30:36', 1, 1),
(361, '2013-06-25 12:30:36', '2013-06-25 12:30:36', 1, 1),
(362, '2013-06-25 12:30:36', '2013-06-25 12:30:36', 1, 1),
(363, '2013-06-25 12:30:36', '2013-06-25 12:30:36', 1, 1),
(364, '2013-06-25 12:30:36', '2013-06-25 12:30:36', 1, 1),
(365, '2013-06-25 12:30:36', '2013-06-25 12:30:36', 1, 1),
(366, '2013-06-25 12:30:36', '2013-06-25 12:30:36', 1, 1),
(367, '2013-06-25 12:30:36', '2013-06-25 12:30:36', 1, 1),
(368, '2013-06-25 12:30:36', '2013-06-25 12:30:36', 1, 1),
(369, '2013-06-25 12:30:36', '2013-06-25 12:30:36', 1, 1),
(370, '2013-06-25 12:30:36', '2013-06-25 12:30:36', 1, 1),
(371, '2013-06-25 12:30:36', '2013-06-25 12:30:36', 1, 1),
(372, '2013-06-25 12:30:36', '2013-06-25 12:30:36', 1, 1),
(373, '2013-06-25 12:30:36', '2013-06-25 12:30:36', 1, 1),
(374, '2013-06-25 12:30:37', '2013-06-25 12:30:37', 1, 1),
(375, '2013-06-25 12:30:37', '2013-06-25 12:30:37', 1, 1),
(376, '2013-06-25 12:30:37', '2013-06-25 12:30:37', 1, 1),
(377, '2013-06-25 12:30:37', '2013-06-25 12:30:37', 1, 1),
(378, '2013-06-25 12:30:37', '2013-06-25 12:30:37', 1, 1),
(379, '2013-06-25 12:30:37', '2013-06-25 12:30:37', 1, 1),
(380, '2013-06-25 12:30:37', '2013-06-25 12:30:37', 1, 1),
(381, '2013-06-25 12:30:37', '2013-06-25 12:30:37', 1, 1),
(382, '2013-06-25 12:30:37', '2013-06-25 12:30:37', 1, 1),
(383, '2013-06-25 12:30:37', '2013-06-25 12:30:37', 1, 1),
(384, '2013-06-25 12:30:37', '2013-06-25 12:30:37', 1, 1),
(385, '2013-06-25 12:30:37', '2013-06-25 12:30:37', 1, 1),
(386, '2013-06-25 12:30:38', '2013-06-25 12:30:38', 1, 1),
(387, '2013-06-25 12:30:38', '2013-06-25 12:30:38', 1, 1),
(388, '2013-06-25 12:30:38', '2013-06-25 12:30:38', 1, 1),
(389, '2013-06-25 12:30:38', '2013-06-25 12:30:38', 1, 1),
(390, '2013-06-25 12:30:38', '2013-06-25 12:30:38', 1, 1),
(391, '2013-06-25 12:30:38', '2013-06-25 12:30:38', 1, 1),
(392, '2013-06-25 12:30:38', '2013-06-25 12:30:38', 1, 1),
(393, '2013-06-25 12:30:38', '2013-06-25 12:30:38', 1, 1),
(394, '2013-06-25 12:30:38', '2013-06-25 12:30:38', 1, 1),
(395, '2013-06-25 12:30:38', '2013-06-25 12:30:38', 1, 1),
(396, '2013-06-25 12:30:38', '2013-06-25 12:30:38', 1, 1),
(397, '2013-06-25 12:30:38', '2013-06-25 12:30:38', 1, 1),
(398, '2013-06-25 12:30:38', '2013-06-25 12:30:38', 1, 1),
(399, '2013-06-25 12:30:38', '2013-06-25 12:30:38', 1, 1),
(400, '2013-06-25 12:30:38', '2013-06-25 12:30:38', 1, 1),
(401, '2013-06-25 12:30:38', '2013-06-25 12:30:38', 1, 1),
(402, '2013-06-25 12:30:38', '2013-06-25 12:30:38', 1, 1),
(403, '2013-06-25 12:30:38', '2013-06-25 12:30:38', 1, 1),
(404, '2013-06-25 12:30:38', '2013-06-25 12:30:38', 1, 1),
(405, '2013-06-25 12:30:38', '2013-06-25 12:30:38', 1, 1),
(406, '2013-06-25 12:30:38', '2013-06-25 12:30:38', 1, 1),
(407, '2013-06-25 12:30:38', '2013-06-25 12:30:38', 1, 1),
(408, '2013-06-25 12:30:38', '2013-06-25 12:30:38', 1, 1),
(409, '2013-06-25 12:30:38', '2013-06-25 12:30:38', 1, 1),
(410, '2013-06-25 12:30:38', '2013-06-25 12:30:38', 1, 1),
(411, '2013-06-25 12:30:38', '2013-06-25 12:30:38', 1, 1),
(412, '2013-06-25 12:30:39', '2013-06-25 12:30:39', 1, 1),
(413, '2013-06-25 12:30:39', '2013-06-25 12:30:39', 1, 1),
(414, '2013-06-25 12:30:39', '2013-06-25 12:30:39', 1, 1),
(415, '2013-06-25 12:30:39', '2013-06-25 12:30:39', 1, 1),
(416, '2013-06-25 12:30:39', '2013-06-25 12:30:39', 1, 1),
(417, '2013-06-25 12:30:39', '2013-06-25 12:30:39', 1, 1),
(418, '2013-06-25 12:30:39', '2013-06-25 12:30:39', 1, 1),
(419, '2013-06-25 12:30:39', '2013-06-25 12:30:39', 1, 1),
(420, '2013-06-25 12:30:39', '2013-06-25 12:30:39', 1, 1),
(421, '2013-06-25 12:30:39', '2013-06-25 12:30:39', 1, 1),
(422, '2013-06-25 12:30:39', '2013-06-25 12:30:39', 1, 1),
(423, '2013-06-25 12:30:39', '2013-06-25 12:30:39', 1, 1),
(424, '2013-06-25 12:30:39', '2013-06-25 12:30:39', 1, 1),
(425, '2013-06-25 12:30:39', '2013-06-25 12:30:39', 1, 1),
(426, '2013-06-25 12:30:39', '2013-06-25 12:30:40', 1, 1),
(427, '2013-06-25 12:30:40', '2013-06-25 12:30:40', 1, 1),
(428, '2013-06-25 12:30:40', '2013-06-25 12:30:40', 1, 1),
(429, '2013-06-25 12:30:40', '2013-06-25 12:30:40', 1, 1),
(430, '2013-06-25 12:30:40', '2013-06-25 12:30:40', 1, 1),
(431, '2013-06-25 12:30:40', '2013-06-25 12:30:40', 1, 1),
(432, '2013-06-25 12:30:40', '2013-06-25 12:30:40', 1, 1),
(433, '2013-06-25 12:30:40', '2013-06-25 12:30:40', 1, 1),
(434, '2013-06-25 12:30:40', '2013-06-25 12:30:40', 1, 1),
(435, '2013-06-25 12:30:40', '2013-06-25 12:30:41', 1, 1),
(436, '2013-06-25 12:30:41', '2013-06-25 12:30:41', 1, 1),
(437, '2013-06-25 12:30:41', '2013-06-25 12:30:41', 1, 1),
(438, '2013-06-25 12:30:41', '2013-06-25 12:30:41', 1, 1),
(439, '2013-06-25 12:30:41', '2013-06-25 12:30:41', 1, 1),
(440, '2013-06-25 12:30:41', '2013-06-25 12:30:41', 1, 1),
(441, '2013-06-25 12:30:41', '2013-06-25 12:30:41', 1, 1),
(442, '2013-06-25 12:30:41', '2013-06-25 12:30:41', 1, 1),
(443, '2013-06-25 12:30:41', '2013-06-25 12:30:41', 1, 1),
(444, '2013-06-25 12:30:41', '2013-06-25 12:30:42', 1, 1),
(445, '2013-06-25 12:30:42', '2013-06-25 12:30:42', 1, 1),
(446, '2013-06-25 12:30:42', '2013-06-25 12:30:42', 1, 1),
(447, '2013-06-25 12:30:42', '2013-06-25 12:30:42', 1, 1),
(448, '2013-06-25 12:30:42', '2013-06-25 12:30:42', 1, 1),
(449, '2013-06-25 12:30:42', '2013-06-25 12:30:42', 1, 1),
(450, '2013-06-25 12:30:42', '2013-06-25 12:30:42', 1, 1),
(451, '2013-06-25 12:30:42', '2013-06-25 12:30:42', 1, 1),
(452, '2013-06-25 12:30:42', '2013-06-25 12:30:42', 1, 1),
(453, '2013-06-25 12:30:42', '2013-06-25 12:30:42', 1, 1),
(454, '2013-06-25 12:30:42', '2013-06-25 12:30:43', 1, 1),
(455, '2013-06-25 12:30:43', '2013-06-25 12:30:43', 1, 1),
(456, '2013-06-25 12:30:43', '2013-06-25 12:30:43', 1, 1),
(457, '2013-06-25 12:30:43', '2013-06-25 12:30:43', 1, 1),
(458, '2013-06-25 12:30:43', '2013-06-25 12:30:43', 1, 1),
(459, '2013-06-25 12:30:43', '2013-06-25 12:30:43', 1, 1),
(460, '2013-06-25 12:30:43', '2013-06-25 12:30:43', 1, 1),
(461, '2013-06-25 12:30:43', '2013-06-25 12:30:43', 1, 1),
(462, '2013-06-25 12:30:43', '2013-06-25 12:30:43', 1, 1),
(463, '2013-06-25 12:30:43', '2013-06-25 12:30:44', 1, 1),
(464, '2013-06-25 12:30:44', '2013-06-25 12:30:44', 1, 1),
(465, '2013-06-25 12:30:44', '2013-06-25 12:30:44', 1, 1),
(466, '2013-06-25 12:30:44', '2013-06-25 12:30:44', 1, 1),
(467, '2013-06-25 12:30:44', '2013-06-25 12:30:44', 1, 1),
(468, '2013-06-25 12:30:44', '2013-06-25 12:30:44', 1, 1),
(469, '2013-06-25 12:30:44', '2013-06-25 12:30:44', 1, 1),
(470, '2013-06-25 12:30:44', '2013-06-25 12:30:44', 1, 1),
(471, '2013-06-25 12:30:44', '2013-06-25 12:30:44', 1, 1),
(472, '2013-06-25 12:30:44', '2013-06-25 12:30:44', 1, 1),
(473, '2013-06-25 12:30:45', '2013-06-25 12:30:45', 1, 1),
(474, '2013-06-25 12:30:45', '2013-06-25 12:30:45', 1, 1),
(475, '2013-06-25 12:30:45', '2013-06-25 12:30:45', 1, 1),
(476, '2013-06-25 12:30:45', '2013-06-25 12:30:45', 1, 1),
(477, '2013-06-25 12:30:45', '2013-06-25 12:30:45', 1, 1),
(478, '2013-06-25 12:30:45', '2013-06-25 12:30:45', 1, 1),
(479, '2013-06-25 12:30:45', '2013-06-25 12:30:45', 1, 1),
(480, '2013-06-25 12:30:45', '2013-06-25 12:30:45', 9, 1),
(481, '2013-06-25 12:30:45', '2013-06-25 12:30:45', 4, 1),
(482, '2013-06-25 12:30:45', '2013-06-25 12:30:45', 6, 1),
(483, '2013-06-25 12:30:45', '2013-06-25 12:30:45', 3, 1),
(484, '2013-06-25 12:30:45', '2013-06-25 12:30:45', 5, 1),
(485, '2013-06-25 12:30:45', '2013-06-25 12:30:45', 4, 1),
(486, '2013-06-25 12:30:46', '2013-06-25 12:30:46', 5, 1),
(487, '2013-06-25 12:30:46', '2013-06-25 12:30:46', 3, 1),
(488, '2013-06-25 12:30:46', '2013-06-25 12:30:46', 4, 1),
(489, '2013-06-25 12:30:46', '2013-06-25 12:30:46', 10, 1),
(490, '2013-06-25 12:30:46', '2013-06-25 12:30:46', 5, 1),
(491, '2013-06-25 12:30:46', '2013-06-25 12:30:46', 1, 1),
(492, '2013-06-25 12:30:46', '2013-06-25 12:30:46', 3, 1),
(493, '2013-06-25 12:30:46', '2013-06-25 12:30:46', 6, 1),
(494, '2013-06-25 12:30:46', '2013-06-25 12:30:46', 9, 1),
(495, '2013-06-25 12:30:46', '2013-06-25 12:30:46', 4, 1),
(496, '2013-06-25 12:30:46', '2013-06-25 12:30:46', 8, 1),
(497, '2013-06-25 12:30:46', '2013-06-25 12:30:46', 6, 1),
(498, '2013-06-25 12:30:46', '2013-06-25 12:30:46', 10, 1),
(499, '2013-06-25 12:30:46', '2013-06-25 12:30:46', 9, 1),
(500, '2013-06-25 12:30:46', '2013-06-25 12:30:46', 5, 1),
(501, '2013-06-25 12:30:46', '2013-06-25 12:30:46', 9, 1),
(502, '2013-06-25 12:30:46', '2013-06-25 12:30:46', 3, 1),
(503, '2013-06-25 12:30:46', '2013-06-25 12:30:46', 8, 1),
(504, '2013-06-25 12:30:46', '2013-06-25 12:30:46', 7, 1),
(505, '2013-06-25 12:30:46', '2013-06-25 12:30:46', 6, 1),
(506, '2013-06-25 12:30:46', '2013-06-25 12:30:46', 1, 1),
(507, '2013-06-25 12:30:46', '2013-06-25 12:30:46', 3, 1),
(508, '2013-06-25 12:30:46', '2013-06-25 12:30:46', 8, 1),
(509, '2013-06-25 12:30:46', '2013-06-25 12:30:46', 10, 1),
(510, '2013-06-25 12:30:46', '2013-06-25 12:30:46', 10, 1),
(511, '2013-06-25 12:30:46', '2013-06-25 12:30:46', 1, 1),
(512, '2013-06-25 12:30:46', '2013-06-25 12:30:46', 6, 1),
(513, '2013-06-25 12:30:46', '2013-06-25 12:30:46', 9, 1),
(514, '2013-06-25 12:30:46', '2013-06-25 12:30:46', 6, 1),
(515, '2013-06-25 12:30:46', '2013-06-25 12:30:46', 4, 1),
(516, '2013-06-25 12:30:46', '2013-06-25 12:30:46', 6, 1),
(517, '2013-06-25 12:30:46', '2013-06-25 12:30:46', 10, 1),
(518, '2013-06-25 12:30:47', '2013-06-25 12:30:47', 1, 1),
(519, '2013-06-25 12:30:47', '2013-06-25 12:30:47', 1, 1),
(520, '2013-06-25 12:30:47', '2013-06-25 12:30:47', 1, 1),
(521, '2013-06-25 12:30:47', '2013-06-25 12:30:47', 1, 1),
(522, '2013-06-25 12:30:47', '2013-06-25 12:30:47', 1, 1),
(523, '2013-06-25 12:30:47', '2013-06-25 12:30:47', 1, 1),
(524, '2013-06-25 12:30:47', '2013-06-25 12:30:47', 1, 1),
(525, '2013-06-25 12:30:47', '2013-06-25 12:30:47', 1, 1),
(526, '2013-06-25 12:30:47', '2013-06-25 12:30:47', 1, 1),
(527, '2013-06-25 12:30:47', '2013-06-25 12:30:47', 1, 1),
(528, '2013-06-25 12:30:47', '2013-06-25 12:30:47', 1, 1),
(529, '2013-06-25 12:30:47', '2013-06-25 12:30:47', 1, 1),
(530, '2013-06-25 12:30:47', '2013-06-25 12:30:47', 1, 1),
(531, '2013-06-25 12:30:47', '2013-06-25 12:30:47', 1, 1),
(532, '2013-06-25 12:30:47', '2013-06-25 12:30:47', 1, 1),
(533, '2013-06-25 12:30:47', '2013-06-25 12:30:47', 1, 1),
(534, '2013-06-25 12:30:47', '2013-06-25 12:30:47', 1, 1),
(535, '2013-06-25 12:30:47', '2013-06-25 12:30:47', 1, 1),
(536, '2013-06-25 12:30:47', '2013-06-25 12:30:47', 1, 1),
(537, '2013-06-25 12:30:48', '2013-06-25 12:30:48', 1, 1),
(538, '2013-06-25 12:30:48', '2013-06-25 12:30:48', 1, 1),
(539, '2013-06-25 12:30:48', '2013-06-25 12:30:48', 1, 1),
(540, '2013-06-25 12:30:48', '2013-06-25 12:30:48', 1, 1),
(541, '2013-06-25 12:30:48', '2013-06-25 12:30:48', 1, 1),
(542, '2013-06-25 12:30:48', '2013-06-25 12:30:48', 1, 1),
(543, '2013-06-25 12:30:48', '2013-06-25 12:30:48', 1, 1),
(544, '2013-06-25 12:30:48', '2013-06-25 12:30:48', 1, 1),
(545, '2013-06-25 12:30:48', '2013-06-25 12:30:48', 1, 1),
(546, '2013-06-25 12:30:48', '2013-06-25 12:30:48', 1, 1),
(547, '2013-06-25 12:30:48', '2013-06-25 12:30:48', 1, 1),
(548, '2013-06-25 12:30:49', '2013-06-25 12:30:49', 1, 1),
(549, '2013-06-25 12:30:49', '2013-06-25 12:30:49', 1, 1),
(550, '2016-01-04 16:06:37', '2016-01-04 16:06:43', 1, 1),
(551, '2016-01-04 16:06:37', '2016-01-04 16:06:43', 1, 1),
(552, '2016-01-04 16:06:37', '2016-01-04 16:06:43', 1, 1),
(553, '2016-01-04 16:06:37', '2016-01-04 16:06:43', 1, 1),
(554, '2016-01-04 16:06:37', '2016-01-04 16:06:43', 1, 1),
(555, '2016-01-04 16:06:37', '2016-01-04 16:06:43', 1, 1),
(556, '2016-01-04 16:06:51', '2016-01-04 16:06:51', 1, 1),
(557, '2016-01-04 16:06:51', '2016-01-04 16:06:51', 1, 1),
(558, '2016-01-05 05:58:33', '2016-01-19 09:27:01', 1, 1),
(559, '2016-01-05 05:58:36', '2016-01-19 07:47:14', 1, 1),
(560, '2016-01-05 10:29:36', '2016-01-19 13:50:05', 1, 1),
(561, '2016-01-05 10:29:36', '2016-01-19 13:42:13', 1, 1),
(562, '2016-01-05 10:33:35', '2016-01-05 10:33:35', 1, 1),
(563, '2016-01-05 10:33:34', '2016-01-05 10:33:37', 1, 1),
(564, '2016-01-05 10:33:39', '2016-01-14 09:56:51', 1, 1),
(565, '2016-01-05 10:33:39', '2016-01-05 10:33:39', 1, 1),
(566, '2016-01-05 10:33:40', '2016-01-11 06:59:32', 1, 1),
(567, '2016-01-05 10:35:03', '2016-01-05 10:35:03', 1, 1),
(568, '2016-01-05 10:35:04', '2016-01-19 19:55:22', 1, 1),
(569, '2016-01-05 10:35:05', '2016-01-19 18:15:06', 1, 1),
(570, '2016-01-05 10:39:22', '2016-01-05 10:39:22', 1, 1),
(571, '2016-01-05 11:11:01', '2016-01-05 11:11:01', 1, 1),
(572, '2016-01-05 13:10:16', '2016-01-06 06:56:50', 1, 1),
(573, '2016-01-06 06:56:51', '2016-01-19 19:51:08', 1, 1),
(574, '2016-01-06 06:57:03', '2016-01-07 03:48:52', 1, 1),
(575, '2016-01-06 12:21:35', '2016-01-06 12:21:38', 1, 1),
(576, '2016-01-06 12:21:38', '2016-01-06 12:21:40', 1, 1),
(577, '2016-01-06 12:25:57', '2016-01-06 12:26:00', 1, 1),
(578, '2016-01-06 12:26:02', '2016-01-12 18:51:54', 1, 1),
(579, '2016-01-06 12:26:03', '2016-01-12 18:51:54', 1, 1),
(580, '2016-01-06 12:26:03', '2016-01-06 12:26:03', 1, 1),
(581, '2016-01-06 12:26:03', '2016-01-06 12:26:03', 1, 1),
(582, '2016-01-06 12:26:59', '2016-01-06 12:26:59', 1, 1),
(583, '2016-01-06 12:27:00', '2016-01-07 03:48:31', 1, 1),
(584, '2016-01-06 12:27:01', '2016-01-07 03:48:32', 1, 1),
(585, '2016-01-06 12:27:01', '2016-01-06 12:27:01', 1, 1),
(586, '2016-01-06 12:27:01', '2016-01-06 12:27:01', 1, 1),
(587, '2016-01-07 03:47:25', '2016-01-07 03:47:26', 1, 1),
(588, '2016-01-07 03:47:26', '2016-01-07 03:47:26', 1, 1),
(589, '2016-01-07 03:47:27', '2016-01-07 03:47:27', 1, 1),
(590, '2016-01-07 03:47:28', '2016-01-07 03:47:28', 1, 1),
(591, '2016-01-07 03:47:42', '2016-01-07 03:51:34', 1, 1),
(592, '2016-01-07 03:47:43', '2016-01-07 03:51:44', 1, 1),
(593, '2016-01-07 03:47:43', '2016-01-07 03:51:46', 1, 1),
(594, '2016-01-07 03:47:45', '2016-01-07 03:47:45', 1, 1),
(595, '2016-01-07 03:47:45', '2016-01-07 03:47:45', 1, 1),
(596, '2016-01-07 03:48:16', '2016-01-07 03:48:17', 1, 1),
(597, '2016-01-07 03:48:31', '2016-01-07 03:48:31', 1, 1),
(598, '2016-01-07 03:49:10', '2016-01-20 12:42:57', 1, 1),
(599, '2016-01-07 03:51:43', '2016-01-07 03:51:45', 1, 1),
(600, '2016-01-07 04:56:11', '2016-01-07 04:56:11', 1, 1),
(601, '2016-01-07 04:56:14', '2016-01-07 04:56:14', 1, 1),
(602, '2016-01-07 04:56:14', '2016-01-07 04:56:14', 1, 1),
(603, '2016-01-07 04:56:14', '2016-01-07 04:56:14', 1, 1),
(604, '2016-01-07 04:56:14', '2016-01-07 04:56:14', 1, 1),
(605, '2016-01-07 04:56:14', '2016-01-07 04:56:14', 1, 1),
(606, '2016-01-07 04:56:14', '2016-01-07 04:56:14', 1, 1),
(607, '2016-01-07 04:56:14', '2016-01-07 04:56:15', 1, 1),
(608, '2016-01-07 04:56:14', '2016-01-07 04:56:15', 1, 1),
(609, '2016-01-07 04:56:14', '2016-01-07 04:56:15', 1, 1),
(610, '2016-01-08 16:57:56', '2016-01-08 16:57:56', 1, 1),
(612, '2016-01-08 17:01:25', '2016-01-15 21:47:31', 1, 1),
(613, '2016-01-08 17:01:27', '2016-01-12 18:13:11', 1, 1),
(614, '2016-01-08 17:02:31', '2016-01-08 19:02:49', 1, 1),
(616, '2016-01-08 17:17:26', '2016-01-19 19:43:58', 1, 1),
(628, '2016-01-12 18:51:53', '2016-01-12 18:51:53', 1, 1),
(630, '2016-01-12 18:51:54', '2016-01-12 18:51:54', 1, 1),
(636, '2016-01-15 18:48:18', '2016-01-15 18:48:18', 1, 1),
(637, '2016-01-15 18:48:18', '2016-01-15 18:48:18', 1, 1),
(638, '2016-01-15 19:42:22', '2016-01-15 19:44:25', 1, 1),
(639, '2016-01-15 19:44:42', '2016-01-15 19:44:43', 1, 1),
(641, '2016-01-15 19:44:43', '2016-01-15 19:44:43', 1, 1),
(643, '2016-01-15 19:44:43', '2016-01-15 19:44:43', 1, 1),
(644, '2016-01-15 19:44:43', '2016-01-15 19:44:43', 1, 1),
(645, '2016-01-15 19:44:43', '2016-01-15 19:44:43', 1, 1),
(646, '2016-01-15 19:44:43', '2016-01-15 19:44:43', 1, 1),
(647, '2016-01-15 19:44:43', '2016-01-15 19:44:43', 1, 1),
(648, '2016-01-15 19:44:43', '2016-01-15 19:44:43', 1, 1),
(649, '2016-01-15 19:44:43', '2016-01-15 19:44:43', 1, 1),
(650, '2016-01-15 19:44:43', '2016-01-15 19:44:43', 1, 1),
(651, '2016-01-15 19:44:43', '2016-01-15 19:44:43', 1, 1),
(652, '2016-01-15 19:44:43', '2016-01-15 19:44:43', 1, 1),
(653, '2016-01-15 19:44:43', '2016-01-15 19:44:43', 1, 1),
(654, '2016-01-15 19:44:43', '2016-01-15 19:44:43', 1, 1),
(655, '2016-01-15 19:44:43', '2016-01-15 19:44:43', 1, 1),
(656, '2016-01-15 19:44:43', '2016-01-15 19:44:43', 1, 1),
(657, '2016-01-15 19:44:43', '2016-01-15 19:44:43', 1, 1),
(658, '2016-01-15 19:44:43', '2016-01-15 19:44:43', 1, 1),
(659, '2016-01-15 19:44:43', '2016-01-15 19:44:43', 1, 1),
(660, '2016-01-15 19:44:43', '2016-01-15 19:44:44', 1, 1),
(661, '2016-01-15 19:44:44', '2016-01-18 16:46:18', 1, 1),
(662, '2016-01-15 19:44:44', '2016-01-15 19:44:44', 1, 1),
(663, '2016-01-15 19:44:44', '2016-01-15 19:44:44', 1, 1),
(664, '2016-01-15 19:44:44', '2016-01-15 19:44:44', 1, 1),
(665, '2016-01-15 19:44:44', '2016-01-15 19:44:44', 1, 1),
(666, '2016-01-15 19:44:44', '2016-01-15 19:44:44', 1, 1),
(667, '2016-01-15 19:44:44', '2016-01-15 19:44:44', 1, 1),
(668, '2016-01-15 19:44:44', '2016-01-15 19:44:44', 1, 1),
(669, '2016-01-15 19:44:44', '2016-01-15 19:44:44', 1, 1),
(670, '2016-01-15 19:44:44', '2016-01-15 19:44:44', 1, 1),
(671, '2016-01-15 19:44:44', '2016-01-15 19:44:44', 1, 1),
(672, '2016-01-15 19:44:44', '2016-01-15 19:44:44', 1, 1),
(673, '2016-01-15 19:44:44', '2016-01-15 19:44:44', 1, 1),
(674, '2016-01-15 19:44:44', '2016-01-15 19:44:44', 1, 1),
(675, '2016-01-15 19:44:44', '2016-01-15 19:44:44', 1, 1),
(676, '2016-01-15 19:44:44', '2016-01-15 19:44:44', 1, 1),
(677, '2016-01-15 19:44:44', '2016-01-15 19:44:44', 1, 1),
(678, '2016-01-15 19:44:44', '2016-01-15 19:44:44', 1, 1),
(679, '2016-01-15 19:44:44', '2016-01-15 19:44:44', 1, 1),
(680, '2016-01-15 19:44:44', '2016-01-15 19:44:44', 1, 1),
(681, '2016-01-15 19:44:44', '2016-01-15 19:44:44', 1, 1),
(682, '2016-01-15 19:44:44', '2016-01-15 19:44:44', 1, 1),
(683, '2016-01-15 19:44:44', '2016-01-15 19:44:45', 1, 1),
(684, '2016-01-15 19:44:45', '2016-01-15 19:44:45', 1, 1),
(685, '2016-01-15 19:44:45', '2016-01-15 19:44:45', 1, 1),
(686, '2016-01-15 19:44:45', '2016-01-15 19:44:45', 1, 1),
(687, '2016-01-15 19:44:45', '2016-01-15 19:44:45', 1, 1),
(688, '2016-01-15 19:44:45', '2016-01-15 19:44:45', 1, 1),
(689, '2016-01-15 19:44:45', '2016-01-15 19:44:46', 1, 1),
(690, '2016-01-15 19:44:46', '2016-01-15 19:44:46', 1, 1),
(691, '2016-01-15 19:44:46', '2016-01-15 19:44:46', 1, 1),
(692, '2016-01-15 19:44:46', '2016-01-15 19:44:46', 1, 1),
(693, '2016-01-15 19:44:46', '2016-01-15 19:44:46', 1, 1),
(694, '2016-01-15 19:44:46', '2016-01-15 19:44:46', 1, 1),
(695, '2016-01-15 19:44:46', '2016-01-15 19:44:46', 1, 1),
(696, '2016-01-15 19:44:46', '2016-01-15 19:44:46', 1, 1),
(697, '2016-01-15 19:44:46', '2016-01-15 19:44:46', 1, 1),
(698, '2016-01-15 19:46:00', '2016-01-19 13:58:00', 1, 1),
(699, '2016-01-15 19:46:00', '2016-01-15 19:46:00', 1, 1),
(700, '2016-01-15 21:47:31', '2016-01-19 19:54:32', 1, 1),
(701, '2016-01-15 21:56:55', '2016-01-15 22:00:54', 1, 1),
(702, '2016-01-15 22:13:57', '2016-01-20 12:02:38', 1, 1),
(703, '2016-01-15 22:13:58', '2016-01-20 12:42:55', 1, 1),
(704, '2016-01-15 22:13:58', '2016-01-15 22:13:58', 1, 1),
(705, '2016-01-15 22:13:58', '2016-01-15 22:13:58', 1, 1),
(706, '2016-01-15 22:13:58', '2016-01-19 19:16:48', 1, 1),
(707, '2016-01-15 22:13:58', '2016-01-15 22:13:58', 1, 1),
(708, '2016-01-15 22:13:58', '2016-01-15 22:13:58', 1, 1),
(709, '2016-01-15 22:13:58', '2016-01-19 19:16:49', 1, 1),
(710, '2016-01-15 22:13:58', '2016-01-15 22:13:58', 1, 1),
(711, '2016-01-15 22:13:58', '2016-01-15 22:13:58', 1, 1),
(712, '2016-01-15 22:13:58', '2016-01-15 22:13:58', 1, 1),
(713, '2016-01-15 22:13:58', '2016-01-19 19:16:46', 1, 1),
(714, '2016-01-15 22:13:58', '2016-01-15 22:13:58', 1, 1),
(715, '2016-01-15 22:13:58', '2016-01-19 19:16:49', 1, 1),
(716, '2016-01-15 22:13:58', '2016-01-15 22:13:58', 1, 1),
(717, '2016-01-15 22:13:59', '2016-01-19 19:16:48', 1, 1),
(718, '2016-01-15 22:13:59', '2016-01-15 22:13:59', 1, 1),
(719, '2016-01-15 22:13:59', '2016-01-15 22:13:59', 1, 1),
(720, '2016-01-15 22:13:59', '2016-01-15 22:13:59', 1, 1),
(721, '2016-01-15 22:13:59', '2016-01-19 19:16:48', 1, 1),
(722, '2016-01-15 22:13:59', '2016-01-19 19:16:49', 1, 1),
(723, '2016-01-15 22:13:59', '2016-01-19 19:16:48', 1, 1),
(724, '2016-01-15 22:13:59', '2016-01-15 22:13:59', 1, 1),
(725, '2016-01-15 22:13:59', '2016-01-15 22:13:59', 1, 1),
(726, '2016-01-15 22:13:59', '2016-01-15 22:13:59', 1, 1),
(727, '2016-01-15 22:13:59', '2016-01-19 19:16:50', 1, 1),
(728, '2016-01-15 22:13:59', '2016-01-15 22:13:59', 1, 1),
(729, '2016-01-15 22:13:59', '2016-01-19 19:16:50', 1, 1),
(730, '2016-01-15 22:13:59', '2016-01-19 19:16:50', 1, 1),
(731, '2016-01-15 22:13:59', '2016-01-19 19:16:50', 1, 1),
(732, '2016-01-15 22:13:59', '2016-01-15 22:14:00', 1, 1),
(733, '2016-01-15 22:14:00', '2016-01-15 22:14:00', 1, 1),
(734, '2016-01-15 22:14:00', '2016-01-19 19:16:50', 1, 1),
(735, '2016-01-15 22:14:00', '2016-01-15 22:14:00', 1, 1),
(736, '2016-01-15 22:14:00', '2016-01-15 22:14:00', 1, 1),
(737, '2016-01-15 22:14:00', '2016-01-15 22:14:00', 1, 1),
(738, '2016-01-15 22:14:00', '2016-01-15 22:14:00', 1, 1),
(739, '2016-01-15 22:14:00', '2016-01-15 22:14:00', 1, 1),
(740, '2016-01-15 22:14:00', '2016-01-15 22:14:00', 1, 1),
(741, '2016-01-15 22:14:00', '2016-01-15 22:14:00', 1, 1),
(742, '2016-01-15 22:14:00', '2016-01-19 19:16:51', 1, 1),
(743, '2016-01-15 22:14:00', '2016-01-15 22:14:00', 1, 1),
(744, '2016-01-15 22:14:00', '2016-01-15 22:14:00', 1, 1),
(745, '2016-01-15 22:14:00', '2016-01-15 22:14:00', 1, 1),
(746, '2016-01-15 22:14:00', '2016-01-15 22:14:01', 1, 1),
(747, '2016-01-15 22:14:01', '2016-01-19 19:16:51', 1, 1),
(748, '2016-01-15 22:14:01', '2016-01-19 19:16:46', 1, 1),
(749, '2016-01-15 22:14:01', '2016-01-19 19:16:46', 1, 1),
(750, '2016-01-15 22:14:01', '2016-01-19 19:16:46', 1, 1),
(751, '2016-01-15 22:14:01', '2016-01-19 19:16:46', 1, 1),
(752, '2016-01-15 22:14:02', '2016-01-15 22:14:02', 1, 1),
(753, '2016-01-15 22:14:02', '2016-01-15 22:14:02', 1, 1),
(754, '2016-01-15 22:14:02', '2016-01-19 19:16:48', 1, 1),
(755, '2016-01-15 22:14:02', '2016-01-15 22:14:02', 1, 1),
(756, '2016-01-15 22:14:02', '2016-01-19 19:16:51', 1, 1),
(757, '2016-01-15 22:14:02', '2016-01-15 22:14:02', 1, 1),
(758, '2016-01-15 22:14:02', '2016-01-19 19:16:51', 1, 1),
(759, '2016-01-15 22:14:03', '2016-01-15 22:14:20', 1, 1),
(760, '2016-01-15 22:14:37', '2016-01-15 22:14:37', 1, 1),
(761, '2016-01-15 22:20:11', '2016-01-15 22:26:39', 1, 1),
(762, '2016-01-15 22:27:05', '2016-01-19 19:18:35', 1, 1),
(763, '2016-01-15 22:27:07', '2016-01-15 22:31:24', 1, 1),
(764, '2016-01-15 22:27:47', '2016-01-15 22:31:08', 1, 1),
(765, '2016-01-15 22:31:19', '2016-01-19 19:55:22', 1, 1),
(766, '2016-01-15 22:31:19', '2016-01-19 19:18:30', 1, 1),
(767, '2016-01-15 22:31:20', '2016-01-19 19:18:30', 1, 1),
(768, '2016-01-15 22:31:20', '2016-01-19 19:18:30', 1, 1),
(769, '2016-01-15 22:31:20', '2016-01-19 19:18:30', 1, 1),
(770, '2016-01-15 22:31:20', '2016-01-19 19:18:31', 1, 1),
(771, '2016-01-15 22:31:20', '2016-01-19 19:18:31', 1, 1),
(772, '2016-01-15 22:31:20', '2016-01-19 19:18:31', 1, 1),
(773, '2016-01-15 22:31:20', '2016-01-19 19:18:31', 1, 1),
(774, '2016-01-15 22:31:20', '2016-01-19 19:18:31', 1, 1),
(775, '2016-01-15 22:31:20', '2016-01-19 19:18:32', 1, 1),
(776, '2016-01-15 22:31:20', '2016-01-19 19:18:32', 1, 1),
(777, '2016-01-15 22:31:20', '2016-01-19 19:18:32', 1, 1),
(778, '2016-01-15 22:31:20', '2016-01-19 19:18:32', 1, 1),
(779, '2016-01-15 22:31:20', '2016-01-19 19:18:32', 1, 1),
(780, '2016-01-15 22:31:20', '2016-01-19 19:18:32', 1, 1),
(781, '2016-01-15 22:31:20', '2016-01-19 19:18:33', 1, 1),
(782, '2016-01-15 22:31:20', '2016-01-19 19:18:33', 1, 1),
(783, '2016-01-15 22:31:21', '2016-01-19 19:18:33', 1, 1),
(784, '2016-01-15 22:31:21', '2016-01-19 19:18:33', 1, 1),
(785, '2016-01-15 22:31:21', '2016-01-19 19:18:33', 1, 1),
(786, '2016-01-15 22:31:21', '2016-01-19 19:18:33', 1, 1),
(787, '2016-01-15 22:31:21', '2016-01-19 19:18:33', 1, 1),
(788, '2016-01-15 22:31:21', '2016-01-19 19:18:33', 1, 1),
(789, '2016-01-15 22:31:21', '2016-01-19 19:18:33', 1, 1),
(790, '2016-01-15 22:31:21', '2016-01-19 19:18:34', 1, 1),
(791, '2016-01-15 22:31:21', '2016-01-19 19:18:34', 1, 1),
(792, '2016-01-15 22:31:21', '2016-01-19 19:18:34', 1, 1),
(793, '2016-01-15 22:31:21', '2016-01-19 19:18:34', 1, 1),
(794, '2016-01-15 22:31:21', '2016-01-19 19:18:34', 1, 1),
(795, '2016-01-15 22:31:21', '2016-01-19 19:18:35', 1, 1),
(796, '2016-01-15 22:31:21', '2016-01-19 19:18:35', 1, 1),
(797, '2016-01-15 22:31:21', '2016-01-19 19:18:35', 1, 1),
(798, '2016-01-15 22:31:22', '2016-01-19 19:18:35', 1, 1),
(799, '2016-01-15 22:31:22', '2016-01-19 19:18:36', 1, 1),
(800, '2016-01-15 22:31:22', '2016-01-19 19:18:36', 1, 1),
(801, '2016-01-15 22:31:22', '2016-01-19 19:18:36', 1, 1),
(802, '2016-01-15 22:31:22', '2016-01-19 19:18:36', 1, 1),
(803, '2016-01-15 22:31:22', '2016-01-19 19:18:36', 1, 1),
(804, '2016-01-15 22:31:22', '2016-01-19 19:18:36', 1, 1),
(805, '2016-01-15 22:31:22', '2016-01-19 19:18:36', 1, 1),
(806, '2016-01-15 22:31:22', '2016-01-19 19:18:36', 1, 1),
(807, '2016-01-15 22:31:22', '2016-01-19 19:18:36', 1, 1),
(808, '2016-01-15 22:31:22', '2016-01-19 19:18:36', 1, 1),
(809, '2016-01-15 22:31:22', '2016-01-19 19:18:37', 1, 1),
(810, '2016-01-15 22:31:22', '2016-01-19 19:18:37', 1, 1),
(811, '2016-01-15 22:31:22', '2016-01-19 19:18:37', 1, 1),
(812, '2016-01-15 22:31:22', '2016-01-19 19:18:37', 1, 1),
(813, '2016-01-15 22:31:22', '2016-01-19 19:18:37', 1, 1),
(814, '2016-01-15 22:31:23', '2016-01-19 19:18:38', 1, 1),
(815, '2016-01-15 22:31:23', '2016-01-19 19:18:38', 1, 1),
(816, '2016-01-15 22:31:23', '2016-01-19 19:18:38', 1, 1),
(817, '2016-01-15 22:31:23', '2016-01-19 19:18:38', 1, 1),
(818, '2016-01-15 22:31:23', '2016-01-19 19:18:38', 1, 1),
(819, '2016-01-15 22:31:24', '2016-01-19 19:18:39', 1, 1),
(820, '2016-01-15 22:31:24', '2016-01-19 19:18:39', 1, 1),
(821, '2016-01-15 22:31:24', '2016-01-19 19:18:39', 1, 1),
(822, '2016-01-15 22:31:24', '2016-01-19 19:18:39', 1, 1),
(823, '2016-01-19 14:17:01', '2016-01-19 19:18:30', 1, 1),
(824, '2016-01-19 14:17:01', '2016-01-19 14:17:01', 1, 1),
(825, '2016-01-19 14:20:42', '2016-01-19 14:22:35', 1, 1),
(826, '2016-01-19 14:20:42', '2016-01-19 14:20:42', 1, 1),
(827, '2016-01-19 18:14:09', '2016-01-19 18:15:21', 1, 1),
(828, '2016-01-19 18:14:09', '2016-01-19 18:14:09', 1, 1),
(829, '2016-01-19 18:45:59', '2016-01-19 19:16:46', 1, 1),
(830, '2016-01-19 18:45:59', '2016-01-19 18:45:59', 1, 1),
(831, '2016-01-19 19:43:57', '2016-01-19 19:43:58', 1, 1),
(832, '2016-01-19 20:19:22', '2016-01-19 20:19:22', 1, 1),
(833, '2016-01-19 20:19:22', '2016-01-19 20:19:22', 1, 1),
(834, '2016-01-19 20:19:22', '2016-01-19 20:19:22', 1, 1),
(835, '2016-01-19 20:19:22', '2016-01-19 20:19:22', 1, 1),
(836, '2016-01-19 20:19:22', '2016-01-19 20:19:22', 1, 1),
(837, '2016-01-19 20:19:22', '2016-01-19 20:19:22', 1, 1),
(838, '2016-01-19 20:19:22', '2016-01-19 20:19:22', 1, 1),
(839, '2016-01-19 20:19:22', '2016-01-19 20:19:22', 1, 1),
(840, '2016-01-19 20:19:22', '2016-01-19 20:19:22', 1, 1),
(841, '2016-01-19 20:19:22', '2016-01-19 20:19:22', 1, 1),
(842, '2016-01-19 20:19:22', '2016-01-19 20:19:22', 1, 1),
(843, '2016-01-19 20:19:22', '2016-01-19 20:19:22', 1, 1),
(844, '2016-01-19 20:19:22', '2016-01-19 20:19:22', 1, 1),
(845, '2016-01-19 20:19:22', '2016-01-19 20:19:22', 1, 1),
(846, '2016-01-19 20:19:22', '2016-01-19 20:19:22', 1, 1),
(847, '2016-01-19 20:19:22', '2016-01-19 20:19:22', 1, 1),
(848, '2016-01-19 20:19:22', '2016-01-19 20:19:22', 1, 1),
(849, '2016-01-19 20:19:22', '2016-01-19 20:19:22', 1, 1),
(850, '2016-01-19 20:19:22', '2016-01-19 20:19:22', 1, 1),
(851, '2016-01-19 20:19:22', '2016-01-19 20:19:22', 1, 1),
(852, '2016-01-19 20:19:22', '2016-01-19 20:19:22', 1, 1),
(853, '2016-01-19 20:19:22', '2016-01-19 20:19:22', 1, 1),
(854, '2016-01-19 20:19:22', '2016-01-19 20:19:22', 1, 1),
(855, '2016-01-19 20:19:22', '2016-01-19 20:19:22', 1, 1),
(856, '2016-01-19 20:19:22', '2016-01-19 20:19:22', 1, 1),
(857, '2016-01-19 20:19:22', '2016-01-19 20:19:22', 1, 1),
(858, '2016-01-19 20:19:22', '2016-01-19 20:19:22', 1, 1),
(859, '2016-01-19 20:19:22', '2016-01-19 20:19:22', 1, 1),
(860, '2016-01-19 20:19:22', '2016-01-19 20:19:22', 1, 1),
(861, '2016-01-19 20:19:22', '2016-01-19 20:19:22', 1, 1);

-- --------------------------------------------------------

--
-- Table structure for table `jobinprocess`
--

CREATE TABLE IF NOT EXISTS `jobinprocess` (
`id` int(11) unsigned NOT NULL,
  `item_id` int(11) unsigned DEFAULT NULL,
  `type` varchar(64) COLLATE utf8_unicode_ci DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `joblog`
--

CREATE TABLE IF NOT EXISTS `joblog` (
`id` int(11) unsigned NOT NULL,
  `item_id` int(11) unsigned DEFAULT NULL,
  `enddatetime` datetime DEFAULT NULL,
  `isprocessed` tinyint(1) unsigned DEFAULT NULL,
  `message` text COLLATE utf8_unicode_ci,
  `startdatetime` datetime DEFAULT NULL,
  `type` varchar(64) COLLATE utf8_unicode_ci DEFAULT NULL,
  `status` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `kanbanitem`
--

CREATE TABLE IF NOT EXISTS `kanbanitem` (
`id` int(11) unsigned NOT NULL,
  `type` int(11) DEFAULT NULL,
  `sortorder` int(11) DEFAULT NULL,
  `kanbanrelateditem_item_id` int(11) unsigned DEFAULT NULL,
  `task_id` int(11) unsigned DEFAULT NULL
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

--
-- Dumping data for table `kanbanitem`
--

INSERT INTO `kanbanitem` (`id`, `type`, `sortorder`, `kanbanrelateditem_item_id`, `task_id`) VALUES
(1, 1, 1, 574, 20),
(2, 1, 1, 77, 11),
(3, 1, 2, 77, 12),
(4, 1, 2, 574, 21);

-- --------------------------------------------------------

--
-- Table structure for table `marketinglist`
--

CREATE TABLE IF NOT EXISTS `marketinglist` (
`id` int(11) unsigned NOT NULL,
  `ownedsecurableitem_id` int(11) unsigned DEFAULT NULL,
  `name` varchar(64) COLLATE utf8_unicode_ci DEFAULT NULL,
  `description` text COLLATE utf8_unicode_ci,
  `fromname` varchar(64) COLLATE utf8_unicode_ci DEFAULT NULL,
  `fromaddress` varchar(64) COLLATE utf8_unicode_ci DEFAULT NULL,
  `anyonecansubscribe` tinyint(3) unsigned DEFAULT NULL
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

--
-- Dumping data for table `marketinglist`
--

INSERT INTO `marketinglist` (`id`, `ownedsecurableitem_id`, `name`, `description`, `fromname`, `fromaddress`, `anyonecansubscribe`) VALUES
(2, 26, 'Prospects', 'Lorem ipsum dolor sit amet, consectetur adipiscing elit.Mauris gravida erat nec nulla pharetra et lacinia dolor eleifend.', 'Marketing Team', 'marketing@zurmo.com', 1),
(3, 27, 'Sales', 'Vivamus varius sagittis est in porta. Aenean ac elit eu metus accumsan elementum nec vel leo.', 'Sales Team', 'sales@zurmo.com', 1),
(4, 28, 'Clients', 'Cras tempus lectus sit amet elit pretium mollis. Morbi interdum posuere lorem et gravida.', 'Development Team', 'development@zurmo.com', 0),
(5, 29, 'Companies', 'Nulla tempor pretium eros, ut aliquet tellus faucibus et. Donec mattis justo sed ipsum ultrices venenatis.', 'Special Offers', 'offers@zurmo.com', 0),
(6, 30, 'New Offers', 'Mauris ac laoreet dui. Phasellus placerat tincidunt varius.', 'Support Team', 'support@zurmo.com', 0);

-- --------------------------------------------------------

--
-- Table structure for table `marketinglistmember`
--

CREATE TABLE IF NOT EXISTS `marketinglistmember` (
`id` int(11) unsigned NOT NULL,
  `contact_id` int(11) unsigned DEFAULT NULL,
  `marketinglist_id` int(11) unsigned DEFAULT NULL,
  `createddatetime` datetime DEFAULT NULL,
  `modifieddatetime` datetime DEFAULT NULL,
  `unsubscribed` tinyint(3) unsigned DEFAULT NULL
) ENGINE=InnoDB AUTO_INCREMENT=62 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

--
-- Dumping data for table `marketinglistmember`
--

INSERT INTO `marketinglistmember` (`id`, `contact_id`, `marketinglist_id`, `createddatetime`, `modifieddatetime`, `unsubscribed`) VALUES
(2, 2, 2, '2013-06-20 12:29:41', '2013-06-25 12:29:41', 0),
(3, 3, 2, '2013-06-20 12:29:41', '2013-06-25 12:29:41', 0),
(4, 4, 2, '2013-05-27 12:29:41', '2013-06-25 12:29:41', 1),
(5, 5, 2, '2013-06-20 12:29:41', '2013-06-25 12:29:42', 1),
(6, 6, 2, '2013-05-30 12:29:42', '2013-06-25 12:29:42', 1),
(7, 7, 2, '2013-06-16 12:29:42', '2013-06-25 12:29:42', 0),
(8, 8, 2, '2013-06-04 12:29:42', '2013-06-25 12:29:42', 1),
(9, 9, 2, '2013-05-26 12:29:42', '2013-06-25 12:29:42', 1),
(10, 10, 2, '2013-06-23 12:29:42', '2013-06-25 12:29:42', 0),
(11, 11, 2, '2013-06-18 12:29:42', '2013-06-25 12:29:42', 1),
(12, 12, 2, '2013-06-05 12:29:42', '2013-06-25 12:29:42', 0),
(13, 13, 2, '2013-06-18 12:29:43', '2013-06-25 12:29:43', 1),
(14, 2, 3, '2013-05-31 12:29:43', '2013-06-25 12:29:43', 1),
(15, 3, 3, '2013-06-04 12:29:43', '2013-06-25 12:29:43', 0),
(16, 4, 3, '2013-05-31 12:29:43', '2013-06-25 12:29:43', 0),
(17, 5, 3, '2013-06-17 12:29:43', '2013-06-25 12:29:43', 1),
(18, 6, 3, '2013-05-27 12:29:43', '2013-06-25 12:29:43', 1),
(19, 7, 3, '2013-06-23 12:29:43', '2013-06-25 12:29:43', 0),
(20, 8, 3, '2013-06-03 12:29:43', '2013-06-25 12:29:44', 0),
(21, 9, 3, '2013-06-22 12:29:44', '2013-06-25 12:29:44', 1),
(22, 10, 3, '2013-06-10 12:29:44', '2013-06-25 12:29:44', 0),
(23, 11, 3, '2013-06-17 12:29:44', '2013-06-25 12:29:44', 1),
(24, 12, 3, '2013-05-31 12:29:44', '2013-06-25 12:29:44', 0),
(25, 13, 3, '2013-06-13 12:29:44', '2013-06-25 12:29:44', 0),
(26, 2, 4, '2013-05-27 12:29:44', '2013-06-25 12:29:44', 1),
(27, 3, 4, '2013-06-09 12:29:44', '2013-06-25 12:29:44', 0),
(28, 4, 4, '2013-05-27 12:29:45', '2013-06-25 12:29:45', 0),
(29, 5, 4, '2013-06-16 12:29:45', '2013-06-25 12:29:45', 0),
(30, 6, 4, '2013-06-03 12:29:45', '2013-06-25 12:29:45', 0),
(31, 7, 4, '2013-06-01 12:29:45', '2013-06-25 12:29:45', 1),
(32, 8, 4, '2013-05-31 12:29:45', '2013-06-25 12:29:45', 1),
(33, 9, 4, '2013-06-19 12:29:45', '2013-06-25 12:29:45', 0),
(34, 10, 4, '2013-06-19 12:29:45', '2013-06-25 12:29:45', 0),
(35, 11, 4, '2013-05-27 12:29:45', '2013-06-25 12:29:46', 0),
(36, 12, 4, '2013-06-02 12:29:46', '2013-06-25 12:29:46', 0),
(37, 13, 4, '2013-06-24 12:29:46', '2013-06-25 12:29:46', 1),
(38, 2, 5, '2013-06-13 12:29:46', '2013-06-25 12:29:46', 1),
(39, 3, 5, '2013-06-07 12:29:46', '2013-06-25 12:29:46', 1),
(40, 4, 5, '2013-06-24 12:29:46', '2013-06-25 12:29:46', 0),
(41, 5, 5, '2013-05-26 12:29:46', '2013-06-25 12:29:46', 1),
(42, 6, 5, '2013-06-10 12:29:46', '2013-06-25 12:29:46', 0),
(43, 7, 5, '2013-05-26 12:29:46', '2013-06-25 12:29:46', 0),
(44, 8, 5, '2013-06-11 12:29:47', '2013-06-25 12:29:47', 1),
(45, 9, 5, '2013-06-18 12:29:47', '2013-06-25 12:29:47', 1),
(46, 10, 5, '2013-06-06 12:29:47', '2013-06-25 12:29:47', 0),
(47, 11, 5, '2013-06-17 12:29:47', '2013-06-25 12:29:47', 1),
(48, 12, 5, '2013-06-15 12:29:47', '2013-06-25 12:29:47', 0),
(49, 13, 5, '2013-06-21 12:29:47', '2013-06-25 12:29:47', 0),
(50, 2, 6, '2013-05-29 12:29:47', '2013-06-25 12:29:47', 1),
(51, 3, 6, '2013-05-28 12:29:47', '2013-06-25 12:29:47', 1),
(52, 4, 6, '2013-06-16 12:29:47', '2013-06-25 12:29:47', 1),
(53, 5, 6, '2013-06-20 12:29:47', '2013-06-25 12:29:48', 0),
(54, 6, 6, '2013-06-16 12:29:48', '2013-06-25 12:29:48', 0),
(55, 7, 6, '2013-06-04 12:29:48', '2013-06-25 12:29:48', 1),
(56, 8, 6, '2013-06-09 12:29:48', '2013-06-25 12:29:48', 0),
(57, 9, 6, '2013-06-12 12:29:48', '2013-06-25 12:29:48', 1),
(58, 10, 6, '2013-06-05 12:29:48', '2013-06-25 12:29:48', 1),
(59, 11, 6, '2013-06-21 12:29:48', '2013-06-25 12:29:48', 0),
(60, 12, 6, '2013-06-17 12:29:48', '2013-06-25 12:29:48', 1),
(61, 13, 6, '2013-06-04 12:29:48', '2013-06-25 12:29:48', 1);

-- --------------------------------------------------------

--
-- Table structure for table `marketinglist_read`
--

CREATE TABLE IF NOT EXISTS `marketinglist_read` (
  `securableitem_id` int(11) unsigned NOT NULL,
  `munge_id` varchar(12) COLLATE utf8_unicode_ci NOT NULL,
  `count` int(8) unsigned NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

--
-- Dumping data for table `marketinglist_read`
--

INSERT INTO `marketinglist_read` (`securableitem_id`, `munge_id`, `count`) VALUES
(27, 'G3', 1),
(28, 'G3', 1),
(29, 'G3', 1),
(30, 'G3', 1),
(31, 'G3', 1);

-- --------------------------------------------------------

--
-- Table structure for table `meeting`
--

CREATE TABLE IF NOT EXISTS `meeting` (
`id` int(11) unsigned NOT NULL,
  `activity_id` int(11) unsigned DEFAULT NULL,
  `category_customfield_id` int(11) unsigned DEFAULT NULL,
  `description` text COLLATE utf8_unicode_ci,
  `enddatetime` datetime DEFAULT NULL,
  `location` varchar(64) COLLATE utf8_unicode_ci DEFAULT NULL,
  `name` varchar(64) COLLATE utf8_unicode_ci DEFAULT NULL,
  `startdatetime` datetime DEFAULT NULL,
  `processedforlatestactivity` tinyint(1) unsigned DEFAULT NULL,
  `logged` tinyint(1) unsigned DEFAULT NULL
) ENGINE=InnoDB AUTO_INCREMENT=39 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

--
-- Dumping data for table `meeting`
--

INSERT INTO `meeting` (`id`, `activity_id`, `category_customfield_id`, `description`, `enddatetime`, `location`, `name`, `startdatetime`, `processedforlatestactivity`, `logged`) VALUES
(2, 4, 118, NULL, '2013-08-07 12:33:48', 'Conference Room', 'Follow-up call', '2013-08-07 12:30:33', NULL, NULL),
(3, 5, 119, NULL, '2013-08-10 12:34:03', 'Conference Room', 'Phase 2 discussion', '2013-08-10 12:30:33', NULL, NULL),
(4, 6, 120, NULL, '2013-07-31 12:33:18', 'Conference Room', 'Proposal review', '2013-07-31 12:30:33', NULL, NULL),
(5, 7, 121, NULL, '2013-07-09 12:36:33', 'Meeting Room 1', 'Client service review', '2013-07-09 12:30:33', NULL, NULL),
(6, 8, 122, NULL, '2013-08-18 12:36:04', 'Meeting Room 1', 'Tradeshow preparation meeting', '2013-08-18 12:30:34', NULL, NULL),
(7, 9, 123, NULL, '2013-07-17 12:35:34', 'Meeting Room 1', 'Project kick-off', '2013-07-17 12:30:34', NULL, NULL),
(8, 10, 124, NULL, '2013-07-12 12:35:19', 'Conference Room', 'Tradeshow preparation meeting', '2013-07-12 12:30:34', NULL, NULL),
(9, 11, 125, NULL, '2013-08-03 12:34:49', 'Meeting Room 1', 'Technical requirements discussion', '2013-08-03 12:30:34', NULL, NULL),
(10, 12, 126, NULL, '2013-07-26 12:31:04', 'Meeting Room 1', 'Call follow up', '2013-07-26 12:30:34', NULL, NULL),
(11, 13, 127, NULL, '2013-08-06 12:36:19', 'Meeting Room 1', 'Follow-up call', '2013-08-06 12:30:34', NULL, NULL),
(12, 14, 128, NULL, '2013-06-26 12:31:49', 'Meeting Room 1', 'Client service review', '2013-06-26 12:30:34', NULL, NULL),
(13, 15, 129, NULL, '2013-06-29 12:31:04', 'Conference Room', 'Circle back on proposal', '2013-06-29 12:30:34', NULL, NULL),
(14, 16, 130, NULL, '2013-06-29 12:34:34', 'Telephone', 'Tradeshow preparation meeting', '2013-06-29 12:30:34', NULL, NULL),
(15, 17, 131, NULL, '2013-07-27 12:35:04', 'Meeting Room 1', 'Proposal review', '2013-07-27 12:30:34', NULL, NULL),
(16, 18, 132, NULL, '2013-07-06 12:31:04', 'Telephone', 'Proposal review', '2013-07-06 12:30:34', NULL, NULL),
(17, 19, 133, NULL, '2013-07-15 12:36:19', 'Telephone', 'Follow-up call', '2013-07-15 12:30:34', NULL, NULL),
(18, 20, 134, NULL, '2013-08-14 12:31:04', 'Telephone', 'Discuss new pricing', '2013-08-14 12:30:34', NULL, NULL),
(19, 21, 135, NULL, '2013-08-18 12:31:04', 'Conference Room', 'Proposal review', '2013-08-18 12:30:34', NULL, NULL),
(20, 22, 136, NULL, '2013-05-29 12:35:49', 'Conference Room', 'Discuss new pricing', '2013-05-29 12:30:34', NULL, NULL),
(21, 23, 137, NULL, '2013-06-13 12:34:04', 'Conference Room', 'Follow-up call', '2013-06-13 12:30:34', NULL, NULL),
(22, 24, 138, NULL, '2013-06-10 12:35:49', 'Telephone', 'Follow-up call', '2013-06-10 12:30:34', NULL, NULL),
(23, 25, 139, NULL, '2013-06-24 12:32:04', 'Conference Room', 'Follow-up call', '2013-06-24 12:30:34', NULL, NULL),
(24, 26, 140, NULL, '2013-06-19 12:32:04', 'Meeting Room 1', 'Client service review', '2013-06-19 12:30:34', NULL, NULL),
(25, 27, 141, NULL, '2013-05-31 12:33:34', 'Telephone', 'Proposal review', '2013-05-31 12:30:34', NULL, NULL),
(26, 28, 142, NULL, '2013-05-27 12:34:20', 'Meeting Room 1', 'Phase 2 discussion', '2013-05-27 12:30:35', NULL, NULL),
(27, 29, 143, NULL, '2013-05-31 12:33:20', 'Meeting Room 1', 'Project kick-off', '2013-05-31 12:30:35', NULL, NULL),
(28, 30, 144, NULL, '2013-06-11 12:35:35', 'Conference Room', 'Follow-up call', '2013-06-11 12:30:35', NULL, NULL),
(29, 31, 145, NULL, '2013-06-20 12:36:05', 'Conference Room', 'Proposal review', '2013-06-20 12:30:35', NULL, NULL),
(30, 32, 146, NULL, '2013-06-10 12:31:50', 'Telephone', 'Project kick-off', '2013-06-10 12:30:35', NULL, NULL),
(31, 33, 147, NULL, '2013-06-04 12:31:50', 'Telephone', 'Project kick-off', '2013-06-04 12:30:35', NULL, NULL),
(32, 34, 148, NULL, '2013-06-13 12:34:05', 'Meeting Room 1', 'Proposal review', '2013-06-13 12:30:35', NULL, NULL),
(33, 35, 149, NULL, '2013-06-18 12:31:35', 'Telephone', 'Follow-up call', '2013-06-18 12:30:35', NULL, NULL),
(34, 36, 150, NULL, '2013-06-14 12:36:05', 'Conference Room', 'Phase 2 discussion', '2013-06-14 12:30:35', NULL, NULL),
(35, 37, 151, NULL, '2013-06-14 12:33:20', 'Telephone', 'Phase 2 discussion', '2013-06-14 12:30:35', NULL, NULL),
(36, 38, 152, NULL, '2013-06-06 12:36:20', 'Meeting Room 1', 'Phase 2 discussion', '2013-06-06 12:30:35', NULL, NULL),
(37, 39, 153, NULL, '2013-06-18 12:35:50', 'Meeting Room 1', 'Follow-up call', '2013-06-18 12:30:35', NULL, NULL),
(38, 80, 227, '', '2016-01-21 06:00:00', '', 'test', '2016-01-08 06:00:00', 0, NULL);

-- --------------------------------------------------------

--
-- Table structure for table `meeting_read`
--

CREATE TABLE IF NOT EXISTS `meeting_read` (
  `securableitem_id` int(11) unsigned NOT NULL,
  `munge_id` varchar(12) COLLATE utf8_unicode_ci NOT NULL,
  `count` int(8) unsigned NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

--
-- Dumping data for table `meeting_read`
--

INSERT INTO `meeting_read` (`securableitem_id`, `munge_id`, `count`) VALUES
(123, 'R2', 1),
(124, 'R2', 1),
(125, 'R2', 1),
(126, 'R2', 1),
(127, 'R2', 1),
(128, 'R2', 1),
(129, 'R2', 1),
(130, 'R2', 1),
(131, 'R2', 1),
(132, 'R2', 1),
(133, 'R2', 1),
(134, 'R2', 1),
(135, 'R2', 1),
(136, 'R2', 1),
(137, 'R2', 1),
(138, 'R2', 1),
(139, 'R2', 1),
(140, 'R2', 1),
(141, 'R2', 1),
(142, 'R2', 1),
(143, 'R2', 1),
(144, 'R2', 1),
(145, 'R2', 1),
(146, 'R2', 1),
(147, 'R2', 1),
(148, 'R2', 1),
(149, 'R2', 1),
(150, 'R2', 1),
(151, 'R2', 1),
(152, 'R2', 1),
(153, 'R2', 1),
(154, 'R2', 1),
(155, 'R2', 1),
(156, 'R2', 1),
(157, 'R2', 1),
(158, 'R2', 1),
(308, 'G3', 1);

-- --------------------------------------------------------

--
-- Table structure for table `meeting_read_subscription`
--

CREATE TABLE IF NOT EXISTS `meeting_read_subscription` (
`id` int(11) unsigned NOT NULL,
  `userid` int(11) unsigned NOT NULL,
  `modelid` int(11) unsigned NOT NULL,
  `modifieddatetime` datetime DEFAULT NULL,
  `subscriptiontype` tinyint(4) DEFAULT NULL
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

--
-- Dumping data for table `meeting_read_subscription`
--

INSERT INTO `meeting_read_subscription` (`id`, `userid`, `modelid`, `modifieddatetime`, `subscriptiontype`) VALUES
(1, 1, 38, '2016-01-07 03:47:26', 1);

-- --------------------------------------------------------

--
-- Table structure for table `messagesource`
--

CREATE TABLE IF NOT EXISTS `messagesource` (
`id` int(11) unsigned NOT NULL,
  `category` varchar(50) COLLATE utf8_unicode_ci DEFAULT NULL,
  `source` blob
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `messagetranslation`
--

CREATE TABLE IF NOT EXISTS `messagetranslation` (
`id` int(11) unsigned NOT NULL,
  `messagesource_id` int(11) unsigned DEFAULT NULL,
  `translation` blob,
  `language` varchar(16) COLLATE utf8_unicode_ci DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `mission`
--

CREATE TABLE IF NOT EXISTS `mission` (
`id` int(11) unsigned NOT NULL,
  `ownedsecurableitem_id` int(11) unsigned DEFAULT NULL,
  `description` text COLLATE utf8_unicode_ci,
  `duedatetime` datetime DEFAULT NULL,
  `latestdatetime` datetime DEFAULT NULL,
  `reward` text COLLATE utf8_unicode_ci,
  `status` int(11) DEFAULT NULL,
  `takenbyuser__user_id` int(11) unsigned DEFAULT NULL
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

--
-- Dumping data for table `mission`
--

INSERT INTO `mission` (`id`, `ownedsecurableitem_id`, `description`, `duedatetime`, `latestdatetime`, `reward`, `status`, `takenbyuser__user_id`) VALUES
(2, 158, 'Can someone figure out a good location for the company party this year?', NULL, '2013-06-25 12:30:35', 'Lunch on me', 1, NULL),
(3, 159, 'Analyze server infrastructure, look for ways to save money', NULL, '2013-06-25 12:30:35', 'Knowing you are an awesome person', 1, NULL),
(4, 160, 'Get tax document notarized ', NULL, '2013-06-25 12:30:36', 'I will buy you dinner', 1, NULL),
(5, 161, 'Organize the new marketing initiative for summer sales', NULL, '2013-06-25 12:30:36', 'Starbucks 25 dollar gift card', 1, NULL);

-- --------------------------------------------------------

--
-- Table structure for table `mission_read`
--

CREATE TABLE IF NOT EXISTS `mission_read` (
  `securableitem_id` int(11) unsigned NOT NULL,
  `munge_id` varchar(12) COLLATE utf8_unicode_ci NOT NULL,
  `count` int(8) unsigned NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

--
-- Dumping data for table `mission_read`
--

INSERT INTO `mission_read` (`securableitem_id`, `munge_id`, `count`) VALUES
(159, 'G3', 1),
(159, 'R2', 1),
(160, 'G3', 1),
(160, 'R2', 1),
(161, 'G3', 1),
(161, 'R2', 1),
(162, 'G3', 1),
(162, 'R2', 1);

-- --------------------------------------------------------

--
-- Table structure for table `modelcreationapisync`
--

CREATE TABLE IF NOT EXISTS `modelcreationapisync` (
`id` int(11) unsigned NOT NULL,
  `servicename` varchar(50) COLLATE utf8_unicode_ci NOT NULL,
  `modelid` int(11) unsigned NOT NULL,
  `modelclassname` varchar(50) COLLATE utf8_unicode_ci NOT NULL,
  `createddatetime` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `multiplevaluescustomfield`
--

CREATE TABLE IF NOT EXISTS `multiplevaluescustomfield` (
`id` int(11) unsigned NOT NULL,
  `basecustomfield_id` int(11) unsigned DEFAULT NULL
) ENGINE=InnoDB AUTO_INCREMENT=10 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

--
-- Dumping data for table `multiplevaluescustomfield`
--

INSERT INTO `multiplevaluescustomfield` (`id`, `basecustomfield_id`) VALUES
(7, 341),
(8, 533),
(9, 534);

-- --------------------------------------------------------

--
-- Table structure for table `namedsecurableitem`
--

CREATE TABLE IF NOT EXISTS `namedsecurableitem` (
`id` int(11) unsigned NOT NULL,
  `securableitem_id` int(11) unsigned DEFAULT NULL,
  `name` varchar(64) COLLATE utf8_unicode_ci DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `named_securable_actual_permissions_cache`
--

CREATE TABLE IF NOT EXISTS `named_securable_actual_permissions_cache` (
  `securableitem_name` varchar(64) COLLATE utf8_unicode_ci NOT NULL,
  `permitable_id` int(11) unsigned NOT NULL,
  `allow_permissions` tinyint(3) unsigned NOT NULL,
  `deny_permissions` tinyint(3) unsigned NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

--
-- Dumping data for table `named_securable_actual_permissions_cache`
--

INSERT INTO `named_securable_actual_permissions_cache` (`securableitem_name`, `permitable_id`, `allow_permissions`, `deny_permissions`) VALUES
('AccountAccountAffiliationsModule', 1, 31, 0),
('AccountContactAffiliationsModule', 1, 31, 0),
('AccountsModule', 1, 31, 0),
('ApiModule', 1, 31, 0),
('CalendarsModule', 1, 31, 0),
('CampaignsModule', 1, 31, 0),
('ConfigurationModule', 1, 31, 0),
('ContactsModule', 1, 31, 0),
('ContactWebFormsModule', 1, 31, 0),
('ContractsModule', 1, 31, 0),
('ConversationsModule', 1, 31, 0),
('DesignerModule', 1, 31, 0),
('EmailMessagesModule', 1, 31, 0),
('EmailTemplatesModule', 1, 31, 0),
('ExportModule', 1, 31, 0),
('GameRewardsModule', 1, 31, 0),
('GroupsModule', 1, 31, 0),
('HomeModule', 1, 31, 0),
('ImportModule', 1, 31, 0),
('JobsManagerModule', 1, 31, 0),
('LeadsModule', 1, 31, 0),
('MapsModule', 1, 31, 0),
('MarketingListsModule', 1, 31, 0),
('MarketingModule', 1, 31, 0),
('MeetingsModule', 1, 31, 0),
('MissionsModule', 1, 31, 0),
('NotesModule', 1, 31, 0),
('OpportunitiesModule', 1, 31, 0),
('ProductsModule', 1, 31, 0),
('ProductTemplatesModule', 1, 31, 0),
('ProjectsModule', 1, 31, 0),
('ReportsModule', 1, 31, 0),
('RolesModule', 1, 31, 0),
('SocialItemsModule', 1, 31, 0),
('TasksModule', 1, 31, 0),
('UsersModule', 1, 31, 0),
('ValidationsModule', 1, 31, 0),
('WorkflowsModule', 1, 31, 0),
('ZurmoModule', 1, 31, 0);

-- --------------------------------------------------------

--
-- Table structure for table `note`
--

CREATE TABLE IF NOT EXISTS `note` (
`id` int(11) unsigned NOT NULL,
  `activity_id` int(11) unsigned DEFAULT NULL,
  `description` text COLLATE utf8_unicode_ci,
  `occurredondatetime` datetime DEFAULT NULL
) ENGINE=InnoDB AUTO_INCREMENT=26 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

--
-- Dumping data for table `note`
--

INSERT INTO `note` (`id`, `activity_id`, `description`, `occurredondatetime`) VALUES
(2, 40, 'System integration - jumpstart proposal', '2013-03-24 12:30:36'),
(3, 41, 'System integration - jumpstart proposal', '2013-05-02 12:30:36'),
(4, 42, 'Accouting information regarding wire payment', '2013-04-10 12:30:36'),
(5, 43, 'System integration - jumpstart proposal', '2013-06-15 12:30:36'),
(6, 44, 'System integration - jumpstart proposal', '2013-02-08 12:30:36'),
(7, 45, 'Accouting information regarding wire payment', '2013-05-11 12:30:36'),
(8, 46, 'Competitive landscape notes.', '2013-04-20 12:30:36'),
(9, 47, 'Competitive landscape notes.', '2012-12-30 12:30:36'),
(10, 48, 'E-mail: Re: Product changes.', '2013-02-03 12:30:36'),
(11, 49, 'Contract additions. Special section notes.', '2013-03-04 12:30:36'),
(12, 50, 'Contract additions. Special section notes.', '2012-12-22 12:30:36'),
(13, 51, 'Contract additions. Special section notes.', '2013-05-31 12:30:36'),
(14, 52, 'System integration - jumpstart proposal', '2013-05-03 12:30:36'),
(15, 53, 'Contract additions. Special section notes.', '2013-01-21 12:30:36'),
(16, 54, 'Contract additions. Special section notes.', '2013-01-01 12:30:36'),
(17, 55, 'E-mail: Re: Product changes.', '2013-04-02 12:30:37'),
(18, 56, 'Contract additions. Special section notes.', '2013-06-04 12:30:37'),
(19, 57, 'Contract additions. Special section notes.', '2013-02-15 12:30:37'),
(20, 58, 'This account is heating up!', '2013-06-25 12:30:46'),
(21, 59, 'Why is this customer having so many problems. Sigh', '2013-06-25 12:30:46'),
(22, 60, 'Bam. Closed another deal!', '2013-06-25 12:30:46'),
(23, 79, 'dsfsf', '2016-01-06 12:26:00'),
(24, 82, 'sadfasdf', '2016-01-07 03:48:00'),
(25, 83, 'asdfasfs', '2016-01-07 03:47:00');

-- --------------------------------------------------------

--
-- Table structure for table `note_read`
--

CREATE TABLE IF NOT EXISTS `note_read` (
  `securableitem_id` int(11) unsigned NOT NULL,
  `munge_id` varchar(12) COLLATE utf8_unicode_ci NOT NULL,
  `count` int(8) unsigned NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

--
-- Dumping data for table `note_read`
--

INSERT INTO `note_read` (`securableitem_id`, `munge_id`, `count`) VALUES
(163, 'R2', 1),
(164, 'R2', 1),
(165, 'R2', 1),
(166, 'R2', 1),
(167, 'R2', 1),
(168, 'R2', 1),
(169, 'R2', 1),
(170, 'R2', 1),
(171, 'R2', 1),
(172, 'R2', 1),
(173, 'R2', 1),
(174, 'R2', 1),
(175, 'R2', 1),
(176, 'R2', 1),
(177, 'R2', 1),
(178, 'R2', 1),
(179, 'R2', 1),
(180, 'R2', 1),
(261, 'R2', 1),
(307, 'G3', 1),
(310, 'G3', 1),
(311, 'G3', 1);

-- --------------------------------------------------------

--
-- Table structure for table `notification`
--

CREATE TABLE IF NOT EXISTS `notification` (
`id` int(11) unsigned NOT NULL,
  `item_id` int(11) unsigned DEFAULT NULL,
  `notificationmessage_id` int(11) unsigned DEFAULT NULL,
  `type` varchar(64) COLLATE utf8_unicode_ci DEFAULT NULL,
  `ownerhasreadlatest` tinyint(1) unsigned DEFAULT NULL,
  `owner__user_id` int(11) unsigned DEFAULT NULL
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

--
-- Dumping data for table `notification`
--

INSERT INTO `notification` (`id`, `item_id`, `notificationmessage_id`, `type`, `ownerhasreadlatest`, `owner__user_id`) VALUES
(2, 53, 2, 'RemoveApiTestEntryScriptFile', NULL, 1),
(3, 556, 3, 'ClearAssetsFolder', NULL, 1);

-- --------------------------------------------------------

--
-- Table structure for table `notificationmessage`
--

CREATE TABLE IF NOT EXISTS `notificationmessage` (
`id` int(11) unsigned NOT NULL,
  `item_id` int(11) unsigned DEFAULT NULL,
  `htmlcontent` text COLLATE utf8_unicode_ci,
  `textcontent` text COLLATE utf8_unicode_ci
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

--
-- Dumping data for table `notificationmessage`
--

INSERT INTO `notificationmessage` (`id`, `item_id`, `htmlcontent`, `textcontent`) VALUES
(2, 54, NULL, 'If this website is in production mode, please remove the app/test.php file.'),
(3, 557, NULL, 'Please delete all files from assets folder on server.');

-- --------------------------------------------------------

--
-- Table structure for table `notificationsubscriber`
--

CREATE TABLE IF NOT EXISTS `notificationsubscriber` (
`id` int(11) unsigned NOT NULL,
  `hasreadlatest` tinyint(1) unsigned DEFAULT NULL,
  `person_item_id` int(11) unsigned DEFAULT NULL,
  `task_id` int(11) unsigned DEFAULT NULL
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

--
-- Dumping data for table `notificationsubscriber`
--

INSERT INTO `notificationsubscriber` (`id`, `hasreadlatest`, `person_item_id`, `task_id`) VALUES
(1, 1, 1, 20),
(2, 1, 1, 21);

-- --------------------------------------------------------

--
-- Table structure for table `opportunity`
--

CREATE TABLE IF NOT EXISTS `opportunity` (
`id` int(11) unsigned NOT NULL,
  `closedate` date DEFAULT NULL,
  `description` text COLLATE utf8_unicode_ci,
  `name` varchar(64) COLLATE utf8_unicode_ci DEFAULT NULL,
  `probability` tinyint(11) DEFAULT NULL,
  `ownedsecurableitem_id` int(11) unsigned DEFAULT NULL,
  `stage_customfield_id` int(11) unsigned DEFAULT NULL,
  `source_customfield_id` int(11) unsigned DEFAULT NULL,
  `account_id` int(11) unsigned DEFAULT NULL,
  `amount_currencyvalue_id` int(11) unsigned DEFAULT NULL,
  `bulkservprcscstm_multiplevaluescustomfield_id` int(11) unsigned DEFAULT NULL,
  `proposedinfccstm` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `contractlengcstm_customfield_id` int(11) unsigned DEFAULT NULL,
  `vidpricingcscstm_currencyvalue_id` int(11) unsigned DEFAULT NULL,
  `alarmbulkcstcstm_currencyvalue_id` int(11) unsigned DEFAULT NULL,
  `internetbulkcstm_currencyvalue_id` int(11) unsigned DEFAULT NULL,
  `phonebulkcstcstm_currencyvalue_id` int(11) unsigned DEFAULT NULL,
  `totalbulkpricstm_currencyvalue_id` int(11) unsigned DEFAULT NULL,
  `tprmonrecstm_currencyvalue_id` int(11) unsigned DEFAULT NULL,
  `consrequestccstm_customfield_id` int(11) unsigned DEFAULT NULL,
  `constructcoscstm_currencyvalue_id` int(11) unsigned DEFAULT NULL,
  `totalcostprccstm_currencyvalue_id` int(11) unsigned DEFAULT NULL,
  `rampupcstm_customfield_id` int(11) unsigned DEFAULT NULL
) ENGINE=InnoDB AUTO_INCREMENT=80 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

--
-- Dumping data for table `opportunity`
--

INSERT INTO `opportunity` (`id`, `closedate`, `description`, `name`, `probability`, `ownedsecurableitem_id`, `stage_customfield_id`, `source_customfield_id`, `account_id`, `amount_currencyvalue_id`, `bulkservprcscstm_multiplevaluescustomfield_id`, `proposedinfccstm`, `contractlengcstm_customfield_id`, `vidpricingcscstm_currencyvalue_id`, `alarmbulkcstcstm_currencyvalue_id`, `internetbulkcstm_currencyvalue_id`, `phonebulkcstcstm_currencyvalue_id`, `totalbulkpricstm_currencyvalue_id`, `tprmonrecstm_currencyvalue_id`, `consrequestccstm_customfield_id`, `constructcoscstm_currencyvalue_id`, `totalcostprccstm_currencyvalue_id`, `rampupcstm_customfield_id`) VALUES
(22, '2015-12-31', NULL, '3360 Condo', 0, 392, 334, NULL, 35, 276, 7, '', 335, 269, 272, 270, 271, 273, 274, 336, 275, NULL, 456),
(23, '2015-03-31', NULL, '400 Association (Data)', 0, 393, 337, NULL, 24, 278, 8, '', 453, 568, 571, 569, 570, 572, 277, 454, 573, NULL, 455),
(24, '2020-01-01', NULL, '9 Island (Net)', 0, 394, 338, NULL, 45, 280, 9, '', 526, 580, 583, 581, 582, 584, 279, 527, 585, NULL, 528),
(25, '2020-01-01', NULL, 'Alexander Hotel/Condo', 0, 395, 339, NULL, 62, 282, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 281, NULL, NULL, NULL, NULL),
(26, '2020-01-01', NULL, 'Artesia', 0, 396, 340, NULL, 48, 284, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 283, NULL, NULL, NULL, NULL),
(27, '2014-09-30', NULL, 'Aventi', 0, 397, 341, NULL, 22, 286, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 285, NULL, NULL, NULL, NULL),
(28, '2020-01-01', NULL, 'Balmoral Condo', 0, 398, 342, NULL, 47, 288, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 287, NULL, NULL, NULL, NULL),
(29, '2020-01-01', NULL, 'Bravura 1 Condo', 0, 399, 343, NULL, 66, 290, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 289, NULL, NULL, NULL, NULL),
(30, '2015-09-30', NULL, 'Christopher House', 0, 400, 344, NULL, 39, 292, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 291, NULL, NULL, NULL, NULL),
(31, '2020-01-01', NULL, 'Cloisters (Net)', 0, 401, 345, NULL, 34, 294, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 293, NULL, NULL, NULL, NULL),
(32, '2020-01-01', NULL, 'Commodore Club South', 0, 402, 346, NULL, 68, 296, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 295, NULL, NULL, NULL, NULL),
(33, '2020-01-01', NULL, 'Commodore Plaza', 0, 403, 347, NULL, 59, 298, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 297, NULL, NULL, NULL, NULL),
(34, '2013-06-30', NULL, 'Cypress Trails', 0, 404, 348, NULL, 17, 300, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 299, NULL, NULL, NULL, 517),
(35, '2020-01-01', NULL, 'East Pointe Towers', 0, 405, 349, NULL, 65, 302, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 301, NULL, NULL, NULL, NULL),
(36, '2015-03-31', NULL, 'Emerald (Net)', 0, 406, 350, NULL, 33, 304, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 303, NULL, NULL, NULL, NULL),
(37, '2020-01-01', NULL, 'Fairways of Tamarac', 0, 407, 351, NULL, 60, 306, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 305, NULL, NULL, NULL, NULL),
(38, '2014-09-30', NULL, 'Garden Estates (Net)', 0, 408, 352, NULL, 21, 308, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 307, NULL, NULL, NULL, 518),
(39, '2020-01-01', NULL, 'Glades Country Club (Net)', 0, 409, 353, NULL, 44, 310, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 309, NULL, NULL, NULL, NULL),
(40, '2020-01-01', NULL, 'Harbour House', 0, 410, 354, NULL, 42, 312, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 311, NULL, NULL, NULL, NULL),
(41, '2020-01-01', NULL, 'Hillsboro Cove', 0, 411, 355, NULL, 70, 314, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 313, NULL, NULL, NULL, NULL),
(42, '2013-09-30', NULL, 'Isles at Grand Bay', 0, 412, 356, NULL, 18, 316, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 315, NULL, NULL, NULL, 519),
(43, '2015-06-30', NULL, 'Kenilworth (Net)', 0, 413, 357, NULL, 23, 318, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 317, NULL, NULL, NULL, NULL),
(44, '2014-03-31', NULL, 'Key Largo', 0, 414, 358, NULL, 20, 320, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 319, NULL, NULL, NULL, 520),
(45, '2020-01-01', NULL, 'Lake Worth Towers', 0, 415, 359, NULL, 36, 322, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 321, NULL, NULL, NULL, NULL),
(46, '2020-01-01', NULL, 'Lakes of Savannah', 0, 416, 360, NULL, 64, 324, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 323, NULL, NULL, NULL, NULL),
(47, '2020-01-01', NULL, 'Las Verdes', 0, 417, 361, NULL, 63, 326, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 325, NULL, NULL, NULL, NULL),
(48, '2015-03-31', NULL, 'Marina Village (Net)', 0, 418, 362, NULL, 25, 328, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 327, NULL, NULL, NULL, NULL),
(49, '2020-01-01', NULL, 'Mayfair House Condo', 0, 419, 363, NULL, 49, 330, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 329, NULL, NULL, NULL, NULL),
(50, '2015-03-31', NULL, 'Meadowbrook # 4', 0, 420, 364, NULL, 29, 332, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 331, NULL, NULL, NULL, NULL),
(51, '2020-01-01', NULL, 'Midtown Doral', 0, 421, 365, NULL, 27, 334, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 333, NULL, NULL, NULL, 521),
(52, '2020-01-01', NULL, 'Midtown Retail', 0, 422, 366, NULL, 28, 336, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 335, NULL, NULL, NULL, 522),
(53, '2020-01-01', NULL, 'Mystic Point', 0, 423, 367, NULL, 43, 338, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 337, NULL, NULL, NULL, NULL),
(54, '2020-01-01', NULL, 'Nirvana Condos', 0, 424, 368, NULL, 58, 340, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 339, NULL, NULL, NULL, NULL),
(55, '2015-06-30', NULL, 'Northern Star (Net)', 0, 425, 369, NULL, 32, 342, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 341, NULL, NULL, NULL, NULL),
(56, '2020-01-01', NULL, 'OakBridge', 0, 426, 370, NULL, 54, 344, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 343, NULL, NULL, NULL, NULL),
(57, '2020-01-01', NULL, 'Ocean Place', 0, 427, 371, NULL, 52, 346, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 345, NULL, NULL, NULL, NULL),
(58, '2020-01-01', NULL, 'Oceanfront Plaza', 0, 428, 372, NULL, 69, 348, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 347, NULL, NULL, NULL, NULL),
(59, '2020-01-01', NULL, 'OceanView Place', 0, 429, 373, NULL, 50, 350, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 349, NULL, NULL, NULL, NULL),
(60, '2020-01-01', NULL, 'Parker Plaza', 0, 430, 374, NULL, 30, 352, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 351, NULL, NULL, NULL, NULL),
(61, '2020-01-01', NULL, 'Patrician of the Palm Beaches', 0, 431, 375, NULL, 61, 354, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 353, NULL, NULL, NULL, NULL),
(62, '2020-01-01', NULL, 'Pine Ridge Condo', 0, 432, 376, NULL, 38, 356, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 355, NULL, NULL, NULL, NULL),
(63, '2015-12-31', NULL, 'Pinehurst Club (Net)', 0, 433, 377, NULL, 41, 358, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 357, NULL, NULL, NULL, NULL),
(64, '2020-01-01', NULL, 'Plaza of Bal Harbour', 0, 434, 378, NULL, 57, 360, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 359, NULL, NULL, NULL, NULL),
(65, '2020-01-01', NULL, 'Point East Condo', 0, 435, 379, NULL, 37, 362, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 361, NULL, NULL, NULL, NULL),
(66, '2020-01-01', NULL, 'River Bridge', 0, 436, 380, NULL, 51, 364, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 363, NULL, NULL, NULL, NULL),
(67, '2020-01-01', NULL, 'Sand Pebble Beach Condominiums', 0, 437, 381, NULL, 55, 366, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 365, NULL, NULL, NULL, NULL),
(68, '2015-09-30', NULL, 'Seamark (Net)', 0, 438, 382, NULL, 46, 368, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 367, NULL, NULL, NULL, NULL),
(69, '2014-03-31', NULL, 'Strada 315 (Data)', 0, 439, 383, NULL, 13, 370, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 369, NULL, NULL, NULL, NULL),
(70, '2014-03-31', NULL, 'Strada 315 (Video)', 0, 440, 384, NULL, 13, 372, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 371, NULL, NULL, NULL, NULL),
(71, '2014-06-30', NULL, 'Sunset Bay (Data)', 0, 441, 385, NULL, 15, 374, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 373, NULL, NULL, NULL, NULL),
(72, '2014-06-30', NULL, 'Sunset Bay (Video)', 0, 442, 386, NULL, 15, 376, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 375, NULL, NULL, NULL, NULL),
(73, '2020-01-01', NULL, 'The Atriums', 0, 443, 387, NULL, 56, 378, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 377, NULL, NULL, NULL, NULL),
(74, '2020-01-01', NULL, 'The Residences on Hollywood Beach Proposal (Net)', 0, 444, 388, NULL, 40, 380, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 379, NULL, NULL, NULL, NULL),
(75, '2013-09-30', NULL, 'The Summit (Net)', 0, 445, 389, NULL, 19, 382, NULL, '', 514, 574, 577, 575, 576, 578, 381, 515, 579, NULL, 516),
(76, '2020-01-01', NULL, 'The Tides @ Bridgeside Square', 0, 446, 390, NULL, 53, 384, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 383, NULL, NULL, NULL, NULL),
(77, '2015-03-31', NULL, 'Topaz North', 0, 447, 391, NULL, 31, 386, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 385, NULL, NULL, NULL, NULL),
(78, '2020-01-01', NULL, 'TOWERS OF KENDAL LAKES', 0, 448, 392, NULL, 67, 388, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 387, NULL, NULL, NULL, NULL),
(79, '2015-03-31', NULL, 'Tropic Harbor', 0, 449, 393, NULL, 26, 390, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 389, NULL, NULL, NULL, NULL);

-- --------------------------------------------------------

--
-- Table structure for table `opportunitystarred`
--

CREATE TABLE IF NOT EXISTS `opportunitystarred` (
`id` int(11) unsigned NOT NULL,
  `basestarredmodel_id` int(11) unsigned DEFAULT NULL,
  `opportunity_id` int(11) unsigned DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `opportunity_project`
--

CREATE TABLE IF NOT EXISTS `opportunity_project` (
`id` int(11) unsigned NOT NULL,
  `opportunity_id` int(11) unsigned DEFAULT NULL,
  `project_id` int(11) unsigned DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `opportunity_read`
--

CREATE TABLE IF NOT EXISTS `opportunity_read` (
  `securableitem_id` int(11) unsigned NOT NULL,
  `munge_id` varchar(12) COLLATE utf8_unicode_ci NOT NULL,
  `count` int(8) unsigned NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

--
-- Dumping data for table `opportunity_read`
--

INSERT INTO `opportunity_read` (`securableitem_id`, `munge_id`, `count`) VALUES
(393, 'G3', 1);

-- --------------------------------------------------------

--
-- Table structure for table `ownedsecurableitem`
--

CREATE TABLE IF NOT EXISTS `ownedsecurableitem` (
`id` int(11) unsigned NOT NULL,
  `securableitem_id` int(11) unsigned DEFAULT NULL,
  `owner__user_id` int(11) unsigned DEFAULT NULL
) ENGINE=InnoDB AUTO_INCREMENT=510 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

--
-- Dumping data for table `ownedsecurableitem`
--

INSERT INTO `ownedsecurableitem` (`id`, `securableitem_id`, `owner__user_id`) VALUES
(26, 27, 4),
(27, 28, 6),
(28, 29, 3),
(29, 30, 7),
(30, 31, 7),
(31, 32, 9),
(32, 33, 9),
(33, 34, 6),
(34, 35, 7),
(35, 36, 7),
(36, 37, 8),
(37, 38, 7),
(38, 39, 5),
(39, 40, 6),
(40, 41, 7),
(41, 42, 8),
(42, 43, 9),
(43, 44, 7),
(44, 45, 7),
(45, 46, 9),
(46, 47, 9),
(47, 48, 6),
(48, 49, 9),
(49, 50, 7),
(50, 51, 7),
(51, 52, 7),
(52, 53, 9),
(53, 54, 6),
(54, 55, 7),
(55, 56, 5),
(56, 57, 9),
(57, 58, 6),
(58, 59, 5),
(59, 60, 7),
(60, 61, 7),
(61, 62, 1),
(62, 63, 1),
(63, 64, 1),
(64, 65, 1),
(65, 66, 1),
(66, 67, 1),
(67, 68, 1),
(68, 69, 1),
(69, 70, 1),
(70, 71, 1),
(71, 72, 8),
(72, 73, 9),
(73, 74, 6),
(74, 75, 5),
(75, 76, 7),
(76, 77, 6),
(77, 78, 7),
(78, 79, 9),
(79, 80, 7),
(80, 81, 6),
(81, 82, 8),
(82, 83, 7),
(83, 84, 7),
(84, 85, 7),
(85, 86, 9),
(86, 87, 9),
(87, 88, 6),
(88, 89, 5),
(89, 90, 5),
(90, 91, 5),
(91, 92, 6),
(92, 93, 3),
(93, 94, 7),
(94, 95, 7),
(95, 96, 8),
(96, 97, 7),
(97, 98, 3),
(98, 99, 8),
(99, 100, 9),
(100, 101, 6),
(101, 102, 7),
(102, 103, 8),
(103, 104, 7),
(104, 105, 8),
(105, 106, 10),
(106, 107, 8),
(107, 108, 8),
(108, 109, 10),
(109, 110, 6),
(122, 123, 6),
(123, 124, 6),
(124, 125, 9),
(125, 126, 5),
(126, 127, 5),
(127, 128, 6),
(128, 129, 5),
(129, 130, 5),
(130, 131, 5),
(131, 132, 7),
(132, 133, 7),
(133, 134, 7),
(134, 135, 5),
(135, 136, 7),
(136, 137, 9),
(137, 138, 6),
(138, 139, 6),
(139, 140, 7),
(140, 141, 7),
(141, 142, 7),
(142, 143, 9),
(143, 144, 8),
(144, 145, 8),
(145, 146, 5),
(146, 147, 5),
(147, 148, 7),
(148, 149, 6),
(149, 150, 7),
(150, 151, 9),
(151, 152, 5),
(152, 153, 5),
(153, 154, 8),
(154, 155, 8),
(155, 156, 7),
(156, 157, 9),
(157, 158, 5),
(158, 159, 5),
(159, 160, 4),
(160, 161, 6),
(161, 162, 4),
(162, 163, 5),
(163, 164, 7),
(164, 165, 6),
(165, 166, 9),
(166, 167, 5),
(167, 168, 8),
(168, 169, 8),
(169, 170, 7),
(170, 171, 6),
(171, 172, 6),
(172, 173, 5),
(173, 174, 7),
(174, 175, 7),
(175, 176, 8),
(176, 177, 5),
(177, 178, 7),
(178, 179, 7),
(179, 180, 7),
(180, 181, 1),
(181, 182, 1),
(182, 183, 1),
(183, 184, 1),
(184, 185, 1),
(185, 186, 7),
(186, 187, 7),
(187, 188, 10),
(188, 189, 6),
(189, 190, 5),
(190, 191, 4),
(191, 192, 10),
(192, 193, 9),
(193, 194, 9),
(194, 195, 7),
(195, 196, 10),
(196, 197, 8),
(197, 198, 4),
(198, 199, 4),
(199, 200, 4),
(200, 201, 6),
(201, 202, 6),
(202, 203, 8),
(203, 204, 3),
(204, 205, 8),
(205, 206, 5),
(206, 207, 9),
(207, 208, 3),
(208, 209, 7),
(209, 210, 5),
(210, 211, 6),
(211, 212, 9),
(212, 213, 6),
(213, 214, 6),
(214, 215, 9),
(215, 216, 7),
(216, 217, 3),
(217, 218, 4),
(218, 219, 3),
(219, 220, 6),
(220, 221, 3),
(221, 222, 5),
(222, 223, 5),
(223, 224, 7),
(224, 225, 9),
(225, 226, 8),
(226, 227, 3),
(227, 228, 8),
(228, 229, 4),
(229, 230, 7),
(230, 231, 7),
(231, 232, 9),
(232, 233, 10),
(233, 234, 3),
(234, 235, 8),
(235, 236, 7),
(236, 237, 5),
(237, 238, 6),
(238, 239, 3),
(239, 240, 4),
(240, 241, 9),
(241, 242, 4),
(242, 243, 5),
(243, 244, 6),
(244, 245, 9),
(245, 246, 4),
(246, 247, 6),
(247, 248, 3),
(248, 249, 5),
(249, 250, 3),
(250, 251, 3),
(251, 252, 8),
(252, 253, 6),
(253, 254, 10),
(254, 255, 9),
(255, 256, 5),
(256, 257, 9),
(257, 258, 3),
(258, 259, 3),
(259, 260, 3),
(260, 261, 6),
(261, 262, 6),
(262, 263, 6),
(263, 264, 10),
(264, 265, 6),
(265, 266, 7),
(266, 267, 7),
(267, 268, 7),
(268, 269, 5),
(269, 270, 6),
(270, 271, 9),
(271, 272, 8),
(272, 273, 8),
(273, 274, 6),
(274, 275, 6),
(275, 276, 5),
(276, 277, 5),
(277, 278, 7),
(278, 279, 7),
(279, 280, 6),
(280, 281, 6),
(281, 282, 6),
(282, 283, 9),
(283, 284, 8),
(284, 285, 3),
(285, 286, 9),
(286, 287, 7),
(287, 288, 8),
(288, 289, 8),
(289, 290, 8),
(290, 291, 3),
(291, 292, 1),
(292, 293, 1),
(293, 294, 1),
(294, 295, 1),
(295, 296, 1),
(296, 297, 1),
(297, 298, 1),
(298, 299, 1),
(299, 300, 1),
(300, 301, 1),
(301, 302, 1),
(302, 303, 1),
(303, 304, 1),
(304, 305, 1),
(305, 306, 1),
(306, 307, 1),
(307, 308, 1),
(308, 309, 1),
(309, 310, 1),
(310, 311, 1),
(311, 312, 1),
(312, 313, 1),
(313, 314, 1),
(315, 316, 1),
(328, 329, 1),
(334, 335, 1),
(336, 337, 1),
(338, 339, 1),
(339, 340, 1),
(340, 341, 1),
(341, 342, 1),
(342, 343, 1),
(343, 344, 1),
(344, 345, 1),
(345, 346, 1),
(346, 347, 1),
(347, 348, 1),
(348, 349, 1),
(349, 350, 1),
(350, 351, 1),
(351, 352, 1),
(352, 353, 1),
(353, 354, 1),
(354, 355, 1),
(355, 356, 1),
(356, 357, 1),
(357, 358, 1),
(358, 359, 1),
(359, 360, 1),
(360, 361, 1),
(361, 362, 1),
(362, 363, 1),
(363, 364, 1),
(364, 365, 1),
(365, 366, 1),
(366, 367, 1),
(367, 368, 1),
(368, 369, 1),
(369, 370, 1),
(370, 371, 1),
(371, 372, 1),
(372, 373, 1),
(373, 374, 1),
(374, 375, 1),
(375, 376, 1),
(376, 377, 1),
(377, 378, 1),
(378, 379, 1),
(379, 380, 1),
(380, 381, 1),
(381, 382, 1),
(382, 383, 1),
(383, 384, 1),
(384, 385, 1),
(385, 386, 1),
(386, 387, 1),
(387, 388, 1),
(388, 389, 1),
(389, 390, 1),
(390, 391, 1),
(391, 392, 1),
(392, 393, 1),
(393, 394, 1),
(394, 395, 1),
(395, 396, 1),
(396, 397, 1),
(397, 398, 1),
(398, 399, 1),
(399, 400, 1),
(400, 401, 1),
(401, 402, 1),
(402, 403, 1),
(403, 404, 1),
(404, 405, 1),
(405, 406, 1),
(406, 407, 1),
(407, 408, 1),
(408, 409, 1),
(409, 410, 1),
(410, 411, 1),
(411, 412, 1),
(412, 413, 1),
(413, 414, 1),
(414, 415, 1),
(415, 416, 1),
(416, 417, 1),
(417, 418, 1),
(418, 419, 1),
(419, 420, 1),
(420, 421, 1),
(421, 422, 1),
(422, 423, 1),
(423, 424, 1),
(424, 425, 1),
(425, 426, 1),
(426, 427, 1),
(427, 428, 1),
(428, 429, 1),
(429, 430, 1),
(430, 431, 1),
(431, 432, 1),
(432, 433, 1),
(433, 434, 1),
(434, 435, 1),
(435, 436, 1),
(436, 437, 1),
(437, 438, 1),
(438, 439, 1),
(439, 440, 1),
(440, 441, 1),
(441, 442, 1),
(442, 443, 1),
(443, 444, 1),
(444, 445, 1),
(445, 446, 1),
(446, 447, 1),
(447, 448, 1),
(448, 449, 1),
(449, 450, 1),
(450, 451, 1),
(451, 452, 1),
(452, 453, 1),
(453, 454, 1),
(454, 455, 1),
(455, 456, 1),
(456, 457, 1),
(457, 458, 1),
(458, 459, 1),
(459, 460, 1),
(460, 461, 1),
(461, 462, 1),
(462, 463, 1),
(463, 464, 1),
(464, 465, 1),
(465, 466, 1),
(466, 467, 1),
(467, 468, 1),
(468, 469, 1),
(469, 470, 1),
(470, 471, 1),
(471, 472, 1),
(472, 473, 1),
(473, 474, 1),
(474, 475, 1),
(475, 476, 1),
(476, 477, 1),
(477, 478, 1),
(478, 479, 1),
(479, 480, 1),
(480, 481, 1),
(481, 482, 1),
(482, 483, 1),
(483, 484, 1),
(484, 485, 1),
(485, 486, 1),
(486, 487, 1),
(487, 488, 1),
(488, 489, 1),
(489, 490, 1),
(490, 491, 1),
(491, 492, 1),
(492, 493, 1),
(493, 494, 1),
(494, 495, 1),
(495, 496, 1),
(496, 497, 1),
(497, 498, 1),
(498, 499, 1),
(499, 500, 1),
(500, 501, 1),
(501, 502, 1),
(502, 503, 1),
(503, 504, 1),
(504, 505, 1),
(505, 506, 1),
(506, 507, 1),
(507, 508, 1),
(508, 509, 1),
(509, 510, 1);

-- --------------------------------------------------------

--
-- Table structure for table `permission`
--

CREATE TABLE IF NOT EXISTS `permission` (
`id` int(11) unsigned NOT NULL,
  `permitable_id` int(11) unsigned DEFAULT NULL,
  `securableitem_id` int(11) unsigned DEFAULT NULL,
  `permissions` tinyint(11) DEFAULT NULL,
  `type` tinyint(11) DEFAULT NULL
) ENGINE=InnoDB AUTO_INCREMENT=142 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

--
-- Dumping data for table `permission`
--

INSERT INTO `permission` (`id`, `permitable_id`, `securableitem_id`, `permissions`, `type`) VALUES
(2, 5, 27, 27, 1),
(3, 5, 28, 27, 1),
(4, 5, 29, 27, 1),
(5, 5, 30, 27, 1),
(6, 5, 31, 27, 1),
(7, 5, 44, 27, 1),
(8, 5, 45, 27, 1),
(9, 5, 46, 27, 1),
(10, 5, 47, 27, 1),
(11, 5, 48, 27, 1),
(12, 5, 49, 27, 1),
(13, 5, 50, 27, 1),
(14, 5, 51, 27, 1),
(15, 5, 52, 27, 1),
(16, 5, 53, 27, 1),
(17, 5, 54, 27, 1),
(18, 5, 55, 27, 1),
(19, 5, 56, 27, 1),
(20, 5, 57, 27, 1),
(21, 5, 58, 27, 1),
(22, 5, 59, 27, 1),
(23, 5, 60, 27, 1),
(24, 5, 61, 27, 1),
(25, 5, 62, 27, 1),
(26, 5, 63, 27, 1),
(27, 5, 64, 27, 1),
(28, 5, 65, 27, 1),
(29, 5, 66, 27, 1),
(30, 5, 67, 27, 1),
(31, 5, 68, 27, 1),
(32, 5, 69, 27, 1),
(33, 5, 70, 27, 1),
(34, 5, 71, 27, 1),
(35, 5, 72, 27, 1),
(36, 5, 73, 27, 1),
(37, 5, 74, 27, 1),
(38, 5, 75, 27, 1),
(39, 5, 76, 27, 1),
(40, 5, 77, 27, 1),
(41, 5, 78, 27, 1),
(42, 5, 79, 27, 1),
(43, 5, 80, 27, 1),
(44, 5, 81, 27, 1),
(45, 5, 82, 27, 1),
(46, 5, 83, 27, 1),
(47, 5, 84, 27, 1),
(48, 5, 85, 27, 1),
(49, 5, 86, 27, 1),
(50, 5, 87, 27, 1),
(51, 5, 88, 27, 1),
(52, 5, 89, 27, 1),
(53, 13, 90, 27, 1),
(54, 18, 90, 27, 1),
(55, 1, 90, 27, 1),
(56, 18, 91, 27, 1),
(57, 16, 91, 27, 1),
(58, 12, 91, 27, 1),
(59, 1, 91, 27, 1),
(60, 16, 92, 27, 1),
(61, 12, 92, 27, 1),
(62, 18, 92, 27, 1),
(63, 13, 92, 27, 1),
(64, 1, 92, 27, 1),
(65, 5, 93, 27, 1),
(66, 5, 94, 27, 1),
(67, 5, 95, 27, 1),
(68, 5, 96, 27, 1),
(69, 5, 97, 27, 1),
(70, 5, 98, 27, 1),
(71, 5, 159, 3, 1),
(72, 5, 160, 3, 1),
(73, 5, 161, 3, 1),
(74, 5, 162, 3, 1),
(75, 5, 181, 27, 1),
(76, 5, 182, 27, 1),
(77, 5, 183, 27, 1),
(78, 5, 184, 27, 1),
(79, 5, 185, 27, 1),
(80, 5, 245, 27, 1),
(81, 5, 246, 27, 1),
(82, 5, 247, 27, 1),
(83, 5, 248, 27, 1),
(84, 5, 249, 27, 1),
(85, 5, 251, 27, 1),
(86, 5, 252, 27, 1),
(87, 5, 253, 27, 1),
(88, 5, 254, 27, 1),
(89, 5, 255, 27, 1),
(90, 5, 256, 27, 1),
(91, 5, 257, 27, 1),
(92, 5, 258, 27, 1),
(93, 5, 260, 27, 1),
(94, 5, 262, 27, 1),
(95, 5, 263, 27, 1),
(96, 5, 264, 27, 1),
(97, 5, 283, 27, 1),
(98, 5, 284, 27, 1),
(99, 5, 285, 27, 1),
(100, 5, 286, 27, 1),
(101, 5, 287, 27, 1),
(102, 5, 292, 27, 1),
(103, 5, 293, 27, 1),
(104, 5, 294, 27, 1),
(105, 5, 295, 27, 1),
(106, 5, 296, 27, 1),
(107, 5, 297, 27, 1),
(108, 5, 299, 27, 1),
(109, 5, 300, 27, 1),
(110, 5, 301, 27, 1),
(111, 5, 302, 27, 1),
(112, 5, 303, 27, 1),
(113, 5, 306, 27, 1),
(114, 5, 307, 27, 1),
(115, 5, 308, 27, 1),
(116, 5, 309, 27, 1),
(117, 5, 310, 27, 1),
(118, 5, 311, 27, 1),
(119, 5, 312, 27, 1),
(121, 5, 316, 27, 1),
(134, 5, 329, 27, 1),
(140, 5, 393, 27, 1),
(141, 5, 510, 27, 1);

-- --------------------------------------------------------

--
-- Table structure for table `permitable`
--

CREATE TABLE IF NOT EXISTS `permitable` (
`id` int(11) unsigned NOT NULL,
  `item_id` int(11) unsigned DEFAULT NULL
) ENGINE=InnoDB AUTO_INCREMENT=21 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

--
-- Dumping data for table `permitable`
--

INSERT INTO `permitable` (`id`, `item_id`) VALUES
(1, 1),
(2, 2),
(5, 52),
(6, 55),
(7, 56),
(8, 57),
(9, 58),
(10, 59),
(11, 60),
(12, 64),
(13, 65),
(14, 66),
(15, 67),
(16, 68),
(17, 69),
(18, 70),
(19, 71),
(20, 562);

-- --------------------------------------------------------

--
-- Table structure for table `person`
--

CREATE TABLE IF NOT EXISTS `person` (
`id` int(11) unsigned NOT NULL,
  `department` varchar(64) COLLATE utf8_unicode_ci DEFAULT NULL,
  `firstname` varchar(32) COLLATE utf8_unicode_ci DEFAULT NULL,
  `jobtitle` varchar(64) COLLATE utf8_unicode_ci DEFAULT NULL,
  `lastname` varchar(32) COLLATE utf8_unicode_ci DEFAULT NULL,
  `mobilephone` varchar(24) COLLATE utf8_unicode_ci DEFAULT NULL,
  `officephone` varchar(24) COLLATE utf8_unicode_ci DEFAULT NULL,
  `officefax` varchar(24) COLLATE utf8_unicode_ci DEFAULT NULL,
  `title_customfield_id` int(11) unsigned DEFAULT NULL,
  `primaryemail_email_id` int(11) unsigned DEFAULT NULL,
  `ownedsecurableitem_id` int(11) unsigned DEFAULT NULL,
  `primaryaddress_address_id` int(11) unsigned DEFAULT NULL
) ENGINE=InnoDB AUTO_INCREMENT=43 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

--
-- Dumping data for table `person`
--

INSERT INTO `person` (`id`, `department`, `firstname`, `jobtitle`, `lastname`, `mobilephone`, `officephone`, `officefax`, `title_customfield_id`, `primaryemail_email_id`, `ownedsecurableitem_id`, `primaryaddress_address_id`) VALUES
(1, NULL, 'Super', NULL, 'User', NULL, NULL, NULL, NULL, 2, NULL, NULL),
(4, 'Sales', 'Jason', 'Sales Director', 'Blue', '714-865-1145', '761-508-1335', '252-780-4534', 2, 3, NULL, 2),
(5, 'Information Technology', 'Jim', 'Vice President', 'Smith', '795-691-1482', '383-243-3111', '429-353-4540', 3, 4, NULL, 3),
(6, 'Sales', 'John', 'Vice President', 'Smith', '874-690-7821', '540-857-4006', '787-385-9970', 4, 5, NULL, 4),
(7, 'Sales', 'Sally', 'Vice President', 'Smith', '396-259-8851', '549-210-2348', '338-283-2412', 5, 6, NULL, 5),
(8, 'Sales', 'Mary', 'Vice President', 'Smith', '270-560-5344', '429-432-2541', '654-246-9082', 6, 7, NULL, 6),
(9, 'Sales', 'Katie', 'Sales Director', 'Smith', '479-644-6178', '538-767-8634', '706-542-3585', 7, 8, NULL, 7),
(10, 'Information Technology', 'Jill', 'IT Director', 'Smith', '515-208-7698', '554-864-6039', '595-865-6781', 8, 9, NULL, 8),
(11, 'Sales', 'Sam', 'Sales Manager', 'Smith', '767-538-3394', '435-371-8652', '506-646-2834', 9, 10, NULL, 9),
(12, 'Sales', 'Jose', 'Vice President', 'Robinson', '765-662-5544', '278-384-8422', '862-580-6670', 22, 17, 31, 16),
(13, 'Information Technology', 'Kirby', 'Vice President', 'Davis', '521-398-1785', '706-610-8791', '807-275-1547', 25, 18, 32, 17),
(14, 'Information Technology', 'Laura', 'Vice President', 'Miller', '573-343-1395', '855-308-4001', '442-332-7204', 28, 19, 33, 18),
(15, 'Information Technology', 'Walter', 'IT Director', 'Williams', '805-684-3356', '320-389-8265', '539-388-5599', 31, 20, 34, 19),
(16, 'Information Technology', 'Alice', 'Vice President', 'Martin', '538-589-8948', '554-306-3464', '388-824-5069', 34, 21, 35, 20),
(17, 'Information Technology', 'Jeffrey', 'IT Manager', 'Lee', '568-722-6573', '203-598-2100', '736-272-1716', 37, 22, 36, 21),
(18, 'Sales', 'Maya', 'Vice President', 'Wilson', '626-813-7287', '434-570-3804', '692-365-9763', 40, 23, 37, 22),
(19, 'Information Technology', 'Kirby', 'IT Manager', 'Johnson', '801-515-3147', '620-813-9467', '476-738-9346', 43, 24, 38, 23),
(20, 'Sales', 'Sarah', 'Sales Manager', 'Harris', '569-691-3791', '508-784-5821', '598-344-4270', 46, 25, 39, 24),
(21, 'Sales', 'Sarah', 'Sales Manager', 'Harris', '248-504-7319', '514-217-4297', '760-342-8164', 49, 26, 40, 25),
(22, 'Information Technology', 'Ester', 'IT Director', 'Taylor', '415-560-9383', '498-772-3839', '682-619-6768', 52, 27, 41, 26),
(23, 'Sales', 'Jake', 'Sales Manager', 'Williams', '214-251-2176', '397-628-5037', '810-371-6552', 55, 28, 42, 27),
(24, 'Information Technology', 'Kirby', 'IT Director', 'Williams', '401-343-2551', '500-737-8375', '715-519-7840', 58, 29, 98, 28),
(25, 'Sales', 'Ray', 'Vice President', 'Harris', '460-553-2931', '311-802-8576', '283-635-4262', 61, 30, 99, 29),
(26, 'Information Technology', 'Sophie', 'Vice President', 'Rodriguez', '563-629-3794', '270-281-5963', '823-742-6439', 64, 31, 100, 30),
(27, 'Information Technology', 'Nev', 'IT Director', 'Lee', '326-684-7292', '367-645-9588', '351-490-2070', 67, 32, 101, 31),
(28, 'Information Technology', 'Kirby', 'IT Manager', 'Lee', '850-379-7272', '457-248-4119', '372-779-5218', 70, 33, 102, 32),
(29, 'Sales', 'Jeffrey', 'Vice President', 'Clark', '362-466-7482', '637-234-9553', '623-385-3339', 73, 34, 103, 33),
(30, 'Sales', 'Lisa', 'Sales Manager', 'Johnson', '532-404-4408', '707-890-2911', '581-853-1118', 76, 35, 104, 34),
(31, 'Information Technology', 'Ray', 'IT Director', 'Robinson', '358-370-5810', '595-812-3831', '755-765-7631', 79, 36, 105, 35),
(32, 'Information Technology', 'Jake', 'IT Director', 'Lewis', '704-562-4414', '661-744-9379', '269-484-7547', 82, 37, 106, 36),
(33, 'Sales', 'Alice', 'Vice President', 'Walker', '670-457-3552', '784-784-7031', '643-745-6554', 85, 38, 107, 37),
(34, 'Information Technology', 'Jose', 'IT Manager', 'Hall', '716-417-4741', '772-254-6007', '735-596-4838', 88, 39, 108, 38),
(35, 'Sales', 'Ray', 'Sales Manager', 'Martinez', '591-535-7835', '722-799-1730', '532-675-1437', 91, 40, 109, 39),
(36, NULL, 'Alice', 'Sales Manager', 'Brown', NULL, NULL, NULL, NULL, NULL, 287, NULL),
(37, NULL, 'Jim', 'Sales Director', 'Smith', NULL, NULL, NULL, NULL, NULL, 288, NULL),
(38, NULL, 'Keith', 'IT Manager', 'Cooper', NULL, NULL, NULL, NULL, NULL, 289, NULL),
(39, NULL, 'Sarah', 'Vice President', 'Lee', NULL, NULL, NULL, NULL, NULL, 290, NULL),
(40, NULL, 'System', NULL, 'User', NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(41, '', 'ewrw', '', 'werw', '', '', '', 225, 41, 305, 40),
(42, 'HOA', 'Eric', 'President of Board', 'Riveron', '', '305-555-5555', '', 262, 43, 328, 47);

-- --------------------------------------------------------

--
-- Table structure for table `personwhohavenotreadlatest`
--

CREATE TABLE IF NOT EXISTS `personwhohavenotreadlatest` (
`id` int(11) unsigned NOT NULL,
  `person_item_id` int(11) unsigned DEFAULT NULL,
  `mission_id` int(11) unsigned DEFAULT NULL
) ENGINE=InnoDB AUTO_INCREMENT=39 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

--
-- Dumping data for table `personwhohavenotreadlatest`
--

INSERT INTO `personwhohavenotreadlatest` (`id`, `person_item_id`, `mission_id`) VALUES
(3, 64, 2),
(4, 70, 2),
(5, 65, 2),
(6, 69, 2),
(7, 68, 2),
(8, 67, 2),
(9, 71, 2),
(10, 1, 2),
(11, 66, 2),
(12, 64, 3),
(13, 70, 3),
(14, 66, 3),
(15, 69, 3),
(16, 68, 3),
(17, 67, 3),
(18, 71, 3),
(19, 1, 3),
(20, 65, 3),
(21, 64, 4),
(22, 70, 4),
(23, 65, 4),
(24, 66, 4),
(25, 69, 4),
(26, 68, 4),
(27, 71, 4),
(28, 1, 4),
(29, 67, 4),
(30, 64, 5),
(31, 70, 5),
(32, 66, 5),
(33, 69, 5),
(34, 68, 5),
(35, 67, 5),
(36, 71, 5),
(37, 1, 5),
(38, 65, 5);

-- --------------------------------------------------------

--
-- Table structure for table `perusermetadata`
--

CREATE TABLE IF NOT EXISTS `perusermetadata` (
`id` int(11) unsigned NOT NULL,
  `_user_id` int(11) unsigned DEFAULT NULL,
  `classname` varchar(64) COLLATE utf8_unicode_ci DEFAULT NULL,
  `serializedmetadata` text COLLATE utf8_unicode_ci
) ENGINE=InnoDB AUTO_INCREMENT=13 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

--
-- Dumping data for table `perusermetadata`
--

INSERT INTO `perusermetadata` (`id`, `_user_id`, `classname`, `serializedmetadata`) VALUES
(2, 1, 'ZurmoModule', 'a:3:{s:25:"turnOffEmailNotifications";b:1;s:14:"recentlyViewed";s:825:"a:11:{i:0;a:3:{i:0;s:15:"ContractsModule";i:1;i:14;i:2;s:23:"3360 Condo-New Contract";}i:1;a:3:{i:0;s:19:"OpportunitiesModule";i:1;i:24;i:2;s:14:"9 Island (Net)";}i:2;a:3:{i:0;s:11:"UsersModule";i:1;i:1;i:2;s:10:"Super User";}i:3;a:3:{i:0;s:19:"OpportunitiesModule";i:1;i:22;i:2;s:10:"3360 Condo";}i:4;a:3:{i:0;s:19:"OpportunitiesModule";i:1;i:23;i:2;s:22:"400 Association (Data)";}i:5;a:3:{i:0;s:14:"AccountsModule";i:1;i:35;i:2;s:10:"3360 Condo";}i:6;a:3:{i:0;s:14:"AccountsModule";i:1;i:71;i:2;s:3:"JEM";}i:7;a:3:{i:0;s:19:"OpportunitiesModule";i:1;i:33;i:2;s:15:"Commodore Plaza";}i:8;a:3:{i:0;s:19:"OpportunitiesModule";i:1;i:32;i:2;s:20:"Commodore Club South";}i:9;a:3:{i:0;s:19:"OpportunitiesModule";i:1;i:31;i:2;s:15:"Cloisters (Net)";}i:10;a:3:{i:0;s:19:"OpportunitiesModule";i:1;i:30;i:2;s:17:"Christopher House";}}";s:31:"SecurityIntroView-intro-content";b:1;}'),
(3, 3, 'ZurmoModule', 'a:1:{s:25:"turnOffEmailNotifications";b:1;}'),
(4, 4, 'ZurmoModule', 'a:1:{s:25:"turnOffEmailNotifications";b:1;}'),
(5, 5, 'ZurmoModule', 'a:1:{s:25:"turnOffEmailNotifications";b:1;}'),
(6, 6, 'ZurmoModule', 'a:1:{s:25:"turnOffEmailNotifications";b:1;}'),
(7, 7, 'ZurmoModule', 'a:1:{s:25:"turnOffEmailNotifications";b:1;}'),
(8, 8, 'ZurmoModule', 'a:1:{s:25:"turnOffEmailNotifications";b:1;}'),
(9, 9, 'ZurmoModule', 'a:1:{s:25:"turnOffEmailNotifications";b:1;}'),
(10, 10, 'ZurmoModule', 'a:1:{s:25:"turnOffEmailNotifications";b:1;}'),
(11, 1, 'UsersModule', 'a:1:{s:17:"timeZoneConfirmed";b:1;}'),
(12, 1, 'CalendarsModule', 'a:4:{s:20:"myCalendarSelections";s:3:"1,2";s:23:"myCalendarDateRangeType";s:5:"month";s:19:"myCalendarStartDate";s:10:"2016-01-01";s:17:"myCalendarEndDate";s:10:"2016-02-01";}');

-- --------------------------------------------------------

--
-- Table structure for table `policy`
--

CREATE TABLE IF NOT EXISTS `policy` (
`id` int(11) unsigned NOT NULL,
  `permitable_id` int(11) unsigned DEFAULT NULL,
  `modulename` varchar(64) COLLATE utf8_unicode_ci DEFAULT NULL,
  `name` varchar(64) COLLATE utf8_unicode_ci DEFAULT NULL,
  `value` varchar(64) COLLATE utf8_unicode_ci DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `portlet`
--

CREATE TABLE IF NOT EXISTS `portlet` (
`id` int(11) unsigned NOT NULL,
  `_user_id` int(11) unsigned DEFAULT NULL,
  `layoutid` varchar(100) COLLATE utf8_unicode_ci DEFAULT NULL,
  `viewtype` text COLLATE utf8_unicode_ci,
  `serializedviewdata` text COLLATE utf8_unicode_ci,
  `collapsed` tinyint(1) unsigned DEFAULT NULL,
  `column` int(11) DEFAULT NULL,
  `position` int(11) DEFAULT NULL
) ENGINE=InnoDB AUTO_INCREMENT=52 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

--
-- Dumping data for table `portlet`
--

INSERT INTO `portlet` (`id`, `_user_id`, `layoutid`, `viewtype`, `serializedviewdata`, `collapsed`, `column`, `position`) VALUES
(1, 1, 'ContractDetailsAndRelationsView', 'ContractDetailsPortlet', NULL, 0, 1, 1),
(2, 1, 'ContractDetailsAndRelationsView', 'NoteInlineEditForPortlet', NULL, 0, 1, 2),
(3, 1, 'ContractDetailsAndRelationsView', 'ContractLatestActivitiesForPortlet', NULL, 0, 1, 3),
(4, 1, 'ContractDetailsAndRelationsView', 'UpcomingMeetingsForContractCalendar', NULL, 0, 2, 1),
(5, 1, 'ContractDetailsAndRelationsView', 'OpenTasksForContractRelatedList', NULL, 0, 2, 2),
(6, 1, 'ContractDetailsAndRelationsView', 'ContactsForContractRelatedList', NULL, 0, 2, 3),
(7, 1, 'OpportunityDetailsAndRelationsView', 'OpportunityDetailsPortlet', NULL, 0, 1, 1),
(8, 1, 'OpportunityDetailsAndRelationsView', 'NoteInlineEditForPortlet', NULL, 0, 1, 2),
(9, 1, 'OpportunityDetailsAndRelationsView', 'OpportunityLatestActivitiesForPortlet', NULL, 0, 1, 3),
(10, 1, 'OpportunityDetailsAndRelationsView', 'UpcomingMeetingsForOpportunityCalendar', NULL, 0, 2, 1),
(11, 1, 'OpportunityDetailsAndRelationsView', 'OpenTasksForOpportunityRelatedList', NULL, 0, 2, 2),
(12, 1, 'OpportunityDetailsAndRelationsView', 'ContactsForOpportunityRelatedList', NULL, 0, 2, 3),
(13, 1, 'UserDetailsAndRelationsViewLeftBottomView', 'UserSocialItemsForPortlet', NULL, 0, 1, 1),
(15, 3, 'ContractDetailsAndRelationsView', 'ContractDetailsPortlet', NULL, 0, 1, 1),
(16, 3, 'ContractDetailsAndRelationsView', 'NoteInlineEditForPortlet', NULL, 0, 1, 2),
(17, 3, 'ContractDetailsAndRelationsView', 'ContractLatestActivitiesForPortlet', NULL, 0, 1, 3),
(18, 3, 'ContractDetailsAndRelationsView', 'UpcomingMeetingsForContractCalendar', NULL, 0, 2, 2),
(19, 3, 'ContractDetailsAndRelationsView', 'OpenTasksForContractRelatedList', NULL, 0, 2, 3),
(20, 3, 'ContractDetailsAndRelationsView', 'ContactsForContractRelatedList', NULL, 0, 2, 4),
(21, 3, 'ContractDetailsAndRelationsView', 'UpcomingMeetingsForContractList', NULL, 0, 2, 1),
(22, 1, 'HomeDashboard1', 'MyUpcomingMeetingsCalendar', NULL, 0, 1, 1),
(23, 1, 'HomeDashboard1', 'AllLatestActivitiesForPortlet', NULL, 0, 1, 2),
(24, 1, 'HomeDashboard1', 'TasksMyList', NULL, 0, 1, 3),
(25, 1, 'HomeDashboard1', 'OpportunitiesBySourceChart', NULL, 0, 1, 4),
(26, 1, 'HomeDashboard1', 'AllSocialItemsForPortlet', NULL, 0, 2, 1),
(27, 1, 'HomeDashboard1', 'MyMissionsForPortlet', NULL, 0, 2, 2),
(28, 1, 'HomeDashboard1', 'OpportunitiesByStageChart', NULL, 0, 2, 3),
(29, 1, 'AccountDetailsAndRelationsView', 'AccountDetailsPortlet', NULL, 0, 1, 1),
(30, 1, 'AccountDetailsAndRelationsView', 'NoteInlineEditForPortlet', NULL, 0, 1, 2),
(31, 1, 'AccountDetailsAndRelationsView', 'AccountLatestActivitiesForPortlet', NULL, 0, 1, 3),
(32, 1, 'AccountDetailsAndRelationsView', 'UpcomingMeetingsForAccountCalendar', NULL, 0, 2, 1),
(33, 1, 'AccountDetailsAndRelationsView', 'OpenTasksForAccountRelatedList', NULL, 0, 2, 2),
(34, 1, 'AccountDetailsAndRelationsView', 'ContactsForAccountRelatedList', NULL, 0, 2, 3),
(35, 1, 'AccountDetailsAndRelationsView', 'OpportunitiesForAccountRelatedList', NULL, 0, 2, 4),
(37, 1, 'OpportunityDetailsAndRelationsView', 'ContractsForOpportunityRelatedList', NULL, 0, 2, 4),
(38, 1, 'RowsAndColumnsReportDetailsAndResultsViewLeftBottomView', 'RuntimeFiltersForPortlet', NULL, 0, 1, 1),
(39, 1, 'RowsAndColumnsReportDetailsAndResultsViewLeftBottomView', 'ReportResultsGridForPortlet', NULL, 0, 1, 2),
(40, 1, 'RowsAndColumnsReportDetailsAndResultsViewLeftBottomView', 'ReportSQLForPortlet', NULL, 0, 1, 3),
(41, 1, 'MarketingDashboard', 'MarketingOverallMetrics', NULL, 0, 1, 1),
(42, 1, 'MarketingListDetailsAndRelationsViewLeftBottomView', 'MarketingListMembersPortlet', NULL, 0, 1, 1),
(43, 1, 'MarketingListDetailsAndRelationsViewLeftBottomView', 'AutorespondersPortlet', NULL, 0, 1, 2),
(44, 1, 'MarketingListDetailsAndRelationsViewLeftBottomView', 'CampaignsForMarketingListRelatedList', NULL, 0, 1, 3),
(45, 1, 'MarketingListDetailsAndRelationsViewLeftBottomView', 'MarketingListOverallMetrics', NULL, 0, 1, 4),
(46, 1, 'CampaignDetailsAndRelationsViewLeftBottomView', 'CampaignOverallMetrics', NULL, 0, 1, 1),
(47, 1, 'CampaignDetailsAndRelationsViewLeftBottomView', 'CampaignItemsRelatedList', NULL, 0, 1, 2),
(48, 1, 'SummationReportDetailsAndResultsViewLeftBottomView', 'RuntimeFiltersForPortlet', NULL, 0, 1, 1),
(49, 1, 'SummationReportDetailsAndResultsViewLeftBottomView', 'ReportChartForPortlet', NULL, 0, 1, 2),
(50, 1, 'SummationReportDetailsAndResultsViewLeftBottomView', 'ReportResultsGridForPortlet', NULL, 0, 1, 3),
(51, 1, 'SummationReportDetailsAndResultsViewLeftBottomView', 'ReportSQLForPortlet', NULL, 0, 1, 4);

-- --------------------------------------------------------

--
-- Table structure for table `product`
--

CREATE TABLE IF NOT EXISTS `product` (
`id` int(11) unsigned NOT NULL,
  `ownedsecurableitem_id` int(11) unsigned DEFAULT NULL,
  `stage_customfield_id` int(11) unsigned DEFAULT NULL,
  `sellprice_currencyvalue_id` int(11) unsigned DEFAULT NULL,
  `account_id` int(11) unsigned DEFAULT NULL,
  `contact_id` int(11) unsigned DEFAULT NULL,
  `name` varchar(64) COLLATE utf8_unicode_ci DEFAULT NULL,
  `description` text COLLATE utf8_unicode_ci,
  `quantity` int(11) DEFAULT NULL,
  `pricefrequency` int(11) DEFAULT NULL,
  `type` int(11) DEFAULT NULL,
  `opportunity_id` int(11) unsigned DEFAULT NULL,
  `producttemplate_id` int(11) unsigned DEFAULT NULL
) ENGINE=InnoDB AUTO_INCREMENT=61 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

--
-- Dumping data for table `product`
--

INSERT INTO `product` (`id`, `ownedsecurableitem_id`, `stage_customfield_id`, `sellprice_currencyvalue_id`, `account_id`, `contact_id`, `name`, `description`, `quantity`, `pricefrequency`, `type`, `opportunity_id`, `producttemplate_id`) VALUES
(2, 185, 154, 110, 7, 9, 'Amazing Kid Sample', NULL, 60, 2, 1, 3, 2),
(3, 186, 155, 111, 6, 3, 'You Can Do Anything Sample', NULL, 18, 2, 1, 9, 3),
(4, 187, 156, 112, 5, 11, 'A Bend in the River November Issue', NULL, 95, 2, 1, 6, 4),
(5, 188, 157, 113, 3, 4, 'A Gift of Monotheists October Issue', NULL, 79, 2, 1, 5, 5),
(6, 189, 158, 114, 4, 2, 'Enjoy Once in a Lifetime Music', NULL, 4, 2, 1, 6, 6),
(7, 190, 159, 115, 3, 8, 'Laptop Inc - Model LsntjG-PFp', NULL, 11, 2, 1, 6, 7),
(8, 191, 160, 116, 4, 2, 'Laptop Inc - Model LsntjG-PQs', NULL, 18, 2, 1, 13, 7),
(9, 192, 161, 117, 6, 5, 'Laptop Inc - Model Ps9gyD-PdD', NULL, 53, 2, 1, 4, 8),
(10, 193, 162, 118, 4, 12, 'Laptop Inc - Model Ps9gyD-P1f', NULL, 18, 2, 1, 10, 8),
(11, 194, 163, 119, 6, 10, 'Laptop Inc - Model nYmDt9-PTc', NULL, 58, 2, 1, 12, 9),
(12, 195, 164, 120, 5, 4, 'Laptop Inc - Model nYmDt9-PhS', NULL, 93, 2, 1, 9, 9),
(13, 196, 165, 121, 7, 8, 'Laptop Inc - Model eOKsFD-P1S', NULL, 17, 2, 1, 6, 10),
(14, 197, 166, 122, 7, 12, 'Laptop Inc - Model eOKsFD-Pfq', NULL, 54, 2, 1, 7, 10),
(15, 198, 167, 123, 3, 10, 'Laptop Inc - Model btOJRS-PPp', NULL, 90, 2, 1, 13, 11),
(16, 199, 168, 124, 3, 9, 'Laptop Inc - Model btOJRS-PUm', NULL, 31, 2, 1, 9, 11),
(17, 200, 169, 125, 6, 11, 'Laptop Inc - Model kr1JfZ-PV3', NULL, 32, 2, 1, 4, 12),
(18, 201, 170, 126, 3, 8, 'Laptop Inc - Model kr1JfZ-Pyg', NULL, 83, 2, 1, 9, 12),
(19, 202, 171, 127, 6, 6, 'Laptop Inc - Model ktRhOn-PDw', NULL, 51, 2, 1, 2, 13),
(20, 203, 172, 128, 7, 9, 'Laptop Inc - Model ktRhOn-PBT', NULL, 53, 2, 1, 11, 13),
(21, 204, 173, 129, 3, 13, 'Laptop Inc - Model xAwe35-Pk0', NULL, 12, 2, 1, 5, 14),
(22, 205, 174, 130, 7, 2, 'Laptop Inc - Model xAwe35-Pwp', NULL, 89, 2, 1, 13, 14),
(23, 206, 175, 131, 4, 6, 'Laptop Inc - Model JcXZwA-PF2', NULL, 28, 2, 1, 7, 15),
(24, 207, 176, 132, 7, 9, 'Laptop Inc - Model JcXZwA-PW5', NULL, 4, 2, 1, 10, 15),
(25, 208, 177, 133, 4, 13, 'Camera Inc 2 MegaPixel - Model RIHmYF-PxS', NULL, 34, 2, 1, 8, 16),
(26, 209, 178, 134, 3, 8, 'Camera Inc 2 MegaPixel - Model RIHmYF-PI2', NULL, 55, 2, 1, 10, 16),
(27, 210, 179, 135, 3, 9, 'Camera Inc 2 MegaPixel - Model M9JqrI-Pkl', NULL, 27, 2, 1, 6, 17),
(28, 211, 180, 136, 2, 13, 'Camera Inc 2 MegaPixel - Model M9JqrI-P3O', NULL, 46, 2, 1, 8, 17),
(29, 212, 181, 137, 7, 8, 'Camera Inc 2 MegaPixel - Model R9FmDg-PrE', NULL, 73, 2, 1, 3, 18),
(30, 213, 182, 138, 4, 10, 'Camera Inc 2 MegaPixel - Model R9FmDg-P3M', NULL, 60, 2, 1, 10, 18),
(31, 214, 183, 139, 7, 6, 'Camera Inc 2 MegaPixel - Model dKJCNi-Ppx', NULL, 26, 2, 1, 4, 19),
(32, 215, 184, 140, 3, 7, 'Camera Inc 2 MegaPixel - Model dKJCNi-PWO', NULL, 5, 2, 1, 11, 19),
(33, 216, 185, 141, 5, 9, 'Camera Inc 2 MegaPixel - Model jxQeLq-P97', NULL, 67, 2, 1, 3, 20),
(34, 217, 186, 142, 7, 6, 'Camera Inc 2 MegaPixel - Model jxQeLq-PTM', NULL, 1, 2, 1, 8, 20),
(35, 218, 187, 143, 2, 9, 'Camera Inc 2 MegaPixel - Model l4wupF-Pjv', NULL, 27, 2, 1, 8, 21),
(36, 219, 188, 144, 3, 6, 'Camera Inc 2 MegaPixel - Model l4wupF-PoW', NULL, 21, 2, 1, 5, 21),
(37, 220, 189, 145, 7, 10, 'Camera Inc 2 MegaPixel - Model 6IfjV3-Pm7', NULL, 32, 2, 1, 7, 22),
(38, 221, 190, 146, 4, 13, 'Camera Inc 2 MegaPixel - Model 6IfjV3-PY3', NULL, 38, 2, 1, 8, 22),
(39, 222, 191, 147, 4, 5, 'Camera Inc 2 MegaPixel - Model JCZFLB-POf', NULL, 72, 2, 1, 13, 23),
(40, 223, 192, 148, 6, 3, 'Camera Inc 2 MegaPixel - Model JCZFLB-PQu', NULL, 81, 2, 1, 5, 23),
(41, 224, 193, 149, 7, 2, 'Camera Inc 2 MegaPixel - Model u0ziKO-PI4', NULL, 93, 2, 1, 13, 24),
(42, 225, 194, 150, 2, 12, 'Camera Inc 2 MegaPixel - Model u0ziKO-PNn', NULL, 58, 2, 1, 7, 24),
(43, 226, 195, 151, 7, 12, 'Handycam Inc - Model DrUPcM-PmS', NULL, 64, 2, 1, 9, 25),
(44, 227, 196, 152, 4, 9, 'Handycam Inc - Model DrUPcM-PXO', NULL, 94, 2, 1, 6, 25),
(45, 228, 197, 153, 6, 9, 'Handycam Inc - Model D4I5CU-PdE', NULL, 71, 2, 1, 7, 26),
(46, 229, 198, 154, 2, 9, 'Handycam Inc - Model D4I5CU-P7m', NULL, 82, 2, 1, 7, 26),
(47, 230, 199, 155, 2, 12, 'Handycam Inc - Model jMStmA-P0y', NULL, 9, 2, 1, 2, 27),
(48, 231, 200, 156, 7, 3, 'Handycam Inc - Model jMStmA-PbJ', NULL, 34, 2, 1, 3, 27),
(49, 232, 201, 157, 4, 12, 'Handycam Inc - Model nErS4b-P8u', NULL, 94, 2, 1, 3, 28),
(50, 233, 202, 158, 2, 4, 'Handycam Inc - Model nErS4b-PtP', NULL, 47, 2, 1, 2, 28),
(51, 234, 203, 159, 7, 13, 'Handycam Inc - Model N5WdJi-PZQ', NULL, 13, 2, 1, 5, 29),
(52, 235, 204, 160, 5, 12, 'Handycam Inc - Model N5WdJi-Pyl', NULL, 90, 2, 1, 10, 29),
(53, 236, 205, 161, 7, 9, 'Handycam Inc - Model lCfm76-PWB', NULL, 4, 2, 1, 12, 30),
(54, 237, 206, 162, 7, 5, 'Handycam Inc - Model lCfm76-PgK', NULL, 15, 2, 1, 13, 30),
(55, 238, 207, 163, 2, 5, 'Handycam Inc - Model 68e3Ms-PWH', NULL, 36, 2, 1, 10, 31),
(56, 239, 208, 164, 3, 7, 'Handycam Inc - Model 68e3Ms-Pph', NULL, 74, 2, 1, 11, 31),
(57, 240, 209, 165, 3, 5, 'Handycam Inc - Model jIo9N7-PZG', NULL, 50, 2, 1, 7, 32),
(58, 241, 210, 166, 3, 9, 'Handycam Inc - Model jIo9N7-PaW', NULL, 30, 2, 1, 5, 32),
(59, 242, 211, 167, 4, 2, 'Handycam Inc - Model Pn1TQx-Pmj', NULL, 67, 2, 1, 6, 33),
(60, 243, 212, 168, 7, 2, 'Handycam Inc - Model Pn1TQx-Pew', NULL, 89, 2, 1, 8, 33);

-- --------------------------------------------------------

--
-- Table structure for table `productcatalog`
--

CREATE TABLE IF NOT EXISTS `productcatalog` (
`id` int(11) unsigned NOT NULL,
  `name` varchar(64) COLLATE utf8_unicode_ci DEFAULT NULL,
  `item_id` int(11) unsigned DEFAULT NULL
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

--
-- Dumping data for table `productcatalog`
--

INSERT INTO `productcatalog` (`id`, `name`, `item_id`) VALUES
(2, 'Default', 382);

-- --------------------------------------------------------

--
-- Table structure for table `productcatalog_productcategory`
--

CREATE TABLE IF NOT EXISTS `productcatalog_productcategory` (
`id` int(11) unsigned NOT NULL,
  `productcategory_id` int(11) unsigned DEFAULT NULL,
  `productcatalog_id` int(11) unsigned DEFAULT NULL
) ENGINE=InnoDB AUTO_INCREMENT=9 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

--
-- Dumping data for table `productcatalog_productcategory`
--

INSERT INTO `productcatalog_productcategory` (`id`, `productcategory_id`, `productcatalog_id`) VALUES
(3, 2, 2),
(4, 3, 2),
(5, 4, 2),
(6, 5, 2),
(7, 6, 2),
(8, 7, 2);

-- --------------------------------------------------------

--
-- Table structure for table `productcategory`
--

CREATE TABLE IF NOT EXISTS `productcategory` (
`id` int(11) unsigned NOT NULL,
  `name` varchar(64) COLLATE utf8_unicode_ci DEFAULT NULL,
  `item_id` int(11) unsigned DEFAULT NULL,
  `productcategory_id` int(11) unsigned DEFAULT NULL
) ENGINE=InnoDB AUTO_INCREMENT=8 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

--
-- Dumping data for table `productcategory`
--

INSERT INTO `productcategory` (`id`, `name`, `item_id`, `productcategory_id`) VALUES
(2, 'CD-DVD', 383, NULL),
(3, 'Books', 384, NULL),
(4, 'Music', 385, NULL),
(5, 'Laptops', 386, NULL),
(6, 'Camera', 387, NULL),
(7, 'Handycam', 388, NULL);

-- --------------------------------------------------------

--
-- Table structure for table `productcategory_producttemplate`
--

CREATE TABLE IF NOT EXISTS `productcategory_producttemplate` (
`id` int(11) unsigned NOT NULL,
  `producttemplate_id` int(11) unsigned DEFAULT NULL,
  `productcategory_id` int(11) unsigned DEFAULT NULL
) ENGINE=InnoDB AUTO_INCREMENT=35 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

--
-- Dumping data for table `productcategory_producttemplate`
--

INSERT INTO `productcategory_producttemplate` (`id`, `producttemplate_id`, `productcategory_id`) VALUES
(3, 2, 2),
(4, 3, 2),
(5, 4, 3),
(6, 5, 3),
(7, 6, 4),
(8, 7, 5),
(9, 8, 5),
(10, 9, 5),
(11, 10, 5),
(12, 11, 5),
(13, 12, 5),
(14, 13, 5),
(15, 14, 5),
(16, 15, 5),
(17, 16, 6),
(18, 17, 6),
(19, 18, 6),
(20, 19, 6),
(21, 20, 6),
(22, 21, 6),
(23, 22, 6),
(24, 23, 6),
(25, 24, 6),
(26, 25, 7),
(27, 26, 7),
(28, 27, 7),
(29, 28, 7),
(30, 29, 7),
(31, 30, 7),
(32, 31, 7),
(33, 32, 7),
(34, 33, 7);

-- --------------------------------------------------------

--
-- Table structure for table `producttemplate`
--

CREATE TABLE IF NOT EXISTS `producttemplate` (
`id` int(11) unsigned NOT NULL,
  `item_id` int(11) unsigned DEFAULT NULL,
  `sellprice_currencyvalue_id` int(11) unsigned DEFAULT NULL,
  `cost_currencyvalue_id` int(11) unsigned DEFAULT NULL,
  `listprice_currencyvalue_id` int(11) unsigned DEFAULT NULL,
  `name` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `description` text COLLATE utf8_unicode_ci,
  `pricefrequency` int(11) DEFAULT NULL,
  `status` int(11) DEFAULT NULL,
  `type` int(11) DEFAULT NULL,
  `sellpriceformula_id` int(11) unsigned DEFAULT NULL
) ENGINE=InnoDB AUTO_INCREMENT=34 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

--
-- Dumping data for table `producttemplate`
--

INSERT INTO `producttemplate` (`id`, `item_id`, `sellprice_currencyvalue_id`, `cost_currencyvalue_id`, `listprice_currencyvalue_id`, `name`, `description`, `pricefrequency`, `status`, `type`, `sellpriceformula_id`) VALUES
(2, 389, 16, 14, 15, 'Amazing Kid', NULL, 2, 2, 1, 2),
(3, 390, 19, 17, 18, 'You Can Do Anything', NULL, 2, 2, 1, 3),
(4, 391, 22, 20, 21, 'A Bend in the River', NULL, 2, 2, 1, 4),
(5, 392, 25, 23, 24, 'A Gift of Monotheists', NULL, 2, 2, 1, 5),
(6, 393, 28, 26, 27, 'Once in a Lifetime', NULL, 2, 2, 1, 6),
(7, 394, 31, 29, 30, 'Laptop Inc - Model LsntjG', NULL, 2, 2, 1, 7),
(8, 395, 34, 32, 33, 'Laptop Inc - Model Ps9gyD', NULL, 2, 2, 1, 8),
(9, 396, 37, 35, 36, 'Laptop Inc - Model nYmDt9', NULL, 2, 2, 1, 9),
(10, 397, 40, 38, 39, 'Laptop Inc - Model eOKsFD', NULL, 2, 2, 1, 10),
(11, 398, 43, 41, 42, 'Laptop Inc - Model btOJRS', NULL, 2, 2, 1, 11),
(12, 399, 46, 44, 45, 'Laptop Inc - Model kr1JfZ', NULL, 2, 2, 1, 12),
(13, 400, 49, 47, 48, 'Laptop Inc - Model ktRhOn', NULL, 2, 2, 1, 13),
(14, 401, 52, 50, 51, 'Laptop Inc - Model xAwe35', NULL, 2, 2, 1, 14),
(15, 402, 55, 53, 54, 'Laptop Inc - Model JcXZwA', NULL, 2, 2, 1, 15),
(16, 403, 58, 56, 57, 'Camera Inc 2 MegaPixel - Model RIHmYF', NULL, 2, 2, 1, 16),
(17, 404, 61, 59, 60, 'Camera Inc 2 MegaPixel - Model M9JqrI', NULL, 2, 2, 1, 17),
(18, 405, 64, 62, 63, 'Camera Inc 2 MegaPixel - Model R9FmDg', NULL, 2, 2, 1, 18),
(19, 406, 67, 65, 66, 'Camera Inc 2 MegaPixel - Model dKJCNi', NULL, 2, 2, 1, 19),
(20, 407, 70, 68, 69, 'Camera Inc 2 MegaPixel - Model jxQeLq', NULL, 2, 2, 1, 20),
(21, 408, 73, 71, 72, 'Camera Inc 2 MegaPixel - Model l4wupF', NULL, 2, 2, 1, 21),
(22, 409, 76, 74, 75, 'Camera Inc 2 MegaPixel - Model 6IfjV3', NULL, 2, 2, 1, 22),
(23, 410, 79, 77, 78, 'Camera Inc 2 MegaPixel - Model JCZFLB', NULL, 2, 2, 1, 23),
(24, 411, 82, 80, 81, 'Camera Inc 2 MegaPixel - Model u0ziKO', NULL, 2, 2, 1, 24),
(25, 412, 85, 83, 84, 'Handycam Inc - Model DrUPcM', NULL, 2, 2, 1, 25),
(26, 413, 88, 86, 87, 'Handycam Inc - Model D4I5CU', NULL, 2, 2, 1, 26),
(27, 414, 91, 89, 90, 'Handycam Inc - Model jMStmA', NULL, 2, 2, 1, 27),
(28, 415, 94, 92, 93, 'Handycam Inc - Model nErS4b', NULL, 2, 2, 1, 28),
(29, 416, 97, 95, 96, 'Handycam Inc - Model N5WdJi', NULL, 2, 2, 1, 29),
(30, 417, 100, 98, 99, 'Handycam Inc - Model lCfm76', NULL, 2, 2, 1, 30),
(31, 418, 103, 101, 102, 'Handycam Inc - Model 68e3Ms', NULL, 2, 2, 1, 31),
(32, 419, 106, 104, 105, 'Handycam Inc - Model jIo9N7', NULL, 2, 2, 1, 32),
(33, 420, 109, 107, 108, 'Handycam Inc - Model Pn1TQx', NULL, 2, 2, 1, 33);

-- --------------------------------------------------------

--
-- Table structure for table `product_productcategory`
--

CREATE TABLE IF NOT EXISTS `product_productcategory` (
`id` int(11) unsigned NOT NULL,
  `product_id` int(11) unsigned DEFAULT NULL,
  `productcategory_id` int(11) unsigned DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `product_read`
--

CREATE TABLE IF NOT EXISTS `product_read` (
  `securableitem_id` int(11) unsigned NOT NULL,
  `munge_id` varchar(12) COLLATE utf8_unicode_ci NOT NULL,
  `count` int(8) unsigned NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

--
-- Dumping data for table `product_read`
--

INSERT INTO `product_read` (`securableitem_id`, `munge_id`, `count`) VALUES
(186, 'R2', 1),
(187, 'R2', 1),
(188, 'R2', 1),
(189, 'R2', 1),
(190, 'R2', 1),
(191, 'R2', 1),
(192, 'R2', 1),
(193, 'R2', 1),
(194, 'R2', 1),
(195, 'R2', 1),
(196, 'R2', 1),
(197, 'R2', 1),
(198, 'R2', 1),
(199, 'R2', 1),
(200, 'R2', 1),
(201, 'R2', 1),
(202, 'R2', 1),
(203, 'R2', 1),
(205, 'R2', 1),
(206, 'R2', 1),
(207, 'R2', 1),
(209, 'R2', 1),
(210, 'R2', 1),
(211, 'R2', 1),
(212, 'R2', 1),
(213, 'R2', 1),
(214, 'R2', 1),
(215, 'R2', 1),
(216, 'R2', 1),
(218, 'R2', 1),
(220, 'R2', 1),
(222, 'R2', 1),
(223, 'R2', 1),
(224, 'R2', 1),
(225, 'R2', 1),
(226, 'R2', 1),
(228, 'R2', 1),
(229, 'R2', 1),
(230, 'R2', 1),
(231, 'R2', 1),
(232, 'R2', 1),
(233, 'R2', 1),
(235, 'R2', 1),
(236, 'R2', 1),
(237, 'R2', 1),
(238, 'R2', 1),
(240, 'R2', 1),
(241, 'R2', 1),
(242, 'R2', 1),
(243, 'R2', 1),
(244, 'R2', 1);

-- --------------------------------------------------------

--
-- Table structure for table `project`
--

CREATE TABLE IF NOT EXISTS `project` (
`id` int(11) unsigned NOT NULL,
  `name` varchar(64) COLLATE utf8_unicode_ci DEFAULT NULL,
  `description` text COLLATE utf8_unicode_ci,
  `status` int(11) DEFAULT NULL,
  `ownedsecurableitem_id` int(11) unsigned DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `projectauditevent`
--

CREATE TABLE IF NOT EXISTS `projectauditevent` (
`id` int(11) unsigned NOT NULL,
  `datetime` datetime DEFAULT NULL,
  `eventname` varchar(64) COLLATE utf8_unicode_ci DEFAULT NULL,
  `serializeddata` text COLLATE utf8_unicode_ci,
  `_user_id` int(11) unsigned DEFAULT NULL,
  `project_id` int(11) unsigned DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `project_read`
--

CREATE TABLE IF NOT EXISTS `project_read` (
`id` int(11) unsigned NOT NULL,
  `securableitem_id` int(11) unsigned NOT NULL,
  `munge_id` varchar(12) COLLATE utf8_unicode_ci NOT NULL,
  `count` int(8) unsigned NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `role`
--

CREATE TABLE IF NOT EXISTS `role` (
`id` int(11) unsigned NOT NULL,
  `item_id` int(11) unsigned DEFAULT NULL,
  `role_id` int(11) unsigned DEFAULT NULL,
  `name` varchar(64) COLLATE utf8_unicode_ci DEFAULT NULL
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

--
-- Dumping data for table `role`
--

INSERT INTO `role` (`id`, `item_id`, `role_id`, `name`) VALUES
(2, 61, NULL, 'Executive'),
(3, 62, 2, 'Sales Director'),
(4, 63, 3, 'Sales Manager');

-- --------------------------------------------------------

--
-- Table structure for table `savedcalendar`
--

CREATE TABLE IF NOT EXISTS `savedcalendar` (
`id` int(11) unsigned NOT NULL,
  `name` varchar(64) COLLATE utf8_unicode_ci DEFAULT NULL,
  `description` text COLLATE utf8_unicode_ci,
  `location` text COLLATE utf8_unicode_ci,
  `moduleclassname` varchar(64) COLLATE utf8_unicode_ci DEFAULT NULL,
  `startattributename` text COLLATE utf8_unicode_ci,
  `endattributename` text COLLATE utf8_unicode_ci,
  `serializeddata` text COLLATE utf8_unicode_ci,
  `timezone` varchar(64) COLLATE utf8_unicode_ci DEFAULT NULL,
  `color` varchar(64) COLLATE utf8_unicode_ci DEFAULT NULL,
  `ownedsecurableitem_id` int(11) unsigned DEFAULT NULL
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

--
-- Dumping data for table `savedcalendar`
--

INSERT INTO `savedcalendar` (`id`, `name`, `description`, `location`, `moduleclassname`, `startattributename`, `endattributename`, `serializeddata`, `timezone`, `color`, `ownedsecurableitem_id`) VALUES
(1, 'My Meetings', NULL, 'Chicago', 'MeetingsModule', 'startDateTime', 'endDateTime', 'a:2:{s:7:"Filters";a:1:{i:0;a:6:{s:27:"attributeIndexOrDerivedType";s:11:"owner__User";s:17:"structurePosition";s:1:"1";s:8:"operator";s:6:"equals";s:5:"value";i:1;s:24:"stringifiedModelForValue";s:10:"Super User";s:18:"availableAtRunTime";s:1:"0";}}s:16:"filtersStructure";s:1:"1";}', 'America/Chicago', '#315AB0', 303),
(2, 'My Tasks', NULL, 'Chicago', 'TasksModule', 'createdDateTime', '', 'a:2:{s:7:"Filters";a:1:{i:0;a:6:{s:27:"attributeIndexOrDerivedType";s:11:"owner__User";s:17:"structurePosition";s:1:"1";s:8:"operator";s:6:"equals";s:5:"value";i:1;s:24:"stringifiedModelForValue";s:10:"Super User";s:18:"availableAtRunTime";s:1:"0";}}s:16:"filtersStructure";s:1:"1";}', 'America/Chicago', '#66367b', 304);

-- --------------------------------------------------------

--
-- Table structure for table `savedcalendarsubscription`
--

CREATE TABLE IF NOT EXISTS `savedcalendarsubscription` (
`id` int(11) unsigned NOT NULL,
  `color` varchar(64) COLLATE utf8_unicode_ci DEFAULT NULL,
  `_user_id` int(11) unsigned DEFAULT NULL,
  `savedcalendar_id` int(11) unsigned DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `savedcalendar_read`
--

CREATE TABLE IF NOT EXISTS `savedcalendar_read` (
`id` int(11) unsigned NOT NULL,
  `securableitem_id` int(11) unsigned NOT NULL,
  `munge_id` varchar(12) COLLATE utf8_unicode_ci NOT NULL,
  `count` int(8) unsigned NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `savedreport`
--

CREATE TABLE IF NOT EXISTS `savedreport` (
`id` int(11) unsigned NOT NULL,
  `ownedsecurableitem_id` int(11) unsigned DEFAULT NULL,
  `description` text COLLATE utf8_unicode_ci,
  `moduleclassname` varchar(64) COLLATE utf8_unicode_ci DEFAULT NULL,
  `name` varchar(64) COLLATE utf8_unicode_ci DEFAULT NULL,
  `serializeddata` text COLLATE utf8_unicode_ci,
  `type` varchar(15) COLLATE utf8_unicode_ci DEFAULT NULL
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

--
-- Dumping data for table `savedreport`
--

INSERT INTO `savedreport` (`id`, `ownedsecurableitem_id`, `description`, `moduleclassname`, `name`, `serializeddata`, `type`) VALUES
(2, 180, 'A report showing new leads', 'ContactsModule', 'New Leads Report', 'a:8:{s:16:"filtersStructure";s:7:"1 AND 2";s:22:"currencyConversionType";i:2;s:26:"spotConversionCurrencyCode";N;s:7:"Filters";a:2:{i:0;a:8:{s:18:"availableAtRunTime";b:1;s:18:"currencyIdForValue";N;s:5:"value";N;s:11:"secondValue";N;s:24:"stringifiedModelForValue";N;s:9:"valueType";s:11:"Last 7 Days";s:27:"attributeIndexOrDerivedType";s:15:"createdDateTime";s:8:"operator";N;}i:1;a:8:{s:18:"availableAtRunTime";b:0;s:18:"currencyIdForValue";N;s:5:"value";a:4:{i:0;i:2;i:1;i:3;i:2;i:4;i:3;i:5;}s:11:"secondValue";N;s:24:"stringifiedModelForValue";N;s:9:"valueType";N;s:27:"attributeIndexOrDerivedType";s:5:"state";s:8:"operator";s:5:"oneOf";}}s:8:"OrderBys";a:0:{}s:8:"GroupBys";a:0:{}s:17:"DisplayAttributes";a:4:{i:0;a:6:{s:27:"attributeIndexOrDerivedType";s:8:"FullName";s:5:"label";s:9:"Full Name";s:15:"columnAliasName";s:4:"col0";s:9:"queryOnly";b:0;s:26:"valueUsedAsDrillDownFilter";b:0;s:30:"madeViaSelectInsteadOfViaModel";b:0;}i:1;a:6:{s:27:"attributeIndexOrDerivedType";s:6:"source";s:5:"label";s:6:"Source";s:15:"columnAliasName";s:4:"col1";s:9:"queryOnly";b:0;s:26:"valueUsedAsDrillDownFilter";b:0;s:30:"madeViaSelectInsteadOfViaModel";b:0;}i:2;a:6:{s:27:"attributeIndexOrDerivedType";s:11:"officePhone";s:5:"label";s:12:"Office Phone";s:15:"columnAliasName";s:4:"col2";s:9:"queryOnly";b:0;s:26:"valueUsedAsDrillDownFilter";b:0;s:30:"madeViaSelectInsteadOfViaModel";b:0;}i:3;a:6:{s:27:"attributeIndexOrDerivedType";s:27:"primaryEmail___emailAddress";s:5:"label";s:30:"Primary Email >> Email Address";s:15:"columnAliasName";s:4:"col3";s:9:"queryOnly";b:0;s:26:"valueUsedAsDrillDownFilter";b:0;s:30:"madeViaSelectInsteadOfViaModel";b:0;}}s:26:"DrillDownDisplayAttributes";a:0:{}}', 'RowsAndColumns'),
(3, 181, 'A report showing active customers who have not opted out of receiving emails', 'ContactsModule', 'Active Customer Email List', 'a:8:{s:16:"filtersStructure";s:13:"1 AND 2 AND 3";s:22:"currencyConversionType";i:2;s:26:"spotConversionCurrencyCode";N;s:7:"Filters";a:3:{i:0;a:8:{s:18:"availableAtRunTime";b:0;s:18:"currencyIdForValue";N;s:5:"value";s:8:"Customer";s:11:"secondValue";N;s:24:"stringifiedModelForValue";N;s:9:"valueType";N;s:27:"attributeIndexOrDerivedType";s:14:"account___type";s:8:"operator";s:6:"equals";}i:1;a:8:{s:18:"availableAtRunTime";b:0;s:18:"currencyIdForValue";N;s:5:"value";a:2:{i:0;i:6;i:1;i:7;}s:11:"secondValue";N;s:24:"stringifiedModelForValue";N;s:9:"valueType";N;s:27:"attributeIndexOrDerivedType";s:5:"state";s:8:"operator";s:5:"oneOf";}i:2;a:8:{s:18:"availableAtRunTime";b:0;s:18:"currencyIdForValue";N;s:5:"value";b:0;s:11:"secondValue";N;s:24:"stringifiedModelForValue";N;s:9:"valueType";N;s:27:"attributeIndexOrDerivedType";s:21:"primaryEmail___optOut";s:8:"operator";s:6:"equals";}}s:8:"OrderBys";a:0:{}s:8:"GroupBys";a:0:{}s:17:"DisplayAttributes";a:3:{i:0;a:6:{s:27:"attributeIndexOrDerivedType";s:8:"FullName";s:5:"label";s:9:"Full Name";s:15:"columnAliasName";s:4:"col4";s:9:"queryOnly";b:0;s:26:"valueUsedAsDrillDownFilter";b:0;s:30:"madeViaSelectInsteadOfViaModel";b:0;}i:1;a:6:{s:27:"attributeIndexOrDerivedType";s:14:"account___name";s:5:"label";s:12:"Account Name";s:15:"columnAliasName";s:4:"col5";s:9:"queryOnly";b:0;s:26:"valueUsedAsDrillDownFilter";b:0;s:30:"madeViaSelectInsteadOfViaModel";b:0;}i:2;a:6:{s:27:"attributeIndexOrDerivedType";s:27:"primaryEmail___emailAddress";s:5:"label";s:30:"Primary Email >> Email Address";s:15:"columnAliasName";s:4:"col6";s:9:"queryOnly";b:0;s:26:"valueUsedAsDrillDownFilter";b:0;s:30:"madeViaSelectInsteadOfViaModel";b:0;}}s:26:"DrillDownDisplayAttributes";a:0:{}}', 'RowsAndColumns'),
(4, 182, 'A report showing closed won opportunties by owner', 'OpportunitiesModule', 'Opportunities By Owner', 'a:9:{s:16:"filtersStructure";s:1:"1";s:22:"currencyConversionType";i:2;s:26:"spotConversionCurrencyCode";N;s:7:"Filters";a:1:{i:0;a:8:{s:18:"availableAtRunTime";b:0;s:18:"currencyIdForValue";N;s:5:"value";s:10:"Closed Won";s:11:"secondValue";N;s:24:"stringifiedModelForValue";N;s:9:"valueType";N;s:27:"attributeIndexOrDerivedType";s:5:"stage";s:8:"operator";s:6:"equals";}}s:8:"OrderBys";a:0:{}s:8:"GroupBys";a:1:{i:0;a:2:{s:4:"axis";s:1:"x";s:27:"attributeIndexOrDerivedType";s:11:"owner__User";}}s:17:"DisplayAttributes";a:3:{i:0;a:6:{s:27:"attributeIndexOrDerivedType";s:11:"owner__User";s:5:"label";s:5:"Owner";s:15:"columnAliasName";s:4:"col7";s:9:"queryOnly";b:0;s:26:"valueUsedAsDrillDownFilter";b:0;s:30:"madeViaSelectInsteadOfViaModel";b:0;}i:1;a:6:{s:27:"attributeIndexOrDerivedType";s:5:"Count";s:5:"label";s:5:"Count";s:15:"columnAliasName";s:4:"col8";s:9:"queryOnly";b:0;s:26:"valueUsedAsDrillDownFilter";b:0;s:30:"madeViaSelectInsteadOfViaModel";b:0;}i:2;a:6:{s:27:"attributeIndexOrDerivedType";s:17:"amount__Summation";s:5:"label";s:13:"Amount -(Sum)";s:15:"columnAliasName";s:4:"col9";s:9:"queryOnly";b:0;s:26:"valueUsedAsDrillDownFilter";b:0;s:30:"madeViaSelectInsteadOfViaModel";b:0;}}s:26:"DrillDownDisplayAttributes";a:4:{i:0;a:6:{s:27:"attributeIndexOrDerivedType";s:4:"name";s:5:"label";s:4:"Name";s:15:"columnAliasName";s:4:"col0";s:9:"queryOnly";b:0;s:26:"valueUsedAsDrillDownFilter";b:0;s:30:"madeViaSelectInsteadOfViaModel";b:0;}i:1;a:6:{s:27:"attributeIndexOrDerivedType";s:14:"account___name";s:5:"label";s:12:"Account Name";s:15:"columnAliasName";s:4:"col1";s:9:"queryOnly";b:0;s:26:"valueUsedAsDrillDownFilter";b:0;s:30:"madeViaSelectInsteadOfViaModel";b:0;}i:2;a:6:{s:27:"attributeIndexOrDerivedType";s:6:"amount";s:5:"label";s:6:"Amount";s:15:"columnAliasName";s:4:"col2";s:9:"queryOnly";b:0;s:26:"valueUsedAsDrillDownFilter";b:0;s:30:"madeViaSelectInsteadOfViaModel";b:0;}i:3;a:6:{s:27:"attributeIndexOrDerivedType";s:9:"closeDate";s:5:"label";s:10:"Close Date";s:15:"columnAliasName";s:4:"col3";s:9:"queryOnly";b:0;s:26:"valueUsedAsDrillDownFilter";b:0;s:30:"madeViaSelectInsteadOfViaModel";b:0;}}s:5:"chart";a:5:{s:4:"type";s:5:"Pie2D";s:11:"firstSeries";s:11:"owner__User";s:10:"firstRange";s:17:"amount__Summation";s:12:"secondSeries";N;s:11:"secondRange";N;}}', 'Summation'),
(5, 183, 'A report showing closed won opportunities by month', 'OpportunitiesModule', 'Closed won opportunities by month', 'a:9:{s:16:"filtersStructure";s:1:"1";s:22:"currencyConversionType";i:2;s:26:"spotConversionCurrencyCode";N;s:7:"Filters";a:1:{i:0;a:8:{s:18:"availableAtRunTime";b:0;s:18:"currencyIdForValue";N;s:5:"value";s:10:"Closed Won";s:11:"secondValue";N;s:24:"stringifiedModelForValue";N;s:9:"valueType";N;s:27:"attributeIndexOrDerivedType";s:5:"stage";s:8:"operator";s:6:"equals";}}s:8:"OrderBys";a:0:{}s:8:"GroupBys";a:1:{i:0;a:2:{s:4:"axis";s:1:"x";s:27:"attributeIndexOrDerivedType";s:16:"closeDate__Month";}}s:17:"DisplayAttributes";a:3:{i:0;a:6:{s:27:"attributeIndexOrDerivedType";s:16:"closeDate__Month";s:5:"label";s:19:"Close Date -(Month)";s:15:"columnAliasName";s:5:"col10";s:9:"queryOnly";b:0;s:26:"valueUsedAsDrillDownFilter";b:0;s:30:"madeViaSelectInsteadOfViaModel";b:0;}i:1;a:6:{s:27:"attributeIndexOrDerivedType";s:5:"Count";s:5:"label";s:5:"Count";s:15:"columnAliasName";s:5:"col11";s:9:"queryOnly";b:0;s:26:"valueUsedAsDrillDownFilter";b:0;s:30:"madeViaSelectInsteadOfViaModel";b:0;}i:2;a:6:{s:27:"attributeIndexOrDerivedType";s:17:"amount__Summation";s:5:"label";s:13:"Amount -(Sum)";s:15:"columnAliasName";s:5:"col12";s:9:"queryOnly";b:0;s:26:"valueUsedAsDrillDownFilter";b:0;s:30:"madeViaSelectInsteadOfViaModel";b:0;}}s:26:"DrillDownDisplayAttributes";a:0:{}s:5:"chart";a:5:{s:4:"type";s:5:"Bar2D";s:11:"firstSeries";s:16:"closeDate__Month";s:10:"firstRange";s:17:"amount__Summation";s:12:"secondSeries";N;s:11:"secondRange";N;}}', 'Summation'),
(6, 184, NULL, 'OpportunitiesModule', 'Opportunities by Stage', 'a:9:{s:16:"filtersStructure";s:0:"";s:22:"currencyConversionType";i:2;s:26:"spotConversionCurrencyCode";N;s:7:"Filters";a:0:{}s:8:"OrderBys";a:0:{}s:8:"GroupBys";a:1:{i:0;a:2:{s:4:"axis";s:1:"x";s:27:"attributeIndexOrDerivedType";s:5:"stage";}}s:17:"DisplayAttributes";a:3:{i:0;a:6:{s:27:"attributeIndexOrDerivedType";s:5:"stage";s:5:"label";s:5:"Stage";s:15:"columnAliasName";s:5:"col13";s:9:"queryOnly";b:0;s:26:"valueUsedAsDrillDownFilter";b:0;s:30:"madeViaSelectInsteadOfViaModel";b:0;}i:1;a:6:{s:27:"attributeIndexOrDerivedType";s:5:"Count";s:5:"label";s:5:"Count";s:15:"columnAliasName";s:5:"col14";s:9:"queryOnly";b:0;s:26:"valueUsedAsDrillDownFilter";b:0;s:30:"madeViaSelectInsteadOfViaModel";b:0;}i:2;a:6:{s:27:"attributeIndexOrDerivedType";s:17:"amount__Summation";s:5:"label";s:13:"Amount -(Sum)";s:15:"columnAliasName";s:5:"col15";s:9:"queryOnly";b:0;s:26:"valueUsedAsDrillDownFilter";b:0;s:30:"madeViaSelectInsteadOfViaModel";b:0;}}s:26:"DrillDownDisplayAttributes";a:0:{}s:5:"chart";a:5:{s:4:"type";s:8:"Column2D";s:11:"firstSeries";s:5:"stage";s:10:"firstRange";s:17:"amount__Summation";s:12:"secondSeries";N;s:11:"secondRange";N;}}', 'Summation');

-- --------------------------------------------------------

--
-- Table structure for table `savedreport_read`
--

CREATE TABLE IF NOT EXISTS `savedreport_read` (
  `securableitem_id` int(11) unsigned NOT NULL,
  `munge_id` varchar(12) COLLATE utf8_unicode_ci NOT NULL,
  `count` int(8) unsigned NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

--
-- Dumping data for table `savedreport_read`
--

INSERT INTO `savedreport_read` (`securableitem_id`, `munge_id`, `count`) VALUES
(181, 'G3', 1),
(182, 'G3', 1),
(183, 'G3', 1),
(184, 'G3', 1),
(185, 'G3', 1);

-- --------------------------------------------------------

--
-- Table structure for table `savedsearch`
--

CREATE TABLE IF NOT EXISTS `savedsearch` (
`id` int(11) unsigned NOT NULL,
  `ownedsecurableitem_id` int(11) unsigned DEFAULT NULL,
  `name` varchar(64) COLLATE utf8_unicode_ci DEFAULT NULL,
  `serializeddata` text COLLATE utf8_unicode_ci,
  `viewclassname` varchar(64) COLLATE utf8_unicode_ci DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `savedworkflow`
--

CREATE TABLE IF NOT EXISTS `savedworkflow` (
`id` int(11) unsigned NOT NULL,
  `item_id` int(11) unsigned DEFAULT NULL,
  `description` text COLLATE utf8_unicode_ci,
  `isactive` tinyint(1) unsigned DEFAULT NULL,
  `moduleclassname` varchar(64) COLLATE utf8_unicode_ci DEFAULT NULL,
  `name` varchar(64) COLLATE utf8_unicode_ci DEFAULT NULL,
  `serializeddata` text COLLATE utf8_unicode_ci,
  `type` varchar(15) COLLATE utf8_unicode_ci DEFAULT NULL,
  `triggeron` varchar(15) COLLATE utf8_unicode_ci DEFAULT NULL,
  `order` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `securableitem`
--

CREATE TABLE IF NOT EXISTS `securableitem` (
`id` int(11) unsigned NOT NULL,
  `item_id` int(11) unsigned DEFAULT NULL
) ENGINE=InnoDB AUTO_INCREMENT=511 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

--
-- Dumping data for table `securableitem`
--

INSERT INTO `securableitem` (`id`, `item_id`) VALUES
(27, 78),
(28, 79),
(29, 80),
(30, 81),
(31, 82),
(32, 83),
(33, 84),
(34, 85),
(35, 86),
(36, 87),
(37, 88),
(38, 89),
(39, 90),
(40, 91),
(41, 92),
(42, 93),
(43, 94),
(44, 126),
(45, 127),
(46, 128),
(47, 129),
(48, 130),
(49, 131),
(50, 132),
(51, 133),
(52, 134),
(53, 135),
(54, 136),
(55, 137),
(56, 138),
(57, 139),
(58, 140),
(59, 141),
(60, 142),
(61, 143),
(62, 144),
(63, 145),
(64, 146),
(65, 147),
(66, 148),
(67, 149),
(68, 150),
(69, 151),
(70, 152),
(71, 153),
(72, 172),
(73, 173),
(74, 174),
(75, 175),
(76, 176),
(77, 177),
(78, 178),
(79, 179),
(80, 180),
(81, 181),
(82, 182),
(83, 183),
(84, 184),
(85, 185),
(86, 186),
(87, 187),
(88, 188),
(89, 189),
(90, 190),
(91, 196),
(92, 201),
(93, 208),
(94, 209),
(95, 210),
(96, 211),
(97, 212),
(98, 213),
(99, 286),
(100, 287),
(101, 288),
(102, 289),
(103, 290),
(104, 291),
(105, 292),
(106, 293),
(107, 294),
(108, 295),
(109, 296),
(110, 297),
(123, 310),
(124, 311),
(125, 312),
(126, 313),
(127, 314),
(128, 315),
(129, 316),
(130, 317),
(131, 318),
(132, 319),
(133, 320),
(134, 321),
(135, 322),
(136, 323),
(137, 324),
(138, 325),
(139, 326),
(140, 327),
(141, 328),
(142, 329),
(143, 330),
(144, 331),
(145, 332),
(146, 333),
(147, 334),
(148, 335),
(149, 336),
(150, 337),
(151, 338),
(152, 339),
(153, 340),
(154, 341),
(155, 342),
(156, 343),
(157, 344),
(158, 345),
(159, 346),
(160, 350),
(161, 353),
(162, 356),
(163, 359),
(164, 360),
(165, 361),
(166, 362),
(167, 363),
(168, 364),
(169, 365),
(170, 366),
(171, 367),
(172, 368),
(173, 369),
(174, 370),
(175, 371),
(176, 372),
(177, 373),
(178, 374),
(179, 375),
(180, 376),
(181, 377),
(182, 378),
(183, 379),
(184, 380),
(185, 381),
(186, 421),
(187, 422),
(188, 423),
(189, 424),
(190, 425),
(191, 426),
(192, 427),
(193, 428),
(194, 429),
(195, 430),
(196, 431),
(197, 432),
(198, 433),
(199, 434),
(200, 435),
(201, 436),
(202, 437),
(203, 438),
(204, 439),
(205, 440),
(206, 441),
(207, 442),
(208, 443),
(209, 444),
(210, 445),
(211, 446),
(212, 447),
(213, 448),
(214, 449),
(215, 450),
(216, 451),
(217, 452),
(218, 453),
(219, 454),
(220, 455),
(221, 456),
(222, 457),
(223, 458),
(224, 459),
(225, 460),
(226, 461),
(227, 462),
(228, 463),
(229, 464),
(230, 465),
(231, 466),
(232, 467),
(233, 468),
(234, 469),
(235, 470),
(236, 471),
(237, 472),
(238, 473),
(239, 474),
(240, 475),
(241, 476),
(242, 477),
(243, 478),
(244, 479),
(245, 480),
(246, 481),
(247, 482),
(248, 483),
(249, 486),
(250, 491),
(251, 492),
(252, 496),
(253, 497),
(254, 498),
(255, 499),
(256, 500),
(257, 501),
(258, 502),
(259, 506),
(260, 507),
(261, 511),
(262, 512),
(263, 516),
(264, 517),
(265, 518),
(266, 519),
(267, 520),
(268, 521),
(269, 522),
(270, 523),
(271, 524),
(272, 525),
(273, 526),
(274, 527),
(275, 528),
(276, 529),
(277, 530),
(278, 531),
(279, 532),
(280, 533),
(281, 534),
(282, 535),
(283, 536),
(284, 537),
(285, 538),
(286, 539),
(287, 540),
(288, 541),
(289, 543),
(290, 546),
(291, 548),
(292, 550),
(293, 551),
(294, 552),
(295, 553),
(296, 554),
(297, 555),
(298, 563),
(299, 567),
(300, 570),
(301, 571),
(302, 572),
(303, 574),
(304, 575),
(305, 576),
(306, 577),
(307, 582),
(308, 587),
(309, 591),
(310, 596),
(311, 597),
(312, 599),
(313, 600),
(314, 610),
(316, 614),
(329, 628),
(335, 639),
(337, 641),
(339, 643),
(340, 644),
(341, 645),
(342, 646),
(343, 647),
(344, 648),
(345, 649),
(346, 650),
(347, 651),
(348, 652),
(349, 653),
(350, 654),
(351, 655),
(352, 656),
(353, 657),
(354, 658),
(355, 659),
(356, 660),
(357, 661),
(358, 662),
(359, 663),
(360, 664),
(361, 665),
(362, 666),
(363, 667),
(364, 668),
(365, 669),
(366, 670),
(367, 671),
(368, 672),
(369, 673),
(370, 674),
(371, 675),
(372, 676),
(373, 677),
(374, 678),
(375, 679),
(376, 680),
(377, 681),
(378, 682),
(379, 683),
(380, 684),
(381, 685),
(382, 686),
(383, 687),
(384, 688),
(385, 689),
(386, 690),
(387, 691),
(388, 692),
(389, 693),
(390, 694),
(391, 695),
(392, 696),
(393, 700),
(394, 702),
(395, 703),
(396, 704),
(397, 705),
(398, 706),
(399, 707),
(400, 708),
(401, 709),
(402, 710),
(403, 711),
(404, 712),
(405, 713),
(406, 714),
(407, 715),
(408, 716),
(409, 717),
(410, 718),
(411, 719),
(412, 720),
(413, 721),
(414, 722),
(415, 723),
(416, 724),
(417, 725),
(418, 726),
(419, 727),
(420, 728),
(421, 729),
(422, 730),
(423, 731),
(424, 732),
(425, 733),
(426, 734),
(427, 735),
(428, 736),
(429, 737),
(430, 738),
(431, 739),
(432, 740),
(433, 741),
(434, 742),
(435, 743),
(436, 744),
(437, 745),
(438, 746),
(439, 747),
(440, 748),
(441, 749),
(442, 750),
(443, 751),
(444, 752),
(445, 753),
(446, 754),
(447, 755),
(448, 756),
(449, 757),
(450, 758),
(451, 762),
(452, 765),
(453, 766),
(454, 767),
(455, 768),
(456, 769),
(457, 770),
(458, 771),
(459, 772),
(460, 773),
(461, 774),
(462, 775),
(463, 776),
(464, 777),
(465, 778),
(466, 779),
(467, 780),
(468, 781),
(469, 782),
(470, 783),
(471, 784),
(472, 785),
(473, 786),
(474, 787),
(475, 788),
(476, 789),
(477, 790),
(478, 791),
(479, 792),
(480, 793),
(481, 794),
(482, 795),
(483, 796),
(484, 797),
(485, 798),
(486, 799),
(487, 800),
(488, 801),
(489, 802),
(490, 803),
(491, 804),
(492, 805),
(493, 806),
(494, 807),
(495, 808),
(496, 809),
(497, 810),
(498, 811),
(499, 812),
(500, 813),
(501, 814),
(502, 815),
(503, 816),
(504, 817),
(505, 818),
(506, 819),
(507, 820),
(508, 821),
(509, 822),
(510, 831);

-- --------------------------------------------------------

--
-- Table structure for table `sellpriceformula`
--

CREATE TABLE IF NOT EXISTS `sellpriceformula` (
`id` int(11) unsigned NOT NULL,
  `producttemplate_id` int(11) unsigned DEFAULT NULL,
  `type` int(11) DEFAULT NULL,
  `discountormarkuppercentage` double DEFAULT NULL
) ENGINE=InnoDB AUTO_INCREMENT=34 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

--
-- Dumping data for table `sellpriceformula`
--

INSERT INTO `sellpriceformula` (`id`, `producttemplate_id`, `type`, `discountormarkuppercentage`) VALUES
(2, NULL, 1, NULL),
(3, NULL, 1, NULL),
(4, NULL, 1, NULL),
(5, NULL, 1, NULL),
(6, NULL, 1, NULL),
(7, NULL, 1, NULL),
(8, NULL, 1, NULL),
(9, NULL, 1, NULL),
(10, NULL, 1, NULL),
(11, NULL, 1, NULL),
(12, NULL, 1, NULL),
(13, NULL, 1, NULL),
(14, NULL, 1, NULL),
(15, NULL, 1, NULL),
(16, NULL, 1, NULL),
(17, NULL, 1, NULL),
(18, NULL, 1, NULL),
(19, NULL, 1, NULL),
(20, NULL, 1, NULL),
(21, NULL, 1, NULL),
(22, NULL, 1, NULL),
(23, NULL, 1, NULL),
(24, NULL, 1, NULL),
(25, NULL, 1, NULL),
(26, NULL, 1, NULL),
(27, NULL, 1, NULL),
(28, NULL, 1, NULL),
(29, NULL, 1, NULL),
(30, NULL, 1, NULL),
(31, NULL, 1, NULL),
(32, NULL, 1, NULL),
(33, NULL, 1, NULL);

-- --------------------------------------------------------

--
-- Table structure for table `shorturl`
--

CREATE TABLE IF NOT EXISTS `shorturl` (
`id` int(11) unsigned NOT NULL,
  `hash` varchar(10) COLLATE utf8_unicode_ci DEFAULT NULL,
  `url` text COLLATE utf8_unicode_ci,
  `createddatetime` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `socialitem`
--

CREATE TABLE IF NOT EXISTS `socialitem` (
`id` int(11) unsigned NOT NULL,
  `ownedsecurableitem_id` int(11) unsigned DEFAULT NULL,
  `description` text COLLATE utf8_unicode_ci,
  `latestdatetime` datetime DEFAULT NULL,
  `note_id` int(11) unsigned DEFAULT NULL,
  `touser__user_id` int(11) unsigned DEFAULT NULL
) ENGINE=InnoDB AUTO_INCREMENT=19 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

--
-- Dumping data for table `socialitem`
--

INSERT INTO `socialitem` (`id`, `ownedsecurableitem_id`, `description`, `latestdatetime`, `note_id`, `touser__user_id`) VALUES
(2, 244, 'Game on! I received a new badge: 5 opportunities searched', '2013-06-25 12:30:45', NULL, NULL),
(3, 245, 'Anyone interested in going to San Diego for the trade show?', '2013-06-25 12:30:45', NULL, NULL),
(4, 246, 'Game on! I received a new badge: 15 accounts created', '2013-06-25 12:30:45', NULL, NULL),
(5, 247, 'I love fridays!', '2013-06-25 12:30:45', NULL, NULL),
(6, 248, 'Golf time', '2013-06-25 12:30:46', NULL, NULL),
(7, 250, NULL, '2013-06-25 12:30:46', 20, NULL),
(8, 251, 'Game on! I reached level 4', '2013-06-25 12:30:46', NULL, NULL),
(9, 252, 'Game on! I received a new badge: Logged in 5 times at night', '2013-06-25 12:30:46', NULL, NULL),
(10, 253, 'Just stubbed my toe. Ouch!', '2013-06-25 12:30:46', NULL, NULL),
(11, 254, 'Game on! I received a new badge: For being awesome', '2013-06-25 12:30:46', NULL, NULL),
(12, 255, 'Ask Barry why we can''t use our cell phones in the conference room', '2013-06-25 12:30:46', NULL, NULL),
(13, 256, 'Game on! I reached level 2', '2013-06-25 12:30:46', NULL, NULL),
(14, 257, 'Where should we have the Christmas party?', '2013-06-25 12:30:46', NULL, NULL),
(15, 259, NULL, '2013-06-25 12:30:46', 21, NULL),
(16, 261, NULL, '2013-06-25 12:30:46', 22, NULL),
(17, 262, 'Game on! I reached level 3', '2013-06-25 12:30:46', NULL, NULL),
(18, 263, 'Game on! I reached level 5', '2013-06-25 12:30:47', NULL, NULL);

-- --------------------------------------------------------

--
-- Table structure for table `socialitem_read`
--

CREATE TABLE IF NOT EXISTS `socialitem_read` (
  `securableitem_id` int(11) unsigned NOT NULL,
  `munge_id` varchar(12) COLLATE utf8_unicode_ci NOT NULL,
  `count` int(8) unsigned NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

--
-- Dumping data for table `socialitem_read`
--

INSERT INTO `socialitem_read` (`securableitem_id`, `munge_id`, `count`) VALUES
(245, 'R2', 1),
(246, 'R2', 1),
(247, 'R2', 1),
(249, 'R2', 1),
(252, 'R2', 1),
(253, 'R2', 1),
(254, 'R2', 1),
(255, 'R2', 1),
(256, 'R2', 1),
(257, 'R2', 1),
(262, 'R2', 1),
(263, 'R2', 1),
(264, 'R2', 1);

-- --------------------------------------------------------

--
-- Table structure for table `stuckjob`
--

CREATE TABLE IF NOT EXISTS `stuckjob` (
`id` int(11) unsigned NOT NULL,
  `type` varchar(64) COLLATE utf8_unicode_ci DEFAULT NULL,
  `quantity` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `task`
--

CREATE TABLE IF NOT EXISTS `task` (
`id` int(11) unsigned NOT NULL,
  `activity_id` int(11) unsigned DEFAULT NULL,
  `completeddatetime` datetime DEFAULT NULL,
  `completed` tinyint(1) unsigned DEFAULT NULL,
  `duedatetime` datetime DEFAULT NULL,
  `description` text COLLATE utf8_unicode_ci,
  `name` varchar(128) COLLATE utf8_unicode_ci DEFAULT NULL,
  `status` int(11) DEFAULT NULL,
  `requestedbyuser__user_id` int(11) unsigned DEFAULT NULL,
  `project_id` int(11) unsigned DEFAULT NULL
) ENGINE=InnoDB AUTO_INCREMENT=22 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

--
-- Dumping data for table `task`
--

INSERT INTO `task` (`id`, `activity_id`, `completeddatetime`, `completed`, `duedatetime`, `description`, `name`, `status`, `requestedbyuser__user_id`, `project_id`) VALUES
(2, 61, '2013-06-02 12:33:17', 1, '2013-06-02 12:30:47', NULL, 'Send follow up email', NULL, NULL, NULL),
(3, 62, '2013-05-24 12:32:47', 1, '2013-05-24 12:30:47', NULL, 'Send product catalog', NULL, NULL, NULL),
(4, 63, '2013-05-18 12:31:32', 1, '2013-05-18 12:30:47', NULL, 'Follow up with renewal', NULL, NULL, NULL),
(5, 64, '2013-05-13 12:31:02', 1, '2013-05-13 12:30:47', NULL, 'Send product catalog', NULL, NULL, NULL),
(6, 65, '2013-05-31 12:36:47', 1, '2013-05-31 12:30:47', NULL, 'Follow Up', NULL, NULL, NULL),
(7, 66, '2013-05-15 12:31:47', 1, '2013-05-15 12:30:47', NULL, 'Make a proposal', NULL, NULL, NULL),
(8, 67, NULL, 0, '2013-07-20 12:30:47', NULL, 'Send follow up email', NULL, NULL, NULL),
(9, 68, '2013-05-23 12:33:02', 1, '2013-05-23 12:30:47', NULL, 'Make a proposal', NULL, NULL, NULL),
(10, 69, '2013-06-15 12:35:17', 1, '2013-06-15 12:30:47', NULL, 'Build prototype', NULL, NULL, NULL),
(11, 70, '2013-05-13 12:33:02', 1, '2013-05-13 12:30:47', NULL, 'Document changes to proposal', NULL, NULL, NULL),
(12, 71, '2013-05-30 12:34:02', 1, '2013-05-30 12:30:47', NULL, 'Research position changes', NULL, NULL, NULL),
(13, 72, NULL, 0, '2013-11-28 12:30:47', NULL, 'Make a proposal', NULL, NULL, NULL),
(14, 73, NULL, 0, '2013-10-06 12:30:47', NULL, 'Review contract with legal', NULL, NULL, NULL),
(15, 74, NULL, 0, '2013-07-19 12:30:47', NULL, 'Make a proposal', NULL, NULL, NULL),
(16, 75, NULL, 0, '2013-07-15 12:30:47', NULL, 'Send follow up email', NULL, NULL, NULL),
(17, 76, NULL, 0, '2013-08-29 12:30:47', NULL, 'Send follow up email', NULL, NULL, NULL),
(18, 77, NULL, 0, '2013-09-01 12:30:47', NULL, 'Research position changes', NULL, NULL, NULL),
(19, 78, '2013-06-01 12:33:02', 1, '2013-06-01 12:30:47', NULL, 'Research position changes', NULL, NULL, NULL),
(20, 81, NULL, 0, '0000-00-00 00:00:00', 'asfsda', 'test3', 1, 1, NULL),
(21, 84, NULL, 0, '0000-00-00 00:00:00', 'asfsda', 'test34', 1, 1, NULL);

-- --------------------------------------------------------

--
-- Table structure for table `taskchecklistitem`
--

CREATE TABLE IF NOT EXISTS `taskchecklistitem` (
`id` int(11) unsigned NOT NULL,
  `name` text COLLATE utf8_unicode_ci,
  `completed` tinyint(1) unsigned DEFAULT NULL,
  `task_id` int(11) unsigned DEFAULT NULL,
  `sortorder` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `task_read`
--

CREATE TABLE IF NOT EXISTS `task_read` (
  `securableitem_id` int(11) unsigned NOT NULL,
  `munge_id` varchar(12) COLLATE utf8_unicode_ci NOT NULL,
  `count` int(8) unsigned NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

--
-- Dumping data for table `task_read`
--

INSERT INTO `task_read` (`securableitem_id`, `munge_id`, `count`) VALUES
(265, 'R2', 1),
(266, 'R2', 1),
(267, 'R2', 1),
(268, 'R2', 1),
(269, 'R2', 1),
(270, 'R2', 1),
(271, 'R2', 1),
(272, 'R2', 1),
(273, 'R2', 1),
(274, 'R2', 1),
(275, 'R2', 1),
(276, 'R2', 1),
(277, 'R2', 1),
(278, 'R2', 1),
(279, 'R2', 1),
(280, 'R2', 1),
(281, 'R2', 1),
(282, 'R2', 1),
(309, 'G3', 1),
(312, 'G3', 1);

-- --------------------------------------------------------

--
-- Table structure for table `task_read_subscription`
--

CREATE TABLE IF NOT EXISTS `task_read_subscription` (
`id` int(11) unsigned NOT NULL,
  `userid` int(11) unsigned NOT NULL,
  `modelid` int(11) unsigned NOT NULL,
  `modifieddatetime` datetime DEFAULT NULL,
  `subscriptiontype` tinyint(4) DEFAULT NULL
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

--
-- Dumping data for table `task_read_subscription`
--

INSERT INTO `task_read_subscription` (`id`, `userid`, `modelid`, `modifieddatetime`, `subscriptiontype`) VALUES
(1, 1, 20, '2016-01-07 03:47:43', 1),
(2, 1, 21, '2016-01-07 03:51:44', 1);

-- --------------------------------------------------------

--
-- Table structure for table `workflowmessageinqueue`
--

CREATE TABLE IF NOT EXISTS `workflowmessageinqueue` (
`id` int(11) unsigned NOT NULL,
  `item_id` int(11) unsigned DEFAULT NULL,
  `savedworkflow_id` int(11) unsigned DEFAULT NULL,
  `triggeredbyuser__user_id` int(11) unsigned DEFAULT NULL,
  `modelclassname` varchar(64) COLLATE utf8_unicode_ci DEFAULT NULL,
  `processdatetime` datetime DEFAULT NULL,
  `serializeddata` text COLLATE utf8_unicode_ci,
  `modelitem_item_id` int(11) unsigned DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `_group`
--

CREATE TABLE IF NOT EXISTS `_group` (
`id` int(11) unsigned NOT NULL,
  `permitable_id` int(11) unsigned DEFAULT NULL,
  `name` varchar(64) COLLATE utf8_unicode_ci DEFAULT NULL,
  `_group_id` int(11) unsigned DEFAULT NULL
) ENGINE=InnoDB AUTO_INCREMENT=10 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

--
-- Dumping data for table `_group`
--

INSERT INTO `_group` (`id`, `permitable_id`, `name`, `_group_id`) VALUES
(1, 2, 'Super Administrators', NULL),
(3, 5, 'Everyone', NULL),
(4, 6, 'East', NULL),
(5, 7, 'West', NULL),
(6, 8, 'East Channel Sales', 4),
(7, 9, 'West Channel Sales', 5),
(8, 10, 'East Direct Sales', 4),
(9, 11, 'West Direct Sales', 5);

-- --------------------------------------------------------

--
-- Table structure for table `_group__user`
--

CREATE TABLE IF NOT EXISTS `_group__user` (
`id` int(11) unsigned NOT NULL,
  `_group_id` int(11) unsigned DEFAULT NULL,
  `_user_id` int(11) unsigned DEFAULT NULL
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

--
-- Dumping data for table `_group__user`
--

INSERT INTO `_group__user` (`id`, `_group_id`, `_user_id`) VALUES
(1, 1, 1),
(2, 1, 11);

-- --------------------------------------------------------

--
-- Table structure for table `_right`
--

CREATE TABLE IF NOT EXISTS `_right` (
`id` int(11) unsigned NOT NULL,
  `permitable_id` int(11) unsigned DEFAULT NULL,
  `modulename` varchar(64) COLLATE utf8_unicode_ci DEFAULT NULL,
  `name` varchar(64) COLLATE utf8_unicode_ci DEFAULT NULL,
  `type` tinyint(11) DEFAULT NULL
) ENGINE=InnoDB AUTO_INCREMENT=63 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

--
-- Dumping data for table `_right`
--

INSERT INTO `_right` (`id`, `permitable_id`, `modulename`, `name`, `type`) VALUES
(2, 5, 'UsersModule', 'Login Via Web', 1),
(3, 5, 'UsersModule', 'Login Via Mobile', 1),
(4, 5, 'UsersModule', 'Login Via Web API', 1),
(5, 5, 'AccountsModule', 'Access Accounts Tab', 1),
(6, 5, 'AccountsModule', 'Create Accounts', 1),
(7, 5, 'AccountsModule', 'Delete Accounts', 1),
(8, 5, 'CampaignsModule', 'Access Campaigns Tab', 1),
(9, 5, 'CampaignsModule', 'Create Campaigns', 1),
(10, 5, 'CampaignsModule', 'Delete Campaigns', 1),
(11, 5, 'ContactsModule', 'Access Contacts Tab', 1),
(12, 5, 'ContactsModule', 'Create Contacts', 1),
(13, 5, 'ContactsModule', 'Delete Contacts', 1),
(14, 5, 'ConversationsModule', 'Access Conversations Tab', 1),
(15, 5, 'ConversationsModule', 'Create Conversations', 1),
(16, 5, 'ConversationsModule', 'Delete Conversations', 1),
(17, 5, 'EmailMessagesModule', 'Access Emails Tab', 1),
(18, 5, 'EmailMessagesModule', 'Create Emails', 1),
(19, 5, 'EmailMessagesModule', 'Delete Emails', 1),
(20, 5, 'EmailTemplatesModule', 'Access Email Templates Tab', 1),
(21, 5, 'EmailTemplatesModule', 'Create Email Templates', 1),
(22, 5, 'EmailTemplatesModule', 'Delete Email Templates', 1),
(23, 5, 'LeadsModule', 'Access Leads Tab', 1),
(24, 5, 'LeadsModule', 'Create Leads', 1),
(25, 5, 'LeadsModule', 'Delete Leads', 1),
(26, 5, 'LeadsModule', 'Convert Leads', 1),
(27, 5, 'OpportunitiesModule', 'Access Opportunities Tab', 1),
(28, 5, 'OpportunitiesModule', 'Create Opportunities', 1),
(29, 5, 'OpportunitiesModule', 'Delete Opportunities', 1),
(30, 5, 'MarketingModule', 'Access Marketing Tab', 1),
(31, 5, 'MarketingListsModule', 'Access Marketing Lists Tab', 1),
(32, 5, 'MarketingListsModule', 'Create Marketing Lists', 1),
(33, 5, 'MarketingListsModule', 'Delete Marketing Lists', 1),
(34, 5, 'MeetingsModule', 'Access Meetings', 1),
(35, 5, 'MeetingsModule', 'Create Meetings', 1),
(36, 5, 'MeetingsModule', 'Delete Meetings', 1),
(37, 5, 'MissionsModule', 'Access Missions Tab', 1),
(38, 5, 'MissionsModule', 'Create Missions', 1),
(39, 5, 'MissionsModule', 'Delete Missions', 1),
(40, 5, 'NotesModule', 'Access Notes', 1),
(41, 5, 'NotesModule', 'Create Notes', 1),
(42, 5, 'NotesModule', 'Delete Notes', 1),
(43, 5, 'ReportsModule', 'Access Reports Tab', 1),
(44, 5, 'ReportsModule', 'Create Reports', 1),
(45, 5, 'ReportsModule', 'Delete Reports', 1),
(46, 5, 'TasksModule', 'Access Tasks', 1),
(47, 5, 'TasksModule', 'Create Tasks', 1),
(48, 5, 'TasksModule', 'Delete Tasks', 1),
(49, 5, 'HomeModule', 'Access Dashboards', 1),
(50, 5, 'HomeModule', 'Create Dashboards', 1),
(51, 5, 'HomeModule', 'Delete Dashboards', 1),
(52, 5, 'ExportModule', 'Access Export Tool', 1),
(53, 5, 'SocialItemsModule', 'Access Social Items', 1),
(54, 5, 'ProductsModule', 'Access Products Tab', 1),
(55, 5, 'ProductsModule', 'Create Products', 1),
(56, 5, 'ProductsModule', 'Delete Products', 1),
(57, 5, 'ProductTemplatesModule', 'Access Catalog Items Tab', 1),
(58, 5, 'ProductTemplatesModule', 'Create Catalog Items', 1),
(59, 5, 'ProductTemplatesModule', 'Delete Catalog Items', 1),
(60, 20, 'UsersModule', 'Login Via Mobile', 2),
(61, 20, 'UsersModule', 'Login Via Web', 2),
(62, 20, 'UsersModule', 'Login Via Web API', 2);

-- --------------------------------------------------------

--
-- Table structure for table `_user`
--

CREATE TABLE IF NOT EXISTS `_user` (
`id` int(11) unsigned NOT NULL,
  `person_id` int(11) unsigned DEFAULT NULL,
  `hash` varchar(60) COLLATE utf8_unicode_ci DEFAULT NULL,
  `language` varchar(10) COLLATE utf8_unicode_ci DEFAULT NULL,
  `locale` varchar(10) COLLATE utf8_unicode_ci DEFAULT NULL,
  `timezone` varchar(64) COLLATE utf8_unicode_ci DEFAULT NULL,
  `username` varchar(64) COLLATE utf8_unicode_ci DEFAULT NULL,
  `serializedavatardata` text COLLATE utf8_unicode_ci,
  `isactive` tinyint(1) unsigned DEFAULT NULL,
  `lastlogindatetime` datetime DEFAULT NULL,
  `permitable_id` int(11) unsigned DEFAULT NULL,
  `currency_id` int(11) unsigned DEFAULT NULL,
  `manager__user_id` int(11) unsigned DEFAULT NULL,
  `role_id` int(11) unsigned DEFAULT NULL,
  `isrootuser` tinyint(1) unsigned DEFAULT NULL,
  `hidefromselecting` tinyint(1) unsigned DEFAULT NULL,
  `issystemuser` tinyint(1) unsigned DEFAULT NULL,
  `hidefromleaderboard` tinyint(1) unsigned DEFAULT NULL
) ENGINE=InnoDB AUTO_INCREMENT=12 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

--
-- Dumping data for table `_user`
--

INSERT INTO `_user` (`id`, `person_id`, `hash`, `language`, `locale`, `timezone`, `username`, `serializedavatardata`, `isactive`, `lastlogindatetime`, `permitable_id`, `currency_id`, `manager__user_id`, `role_id`, `isrootuser`, `hidefromselecting`, `issystemuser`, `hidefromleaderboard`) VALUES
(1, 1, '$2y$12$ln1wZ.OXnvVONsfRmO7WW.BNbU3.hMRa.xWV9KnG.IbpGt1nV4/z6', NULL, NULL, 'America/Chicago', 'super', 'a:2:{s:10:"avatarType";i:2;s:24:"customAvatarEmailAddress";N;}', 1, '2016-01-19 20:32:02', 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(3, 4, '$2y$12$3XK.Hs44xOY4eZ9LFYsonOsBgox/jC3kIq3.D6XDxyZxkASRwCBz.', 'en', NULL, 'America/Chicago', 'admin', 'a:2:{s:10:"avatarType";i:2;s:24:"customAvatarEmailAddress";N;}', 1, '2013-06-25 12:29:36', 12, 4, NULL, 2, NULL, NULL, NULL, NULL),
(4, 5, '$2y$12$5o72PnfC8ObLtwIDQ1sCRepp2ZFqmR1geSxsoZXJWPafsrP2/L.D2', 'en', NULL, 'America/Chicago', 'jim', 'a:2:{s:10:"avatarType";i:2;s:24:"customAvatarEmailAddress";N;}', 1, '2013-06-25 12:29:37', 13, 4, NULL, 3, NULL, NULL, NULL, NULL),
(5, 6, '$2y$12$iAwD7iKKOqpUf3gSRC07wOTkjGA3yJYUqJAlCcuBp6VSh/9UdY6qi', 'en', NULL, 'America/Chicago', 'john', 'a:2:{s:10:"avatarType";i:2;s:24:"customAvatarEmailAddress";N;}', 1, '2013-06-25 12:29:37', 14, 4, NULL, 3, NULL, NULL, NULL, NULL),
(6, 7, '$2y$12$weasLevDIEKVkOS.0rxBo.fPG06/p3OfpT0lr6zjeFOZ70PcmIf3.', 'en', NULL, 'America/Chicago', 'sally', 'a:2:{s:10:"avatarType";i:2;s:24:"customAvatarEmailAddress";N;}', 1, '2013-06-25 12:29:37', 15, 4, NULL, 3, NULL, NULL, NULL, NULL),
(7, 8, '$2y$12$v/Cqxtko7nxVZOZ7CunJEuu5pUsT8.28iIe8ABrjXsSLWdvYEzsTe', 'en', NULL, 'America/Chicago', 'mary', 'a:2:{s:10:"avatarType";i:2;s:24:"customAvatarEmailAddress";N;}', 1, '2013-06-25 12:29:37', 16, 4, NULL, 3, NULL, NULL, NULL, NULL),
(8, 9, '$2y$12$NwZjVc2.P.zGxt6JEXozhuTZYN1/nmKnPSAzbQUV5s2m.jZoRsv7C', 'en', NULL, 'America/Chicago', 'katie', 'a:2:{s:10:"avatarType";i:2;s:24:"customAvatarEmailAddress";N;}', 1, '2013-06-25 12:29:37', 17, 4, NULL, 3, NULL, NULL, NULL, NULL),
(9, 10, '$2y$12$Ztr4StydUKRw0hMpUSq7qOjdChZ3wX.OmqZ.AgY.4XerZbnZcQUku', 'en', NULL, 'America/Chicago', 'jill', 'a:2:{s:10:"avatarType";i:2;s:24:"customAvatarEmailAddress";N;}', 1, '2013-06-25 12:29:38', 18, 4, NULL, 3, NULL, NULL, NULL, NULL),
(10, 11, '$2y$12$qWkyGSsqEilN9Hji7.8/u.k8szdPFbvsVPZ6DawOSsO6vF1C5J9i6', 'en', NULL, 'America/Chicago', 'sam', 'a:2:{s:10:"avatarType";i:2;s:24:"customAvatarEmailAddress";N;}', 1, '2013-06-25 12:29:38', 19, 4, NULL, 3, NULL, NULL, NULL, NULL),
(11, 40, '$2y$12$9pM83RxfUo.Bad4aMhypQ.kDL4ERZfnyM.eTAiFd1v/09PQpNlK4m', NULL, NULL, 'America/Chicago', 'backendjoboractionuser', NULL, 0, NULL, 20, NULL, NULL, NULL, NULL, 1, 1, 1);

-- --------------------------------------------------------

--
-- Table structure for table `_user_meeting`
--

CREATE TABLE IF NOT EXISTS `_user_meeting` (
`id` int(11) unsigned NOT NULL,
  `meeting_id` int(11) unsigned DEFAULT NULL,
  `_user_id` int(11) unsigned DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `__role_children_cache`
--

CREATE TABLE IF NOT EXISTS `__role_children_cache` (
  `permitable_id` int(11) NOT NULL DEFAULT '0',
  `role_id` int(11) NOT NULL DEFAULT '0'
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

--
-- Indexes for dumped tables
--

--
-- Indexes for table `account`
--
ALTER TABLE `account`
 ADD PRIMARY KEY (`id`);

--
-- Indexes for table `accountaccountaffiliation`
--
ALTER TABLE `accountaccountaffiliation`
 ADD PRIMARY KEY (`id`);

--
-- Indexes for table `accountcontactaffiliation`
--
ALTER TABLE `accountcontactaffiliation`
 ADD PRIMARY KEY (`id`);

--
-- Indexes for table `accountstarred`
--
ALTER TABLE `accountstarred`
 ADD PRIMARY KEY (`id`), ADD UNIQUE KEY `basestarredmodel_id_account_id` (`basestarredmodel_id`,`account_id`);

--
-- Indexes for table `account_project`
--
ALTER TABLE `account_project`
 ADD PRIMARY KEY (`id`), ADD UNIQUE KEY `unique_di_tcejorp_di_tnuocca` (`account_id`,`project_id`), ADD KEY `di_tnuocca` (`account_id`), ADD KEY `di_tcejorp` (`project_id`);

--
-- Indexes for table `account_read`
--
ALTER TABLE `account_read`
 ADD PRIMARY KEY (`securableitem_id`,`munge_id`), ADD KEY `index_account_read_securable_item_id` (`securableitem_id`);

--
-- Indexes for table `account_read_subscription`
--
ALTER TABLE `account_read_subscription`
 ADD PRIMARY KEY (`id`), ADD UNIQUE KEY `userid_modelid` (`userid`,`modelid`);

--
-- Indexes for table `account_read_subscription_temp_build`
--
ALTER TABLE `account_read_subscription_temp_build`
 ADD PRIMARY KEY (`id`);

--
-- Indexes for table `activelanguage`
--
ALTER TABLE `activelanguage`
 ADD PRIMARY KEY (`id`);

--
-- Indexes for table `activity`
--
ALTER TABLE `activity`
 ADD PRIMARY KEY (`id`);

--
-- Indexes for table `activity_item`
--
ALTER TABLE `activity_item`
 ADD PRIMARY KEY (`id`), ADD UNIQUE KEY `UQ_3072cf7f6632136338312839309d6fb046214edc` (`activity_id`,`item_id`), ADD KEY `index_for_activity_item_activity_id` (`activity_id`), ADD KEY `index_for_activity_item_item_id` (`item_id`);

--
-- Indexes for table `actual_permissions_cache`
--
ALTER TABLE `actual_permissions_cache`
 ADD PRIMARY KEY (`securableitem_id`,`permitable_id`);

--
-- Indexes for table `actual_rights_cache`
--
ALTER TABLE `actual_rights_cache`
 ADD PRIMARY KEY (`identifier`);

--
-- Indexes for table `address`
--
ALTER TABLE `address`
 ADD PRIMARY KEY (`id`);

--
-- Indexes for table `auditevent`
--
ALTER TABLE `auditevent`
 ADD PRIMARY KEY (`id`);

--
-- Indexes for table `autoresponder`
--
ALTER TABLE `autoresponder`
 ADD PRIMARY KEY (`id`);

--
-- Indexes for table `autoresponderitem`
--
ALTER TABLE `autoresponderitem`
 ADD PRIMARY KEY (`id`);

--
-- Indexes for table `autoresponderitemactivity`
--
ALTER TABLE `autoresponderitemactivity`
 ADD PRIMARY KEY (`id`), ADD UNIQUE KEY `emailmessageactivity_id_autoresponderitem_id` (`emailmessageactivity_id`,`autoresponderitem_id`), ADD KEY `emailmessageactivity_id` (`emailmessageactivity_id`), ADD KEY `autoresponderitem_id` (`autoresponderitem_id`);

--
-- Indexes for table `basecustomfield`
--
ALTER TABLE `basecustomfield`
 ADD PRIMARY KEY (`id`);

--
-- Indexes for table `basestarredmodel`
--
ALTER TABLE `basestarredmodel`
 ADD PRIMARY KEY (`id`);

--
-- Indexes for table `bytimeworkflowinqueue`
--
ALTER TABLE `bytimeworkflowinqueue`
 ADD PRIMARY KEY (`id`);

--
-- Indexes for table `calculatedderivedattributemetadata`
--
ALTER TABLE `calculatedderivedattributemetadata`
 ADD PRIMARY KEY (`id`);

--
-- Indexes for table `campaign`
--
ALTER TABLE `campaign`
 ADD PRIMARY KEY (`id`);

--
-- Indexes for table `campaignitem`
--
ALTER TABLE `campaignitem`
 ADD PRIMARY KEY (`id`), ADD KEY `campaign_id` (`campaign_id`), ADD KEY `contact_id` (`contact_id`);

--
-- Indexes for table `campaignitemactivity`
--
ALTER TABLE `campaignitemactivity`
 ADD PRIMARY KEY (`id`), ADD UNIQUE KEY `emailmessageactivity_id_campaignitem_id` (`emailmessageactivity_id`,`campaignitem_id`), ADD KEY `emailmessageactivity_id` (`emailmessageactivity_id`), ADD KEY `campaignitem_id` (`campaignitem_id`);

--
-- Indexes for table `campaign_read`
--
ALTER TABLE `campaign_read`
 ADD PRIMARY KEY (`securableitem_id`,`munge_id`), ADD KEY `index_campaign_read_securable_item_id` (`securableitem_id`);

--
-- Indexes for table `comment`
--
ALTER TABLE `comment`
 ADD PRIMARY KEY (`id`);

--
-- Indexes for table `contact`
--
ALTER TABLE `contact`
 ADD PRIMARY KEY (`id`), ADD KEY `person_id` (`person_id`);

--
-- Indexes for table `contactstarred`
--
ALTER TABLE `contactstarred`
 ADD PRIMARY KEY (`id`), ADD UNIQUE KEY `basestarredmodel_id_contact_id` (`basestarredmodel_id`,`contact_id`);

--
-- Indexes for table `contactstate`
--
ALTER TABLE `contactstate`
 ADD PRIMARY KEY (`id`);

--
-- Indexes for table `contactwebform`
--
ALTER TABLE `contactwebform`
 ADD PRIMARY KEY (`id`);

--
-- Indexes for table `contactwebformentry`
--
ALTER TABLE `contactwebformentry`
 ADD PRIMARY KEY (`id`);

--
-- Indexes for table `contactwebform_read`
--
ALTER TABLE `contactwebform_read`
 ADD PRIMARY KEY (`securableitem_id`,`munge_id`), ADD KEY `index_contactwebform_read_securable_item_id` (`securableitem_id`);

--
-- Indexes for table `contact_contract`
--
ALTER TABLE `contact_contract`
 ADD PRIMARY KEY (`id`), ADD UNIQUE KEY `unique_di_tcatnoc_di_tcartnoc` (`contract_id`,`contact_id`), ADD KEY `di_tcartnoc` (`contract_id`), ADD KEY `di_tcatnoc` (`contact_id`);

--
-- Indexes for table `contact_opportunity`
--
ALTER TABLE `contact_opportunity`
 ADD PRIMARY KEY (`id`), ADD UNIQUE KEY `UQ_49ec3f900018477a710f404b661c83de848a2192` (`contact_id`,`opportunity_id`), ADD KEY `index_for_contact_opportunity_contact_id` (`contact_id`), ADD KEY `index_for_contact_opportunity_opportunity_id` (`opportunity_id`);

--
-- Indexes for table `contact_project`
--
ALTER TABLE `contact_project`
 ADD PRIMARY KEY (`id`), ADD UNIQUE KEY `unique_di_tcejorp_di_tcatnoc` (`contact_id`,`project_id`), ADD KEY `di_tcatnoc` (`contact_id`), ADD KEY `di_tcejorp` (`project_id`);

--
-- Indexes for table `contact_read`
--
ALTER TABLE `contact_read`
 ADD PRIMARY KEY (`securableitem_id`,`munge_id`), ADD KEY `index_contact_read_securable_item_id` (`securableitem_id`);

--
-- Indexes for table `contact_read_subscription`
--
ALTER TABLE `contact_read_subscription`
 ADD PRIMARY KEY (`id`), ADD UNIQUE KEY `userid_modelid` (`userid`,`modelid`);

--
-- Indexes for table `contract`
--
ALTER TABLE `contract`
 ADD PRIMARY KEY (`id`);

--
-- Indexes for table `contractstarred`
--
ALTER TABLE `contractstarred`
 ADD PRIMARY KEY (`id`), ADD UNIQUE KEY `basestarredmodel_id_opportunity_id` (`basestarredmodel_id`,`contract_id`);

--
-- Indexes for table `contract_opportunity`
--
ALTER TABLE `contract_opportunity`
 ADD PRIMARY KEY (`id`), ADD UNIQUE KEY `UQ_49ec3f900018477a710f404b661c83de848a2192` (`contract_id`,`opportunity_id`), ADD KEY `index_for_contract_opportunity_contract_id` (`contract_id`), ADD KEY `index_for_contract_opportunity_opportunity_id` (`opportunity_id`);

--
-- Indexes for table `contract_project`
--
ALTER TABLE `contract_project`
 ADD PRIMARY KEY (`id`), ADD UNIQUE KEY `unique_di_tcejorp_di_tcartnoc` (`contract_id`,`project_id`), ADD KEY `di_tcartnoc` (`contract_id`), ADD KEY `di_tcejorp` (`project_id`);

--
-- Indexes for table `contract_read`
--
ALTER TABLE `contract_read`
 ADD PRIMARY KEY (`securableitem_id`,`munge_id`), ADD KEY `index_opportunity_read_securable_item_id` (`securableitem_id`);

--
-- Indexes for table `conversation`
--
ALTER TABLE `conversation`
 ADD PRIMARY KEY (`id`);

--
-- Indexes for table `conversationparticipant`
--
ALTER TABLE `conversationparticipant`
 ADD PRIMARY KEY (`id`);

--
-- Indexes for table `conversationstarred`
--
ALTER TABLE `conversationstarred`
 ADD PRIMARY KEY (`id`), ADD UNIQUE KEY `basestarredmodel_id_conversation_id` (`basestarredmodel_id`,`conversation_id`);

--
-- Indexes for table `conversation_item`
--
ALTER TABLE `conversation_item`
 ADD PRIMARY KEY (`id`), ADD UNIQUE KEY `UQ_f9926d7fcbce985516b367d10bb523785fbab2d7` (`conversation_id`,`item_id`), ADD KEY `index_for_conversation_item_conversation_id` (`conversation_id`), ADD KEY `index_for_conversation_item_item_id` (`item_id`);

--
-- Indexes for table `conversation_read`
--
ALTER TABLE `conversation_read`
 ADD PRIMARY KEY (`securableitem_id`,`munge_id`), ADD KEY `index_conversation_read_securable_item_id` (`securableitem_id`);

--
-- Indexes for table `currency`
--
ALTER TABLE `currency`
 ADD PRIMARY KEY (`id`), ADD UNIQUE KEY `UQ_4f5a32b86618fd9d6a870ffe890cf77a88669783` (`code`);

--
-- Indexes for table `currencyvalue`
--
ALTER TABLE `currencyvalue`
 ADD PRIMARY KEY (`id`);

--
-- Indexes for table `customfield`
--
ALTER TABLE `customfield`
 ADD PRIMARY KEY (`id`);

--
-- Indexes for table `customfielddata`
--
ALTER TABLE `customfielddata`
 ADD PRIMARY KEY (`id`), ADD UNIQUE KEY `UQ_f97279e76d95d98f7433ff400fab94e189ee6052` (`name`);

--
-- Indexes for table `customfieldvalue`
--
ALTER TABLE `customfieldvalue`
 ADD PRIMARY KEY (`id`), ADD KEY `multiplevaluescustomfield_id` (`multiplevaluescustomfield_id`);

--
-- Indexes for table `dashboard`
--
ALTER TABLE `dashboard`
 ADD PRIMARY KEY (`id`);

--
-- Indexes for table `derivedattributemetadata`
--
ALTER TABLE `derivedattributemetadata`
 ADD PRIMARY KEY (`id`);

--
-- Indexes for table `dropdowndependencyderivedattributemetadata`
--
ALTER TABLE `dropdowndependencyderivedattributemetadata`
 ADD PRIMARY KEY (`id`);

--
-- Indexes for table `email`
--
ALTER TABLE `email`
 ADD PRIMARY KEY (`id`);

--
-- Indexes for table `emailaccount`
--
ALTER TABLE `emailaccount`
 ADD PRIMARY KEY (`id`);

--
-- Indexes for table `emailbox`
--
ALTER TABLE `emailbox`
 ADD PRIMARY KEY (`id`);

--
-- Indexes for table `emailfolder`
--
ALTER TABLE `emailfolder`
 ADD PRIMARY KEY (`id`);

--
-- Indexes for table `emailmessage`
--
ALTER TABLE `emailmessage`
 ADD PRIMARY KEY (`id`);

--
-- Indexes for table `emailmessageactivity`
--
ALTER TABLE `emailmessageactivity`
 ADD PRIMARY KEY (`id`);

--
-- Indexes for table `emailmessagecontent`
--
ALTER TABLE `emailmessagecontent`
 ADD PRIMARY KEY (`id`);

--
-- Indexes for table `emailmessagerecipient`
--
ALTER TABLE `emailmessagerecipient`
 ADD PRIMARY KEY (`id`), ADD KEY `remailmessage_Index` (`emailmessage_id`);

--
-- Indexes for table `emailmessagerecipient_item`
--
ALTER TABLE `emailmessagerecipient_item`
 ADD PRIMARY KEY (`id`), ADD UNIQUE KEY `unique_di_meti_di_tneipiceregassemliame` (`emailmessagerecipient_id`,`item_id`), ADD KEY `di_tneipiceregassemliame` (`emailmessagerecipient_id`), ADD KEY `di_meti` (`item_id`);

--
-- Indexes for table `emailmessagesender`
--
ALTER TABLE `emailmessagesender`
 ADD PRIMARY KEY (`id`);

--
-- Indexes for table `emailmessagesenderror`
--
ALTER TABLE `emailmessagesenderror`
 ADD PRIMARY KEY (`id`);

--
-- Indexes for table `emailmessagesender_item`
--
ALTER TABLE `emailmessagesender_item`
 ADD PRIMARY KEY (`id`), ADD UNIQUE KEY `unique_di_meti_di_rednesegassemliame` (`emailmessagesender_id`,`item_id`), ADD KEY `di_rednesegassemliame` (`emailmessagesender_id`), ADD KEY `di_meti` (`item_id`);

--
-- Indexes for table `emailmessageurl`
--
ALTER TABLE `emailmessageurl`
 ADD PRIMARY KEY (`id`);

--
-- Indexes for table `emailmessage_read`
--
ALTER TABLE `emailmessage_read`
 ADD PRIMARY KEY (`securableitem_id`,`munge_id`), ADD KEY `index_emailmessage_read_securable_item_id` (`securableitem_id`);

--
-- Indexes for table `emailsignature`
--
ALTER TABLE `emailsignature`
 ADD PRIMARY KEY (`id`);

--
-- Indexes for table `emailtemplate`
--
ALTER TABLE `emailtemplate`
 ADD PRIMARY KEY (`id`);

--
-- Indexes for table `emailtemplate_read`
--
ALTER TABLE `emailtemplate_read`
 ADD PRIMARY KEY (`securableitem_id`,`munge_id`), ADD KEY `index_emailtemplate_read_securable_item_id` (`securableitem_id`);

--
-- Indexes for table `exportfilemodel`
--
ALTER TABLE `exportfilemodel`
 ADD PRIMARY KEY (`id`);

--
-- Indexes for table `exportitem`
--
ALTER TABLE `exportitem`
 ADD PRIMARY KEY (`id`);

--
-- Indexes for table `exportitem_read`
--
ALTER TABLE `exportitem_read`
 ADD PRIMARY KEY (`id`), ADD UNIQUE KEY `securableitem_id_munge_id` (`securableitem_id`,`munge_id`), ADD KEY `exportitem_read_securableitem_id` (`securableitem_id`);

--
-- Indexes for table `filecontent`
--
ALTER TABLE `filecontent`
 ADD PRIMARY KEY (`id`);

--
-- Indexes for table `filemodel`
--
ALTER TABLE `filemodel`
 ADD PRIMARY KEY (`id`);

--
-- Indexes for table `gamebadge`
--
ALTER TABLE `gamebadge`
 ADD PRIMARY KEY (`id`);

--
-- Indexes for table `gamecoin`
--
ALTER TABLE `gamecoin`
 ADD PRIMARY KEY (`id`);

--
-- Indexes for table `gamecollection`
--
ALTER TABLE `gamecollection`
 ADD PRIMARY KEY (`id`);

--
-- Indexes for table `gamelevel`
--
ALTER TABLE `gamelevel`
 ADD PRIMARY KEY (`id`);

--
-- Indexes for table `gamenotification`
--
ALTER TABLE `gamenotification`
 ADD PRIMARY KEY (`id`);

--
-- Indexes for table `gamepoint`
--
ALTER TABLE `gamepoint`
 ADD PRIMARY KEY (`id`);

--
-- Indexes for table `gamepointtransaction`
--
ALTER TABLE `gamepointtransaction`
 ADD PRIMARY KEY (`id`), ADD KEY `gamepoint_id` (`gamepoint_id`);

--
-- Indexes for table `gamereward`
--
ALTER TABLE `gamereward`
 ADD PRIMARY KEY (`id`);

--
-- Indexes for table `gamerewardtransaction`
--
ALTER TABLE `gamerewardtransaction`
 ADD PRIMARY KEY (`id`);

--
-- Indexes for table `gamereward_read`
--
ALTER TABLE `gamereward_read`
 ADD PRIMARY KEY (`id`), ADD UNIQUE KEY `securableitem_id_munge_id` (`securableitem_id`,`munge_id`), ADD KEY `gamereward_read_securableitem_id` (`securableitem_id`);

--
-- Indexes for table `gamescore`
--
ALTER TABLE `gamescore`
 ADD PRIMARY KEY (`id`);

--
-- Indexes for table `globalmetadata`
--
ALTER TABLE `globalmetadata`
 ADD PRIMARY KEY (`id`), ADD UNIQUE KEY `UQ_6950932d5c0020179c0a175933c8d60ccab633ae` (`classname`);

--
-- Indexes for table `imagefilemodel`
--
ALTER TABLE `imagefilemodel`
 ADD PRIMARY KEY (`id`);

--
-- Indexes for table `import`
--
ALTER TABLE `import`
 ADD PRIMARY KEY (`id`);

--
-- Indexes for table `importtable1`
--
ALTER TABLE `importtable1`
 ADD PRIMARY KEY (`id`);

--
-- Indexes for table `importtable2`
--
ALTER TABLE `importtable2`
 ADD PRIMARY KEY (`id`);

--
-- Indexes for table `importtable3`
--
ALTER TABLE `importtable3`
 ADD PRIMARY KEY (`id`);

--
-- Indexes for table `importtable4`
--
ALTER TABLE `importtable4`
 ADD PRIMARY KEY (`id`);

--
-- Indexes for table `item`
--
ALTER TABLE `item`
 ADD PRIMARY KEY (`id`);

--
-- Indexes for table `jobinprocess`
--
ALTER TABLE `jobinprocess`
 ADD PRIMARY KEY (`id`);

--
-- Indexes for table `joblog`
--
ALTER TABLE `joblog`
 ADD PRIMARY KEY (`id`);

--
-- Indexes for table `kanbanitem`
--
ALTER TABLE `kanbanitem`
 ADD PRIMARY KEY (`id`);

--
-- Indexes for table `marketinglist`
--
ALTER TABLE `marketinglist`
 ADD PRIMARY KEY (`id`);

--
-- Indexes for table `marketinglistmember`
--
ALTER TABLE `marketinglistmember`
 ADD PRIMARY KEY (`id`);

--
-- Indexes for table `marketinglist_read`
--
ALTER TABLE `marketinglist_read`
 ADD PRIMARY KEY (`securableitem_id`,`munge_id`), ADD KEY `index_marketinglist_read_securable_item_id` (`securableitem_id`);

--
-- Indexes for table `meeting`
--
ALTER TABLE `meeting`
 ADD PRIMARY KEY (`id`);

--
-- Indexes for table `meeting_read`
--
ALTER TABLE `meeting_read`
 ADD PRIMARY KEY (`securableitem_id`,`munge_id`), ADD KEY `index_meeting_read_securable_item_id` (`securableitem_id`);

--
-- Indexes for table `meeting_read_subscription`
--
ALTER TABLE `meeting_read_subscription`
 ADD PRIMARY KEY (`id`), ADD UNIQUE KEY `userid_modelid` (`userid`,`modelid`);

--
-- Indexes for table `messagesource`
--
ALTER TABLE `messagesource`
 ADD PRIMARY KEY (`id`), ADD UNIQUE KEY `source_category_Index` (`category`,`source`(767));

--
-- Indexes for table `messagetranslation`
--
ALTER TABLE `messagetranslation`
 ADD PRIMARY KEY (`id`), ADD UNIQUE KEY `source_language_translation_Index` (`messagesource_id`,`language`,`translation`(767));

--
-- Indexes for table `mission`
--
ALTER TABLE `mission`
 ADD PRIMARY KEY (`id`);

--
-- Indexes for table `mission_read`
--
ALTER TABLE `mission_read`
 ADD PRIMARY KEY (`securableitem_id`,`munge_id`), ADD KEY `index_mission_read_securable_item_id` (`securableitem_id`);

--
-- Indexes for table `modelcreationapisync`
--
ALTER TABLE `modelcreationapisync`
 ADD PRIMARY KEY (`id`);

--
-- Indexes for table `multiplevaluescustomfield`
--
ALTER TABLE `multiplevaluescustomfield`
 ADD PRIMARY KEY (`id`), ADD KEY `basecustomfield_id` (`basecustomfield_id`);

--
-- Indexes for table `namedsecurableitem`
--
ALTER TABLE `namedsecurableitem`
 ADD PRIMARY KEY (`id`), ADD UNIQUE KEY `UQ_f97279e76d95d98f7433ff400fab94e189ee6052` (`name`);

--
-- Indexes for table `named_securable_actual_permissions_cache`
--
ALTER TABLE `named_securable_actual_permissions_cache`
 ADD PRIMARY KEY (`securableitem_name`,`permitable_id`);

--
-- Indexes for table `note`
--
ALTER TABLE `note`
 ADD PRIMARY KEY (`id`);

--
-- Indexes for table `note_read`
--
ALTER TABLE `note_read`
 ADD PRIMARY KEY (`securableitem_id`,`munge_id`), ADD KEY `index_note_read_securable_item_id` (`securableitem_id`);

--
-- Indexes for table `notification`
--
ALTER TABLE `notification`
 ADD PRIMARY KEY (`id`);

--
-- Indexes for table `notificationmessage`
--
ALTER TABLE `notificationmessage`
 ADD PRIMARY KEY (`id`);

--
-- Indexes for table `notificationsubscriber`
--
ALTER TABLE `notificationsubscriber`
 ADD PRIMARY KEY (`id`);

--
-- Indexes for table `opportunity`
--
ALTER TABLE `opportunity`
 ADD PRIMARY KEY (`id`);

--
-- Indexes for table `opportunitystarred`
--
ALTER TABLE `opportunitystarred`
 ADD PRIMARY KEY (`id`), ADD UNIQUE KEY `basestarredmodel_id_opportunity_id` (`basestarredmodel_id`,`opportunity_id`);

--
-- Indexes for table `opportunity_project`
--
ALTER TABLE `opportunity_project`
 ADD PRIMARY KEY (`id`), ADD UNIQUE KEY `unique_di_tcejorp_di_ytinutroppo` (`opportunity_id`,`project_id`), ADD KEY `di_ytinutroppo` (`opportunity_id`), ADD KEY `di_tcejorp` (`project_id`);

--
-- Indexes for table `opportunity_read`
--
ALTER TABLE `opportunity_read`
 ADD PRIMARY KEY (`securableitem_id`,`munge_id`), ADD KEY `index_opportunity_read_securable_item_id` (`securableitem_id`);

--
-- Indexes for table `ownedsecurableitem`
--
ALTER TABLE `ownedsecurableitem`
 ADD PRIMARY KEY (`id`), ADD KEY `owner__user_id` (`owner__user_id`);

--
-- Indexes for table `permission`
--
ALTER TABLE `permission`
 ADD PRIMARY KEY (`id`);

--
-- Indexes for table `permitable`
--
ALTER TABLE `permitable`
 ADD PRIMARY KEY (`id`), ADD KEY `item_id` (`item_id`);

--
-- Indexes for table `person`
--
ALTER TABLE `person`
 ADD PRIMARY KEY (`id`), ADD KEY `ownedsecurableitem_id` (`ownedsecurableitem_id`);

--
-- Indexes for table `personwhohavenotreadlatest`
--
ALTER TABLE `personwhohavenotreadlatest`
 ADD PRIMARY KEY (`id`);

--
-- Indexes for table `perusermetadata`
--
ALTER TABLE `perusermetadata`
 ADD PRIMARY KEY (`id`);

--
-- Indexes for table `policy`
--
ALTER TABLE `policy`
 ADD PRIMARY KEY (`id`);

--
-- Indexes for table `portlet`
--
ALTER TABLE `portlet`
 ADD PRIMARY KEY (`id`);

--
-- Indexes for table `product`
--
ALTER TABLE `product`
 ADD PRIMARY KEY (`id`);

--
-- Indexes for table `productcatalog`
--
ALTER TABLE `productcatalog`
 ADD PRIMARY KEY (`id`);

--
-- Indexes for table `productcatalog_productcategory`
--
ALTER TABLE `productcatalog_productcategory`
 ADD PRIMARY KEY (`id`), ADD UNIQUE KEY `UQ_f6568fb4a89ba252a0046e46ae78caab1cf7b128` (`productcatalog_id`,`productcategory_id`), ADD KEY `index_for_productcatalog_productcategory_productcategory_id` (`productcategory_id`), ADD KEY `index_for_productcatalog_productcategory_productcatalog_id` (`productcatalog_id`);

--
-- Indexes for table `productcategory`
--
ALTER TABLE `productcategory`
 ADD PRIMARY KEY (`id`);

--
-- Indexes for table `productcategory_producttemplate`
--
ALTER TABLE `productcategory_producttemplate`
 ADD PRIMARY KEY (`id`), ADD UNIQUE KEY `UQ_ddf85331d64908459ca387f73c4133bee1cbab07` (`productcategory_id`,`producttemplate_id`), ADD KEY `index_for_productcategory_producttemplate_producttemplate_id` (`producttemplate_id`), ADD KEY `index_for_productcategory_producttemplate_productcategory_id` (`productcategory_id`);

--
-- Indexes for table `producttemplate`
--
ALTER TABLE `producttemplate`
 ADD PRIMARY KEY (`id`);

--
-- Indexes for table `product_productcategory`
--
ALTER TABLE `product_productcategory`
 ADD PRIMARY KEY (`id`), ADD UNIQUE KEY `UQ_1847df0f79503c223534c3058299bc8e4db1c51e` (`product_id`,`productcategory_id`), ADD KEY `index_for_product_productcategory_product_id` (`product_id`), ADD KEY `index_for_product_productcategory_productcategory_id` (`productcategory_id`);

--
-- Indexes for table `product_read`
--
ALTER TABLE `product_read`
 ADD PRIMARY KEY (`securableitem_id`,`munge_id`), ADD KEY `index_product_read_securable_item_id` (`securableitem_id`);

--
-- Indexes for table `project`
--
ALTER TABLE `project`
 ADD PRIMARY KEY (`id`);

--
-- Indexes for table `projectauditevent`
--
ALTER TABLE `projectauditevent`
 ADD PRIMARY KEY (`id`);

--
-- Indexes for table `project_read`
--
ALTER TABLE `project_read`
 ADD PRIMARY KEY (`id`), ADD UNIQUE KEY `securableitem_id_munge_id` (`securableitem_id`,`munge_id`), ADD KEY `project_read_securableitem_id` (`securableitem_id`);

--
-- Indexes for table `role`
--
ALTER TABLE `role`
 ADD PRIMARY KEY (`id`), ADD UNIQUE KEY `UQ_f97279e76d95d98f7433ff400fab94e189ee6052` (`name`);

--
-- Indexes for table `savedcalendar`
--
ALTER TABLE `savedcalendar`
 ADD PRIMARY KEY (`id`);

--
-- Indexes for table `savedcalendarsubscription`
--
ALTER TABLE `savedcalendarsubscription`
 ADD PRIMARY KEY (`id`);

--
-- Indexes for table `savedcalendar_read`
--
ALTER TABLE `savedcalendar_read`
 ADD PRIMARY KEY (`id`), ADD UNIQUE KEY `securableitem_id_munge_id` (`securableitem_id`,`munge_id`), ADD KEY `savedcalendar_read_securableitem_id` (`securableitem_id`);

--
-- Indexes for table `savedreport`
--
ALTER TABLE `savedreport`
 ADD PRIMARY KEY (`id`);

--
-- Indexes for table `savedreport_read`
--
ALTER TABLE `savedreport_read`
 ADD PRIMARY KEY (`securableitem_id`,`munge_id`), ADD KEY `index_savedreport_read_securable_item_id` (`securableitem_id`);

--
-- Indexes for table `savedsearch`
--
ALTER TABLE `savedsearch`
 ADD PRIMARY KEY (`id`);

--
-- Indexes for table `savedworkflow`
--
ALTER TABLE `savedworkflow`
 ADD PRIMARY KEY (`id`);

--
-- Indexes for table `securableitem`
--
ALTER TABLE `securableitem`
 ADD PRIMARY KEY (`id`);

--
-- Indexes for table `sellpriceformula`
--
ALTER TABLE `sellpriceformula`
 ADD PRIMARY KEY (`id`);

--
-- Indexes for table `shorturl`
--
ALTER TABLE `shorturl`
 ADD PRIMARY KEY (`id`);

--
-- Indexes for table `socialitem`
--
ALTER TABLE `socialitem`
 ADD PRIMARY KEY (`id`);

--
-- Indexes for table `socialitem_read`
--
ALTER TABLE `socialitem_read`
 ADD PRIMARY KEY (`securableitem_id`,`munge_id`), ADD KEY `index_socialitem_read_securable_item_id` (`securableitem_id`);

--
-- Indexes for table `stuckjob`
--
ALTER TABLE `stuckjob`
 ADD PRIMARY KEY (`id`);

--
-- Indexes for table `task`
--
ALTER TABLE `task`
 ADD PRIMARY KEY (`id`);

--
-- Indexes for table `taskchecklistitem`
--
ALTER TABLE `taskchecklistitem`
 ADD PRIMARY KEY (`id`);

--
-- Indexes for table `task_read`
--
ALTER TABLE `task_read`
 ADD PRIMARY KEY (`securableitem_id`,`munge_id`), ADD KEY `index_task_read_securable_item_id` (`securableitem_id`);

--
-- Indexes for table `task_read_subscription`
--
ALTER TABLE `task_read_subscription`
 ADD PRIMARY KEY (`id`), ADD UNIQUE KEY `userid_modelid` (`userid`,`modelid`);

--
-- Indexes for table `workflowmessageinqueue`
--
ALTER TABLE `workflowmessageinqueue`
 ADD PRIMARY KEY (`id`);

--
-- Indexes for table `_group`
--
ALTER TABLE `_group`
 ADD PRIMARY KEY (`id`), ADD UNIQUE KEY `UQ_f97279e76d95d98f7433ff400fab94e189ee6052` (`name`);

--
-- Indexes for table `_group__user`
--
ALTER TABLE `_group__user`
 ADD PRIMARY KEY (`id`), ADD UNIQUE KEY `UQ_8b7b9c47c851f14d46de32b2c5dd3ffd490b9319` (`_group_id`,`_user_id`), ADD KEY `index_for__group__user__group_id` (`_group_id`), ADD KEY `index_for__group__user__user_id` (`_user_id`);

--
-- Indexes for table `_right`
--
ALTER TABLE `_right`
 ADD PRIMARY KEY (`id`);

--
-- Indexes for table `_user`
--
ALTER TABLE `_user`
 ADD PRIMARY KEY (`id`), ADD UNIQUE KEY `UQ_2f9f20ae60de87f7bdd974b52941c30e287c6eef` (`username`), ADD KEY `permitable_id` (`permitable_id`);

--
-- Indexes for table `_user_meeting`
--
ALTER TABLE `_user_meeting`
 ADD PRIMARY KEY (`id`), ADD UNIQUE KEY `unique_di_resu__di_gniteem` (`meeting_id`,`_user_id`), ADD KEY `di_gniteem` (`meeting_id`), ADD KEY `di_resu_` (`_user_id`);

--
-- Indexes for table `__role_children_cache`
--
ALTER TABLE `__role_children_cache`
 ADD PRIMARY KEY (`permitable_id`,`role_id`), ADD UNIQUE KEY `permitable_id` (`permitable_id`,`role_id`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `account`
--
ALTER TABLE `account`
MODIFY `id` int(11) unsigned NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=72;
--
-- AUTO_INCREMENT for table `accountaccountaffiliation`
--
ALTER TABLE `accountaccountaffiliation`
MODIFY `id` int(11) unsigned NOT NULL AUTO_INCREMENT;
--
-- AUTO_INCREMENT for table `accountcontactaffiliation`
--
ALTER TABLE `accountcontactaffiliation`
MODIFY `id` int(11) unsigned NOT NULL AUTO_INCREMENT;
--
-- AUTO_INCREMENT for table `accountstarred`
--
ALTER TABLE `accountstarred`
MODIFY `id` int(11) unsigned NOT NULL AUTO_INCREMENT;
--
-- AUTO_INCREMENT for table `account_project`
--
ALTER TABLE `account_project`
MODIFY `id` int(11) unsigned NOT NULL AUTO_INCREMENT;
--
-- AUTO_INCREMENT for table `account_read_subscription`
--
ALTER TABLE `account_read_subscription`
MODIFY `id` int(11) unsigned NOT NULL AUTO_INCREMENT;
--
-- AUTO_INCREMENT for table `account_read_subscription_temp_build`
--
ALTER TABLE `account_read_subscription_temp_build`
MODIFY `id` int(11) unsigned NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=71;
--
-- AUTO_INCREMENT for table `activelanguage`
--
ALTER TABLE `activelanguage`
MODIFY `id` int(11) unsigned NOT NULL AUTO_INCREMENT;
--
-- AUTO_INCREMENT for table `activity`
--
ALTER TABLE `activity`
MODIFY `id` int(11) unsigned NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=85;
--
-- AUTO_INCREMENT for table `activity_item`
--
ALTER TABLE `activity_item`
MODIFY `id` int(11) unsigned NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=228;
--
-- AUTO_INCREMENT for table `address`
--
ALTER TABLE `address`
MODIFY `id` int(11) unsigned NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=51;
--
-- AUTO_INCREMENT for table `auditevent`
--
ALTER TABLE `auditevent`
MODIFY `id` int(11) unsigned NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=1867;
--
-- AUTO_INCREMENT for table `autoresponder`
--
ALTER TABLE `autoresponder`
MODIFY `id` int(11) unsigned NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=6;
--
-- AUTO_INCREMENT for table `autoresponderitem`
--
ALTER TABLE `autoresponderitem`
MODIFY `id` int(11) unsigned NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=20;
--
-- AUTO_INCREMENT for table `autoresponderitemactivity`
--
ALTER TABLE `autoresponderitemactivity`
MODIFY `id` int(11) unsigned NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=20;
--
-- AUTO_INCREMENT for table `basecustomfield`
--
ALTER TABLE `basecustomfield`
MODIFY `id` int(11) unsigned NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=538;
--
-- AUTO_INCREMENT for table `basestarredmodel`
--
ALTER TABLE `basestarredmodel`
MODIFY `id` int(11) unsigned NOT NULL AUTO_INCREMENT;
--
-- AUTO_INCREMENT for table `bytimeworkflowinqueue`
--
ALTER TABLE `bytimeworkflowinqueue`
MODIFY `id` int(11) unsigned NOT NULL AUTO_INCREMENT;
--
-- AUTO_INCREMENT for table `calculatedderivedattributemetadata`
--
ALTER TABLE `calculatedderivedattributemetadata`
MODIFY `id` int(11) unsigned NOT NULL AUTO_INCREMENT;
--
-- AUTO_INCREMENT for table `campaign`
--
ALTER TABLE `campaign`
MODIFY `id` int(11) unsigned NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=12;
--
-- AUTO_INCREMENT for table `campaignitem`
--
ALTER TABLE `campaignitem`
MODIFY `id` int(11) unsigned NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=20;
--
-- AUTO_INCREMENT for table `campaignitemactivity`
--
ALTER TABLE `campaignitemactivity`
MODIFY `id` int(11) unsigned NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=20;
--
-- AUTO_INCREMENT for table `comment`
--
ALTER TABLE `comment`
MODIFY `id` int(11) unsigned NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=44;
--
-- AUTO_INCREMENT for table `contact`
--
ALTER TABLE `contact`
MODIFY `id` int(11) unsigned NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=32;
--
-- AUTO_INCREMENT for table `contactstarred`
--
ALTER TABLE `contactstarred`
MODIFY `id` int(11) unsigned NOT NULL AUTO_INCREMENT;
--
-- AUTO_INCREMENT for table `contactstate`
--
ALTER TABLE `contactstate`
MODIFY `id` int(11) unsigned NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=8;
--
-- AUTO_INCREMENT for table `contactwebform`
--
ALTER TABLE `contactwebform`
MODIFY `id` int(11) unsigned NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=7;
--
-- AUTO_INCREMENT for table `contactwebformentry`
--
ALTER TABLE `contactwebformentry`
MODIFY `id` int(11) unsigned NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=7;
--
-- AUTO_INCREMENT for table `contact_contract`
--
ALTER TABLE `contact_contract`
MODIFY `id` int(11) unsigned NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=2;
--
-- AUTO_INCREMENT for table `contact_opportunity`
--
ALTER TABLE `contact_opportunity`
MODIFY `id` int(11) unsigned NOT NULL AUTO_INCREMENT;
--
-- AUTO_INCREMENT for table `contact_project`
--
ALTER TABLE `contact_project`
MODIFY `id` int(11) unsigned NOT NULL AUTO_INCREMENT;
--
-- AUTO_INCREMENT for table `contact_read_subscription`
--
ALTER TABLE `contact_read_subscription`
MODIFY `id` int(11) unsigned NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=3;
--
-- AUTO_INCREMENT for table `contract`
--
ALTER TABLE `contract`
MODIFY `id` int(11) unsigned NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=72;
--
-- AUTO_INCREMENT for table `contractstarred`
--
ALTER TABLE `contractstarred`
MODIFY `id` int(11) unsigned NOT NULL AUTO_INCREMENT;
--
-- AUTO_INCREMENT for table `contract_opportunity`
--
ALTER TABLE `contract_opportunity`
MODIFY `id` int(11) unsigned NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=59;
--
-- AUTO_INCREMENT for table `contract_project`
--
ALTER TABLE `contract_project`
MODIFY `id` int(11) unsigned NOT NULL AUTO_INCREMENT;
--
-- AUTO_INCREMENT for table `conversation`
--
ALTER TABLE `conversation`
MODIFY `id` int(11) unsigned NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=5;
--
-- AUTO_INCREMENT for table `conversationparticipant`
--
ALTER TABLE `conversationparticipant`
MODIFY `id` int(11) unsigned NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=14;
--
-- AUTO_INCREMENT for table `conversationstarred`
--
ALTER TABLE `conversationstarred`
MODIFY `id` int(11) unsigned NOT NULL AUTO_INCREMENT;
--
-- AUTO_INCREMENT for table `conversation_item`
--
ALTER TABLE `conversation_item`
MODIFY `id` int(11) unsigned NOT NULL AUTO_INCREMENT;
--
-- AUTO_INCREMENT for table `currency`
--
ALTER TABLE `currency`
MODIFY `id` int(11) unsigned NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=6;
--
-- AUTO_INCREMENT for table `currencyvalue`
--
ALTER TABLE `currencyvalue`
MODIFY `id` int(11) unsigned NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=586;
--
-- AUTO_INCREMENT for table `customfield`
--
ALTER TABLE `customfield`
MODIFY `id` int(11) unsigned NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=529;
--
-- AUTO_INCREMENT for table `customfielddata`
--
ALTER TABLE `customfielddata`
MODIFY `id` int(11) unsigned NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=18;
--
-- AUTO_INCREMENT for table `customfieldvalue`
--
ALTER TABLE `customfieldvalue`
MODIFY `id` int(11) unsigned NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=24;
--
-- AUTO_INCREMENT for table `dashboard`
--
ALTER TABLE `dashboard`
MODIFY `id` int(11) unsigned NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=2;
--
-- AUTO_INCREMENT for table `derivedattributemetadata`
--
ALTER TABLE `derivedattributemetadata`
MODIFY `id` int(11) unsigned NOT NULL AUTO_INCREMENT;
--
-- AUTO_INCREMENT for table `dropdowndependencyderivedattributemetadata`
--
ALTER TABLE `dropdowndependencyderivedattributemetadata`
MODIFY `id` int(11) unsigned NOT NULL AUTO_INCREMENT;
--
-- AUTO_INCREMENT for table `email`
--
ALTER TABLE `email`
MODIFY `id` int(11) unsigned NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=45;
--
-- AUTO_INCREMENT for table `emailaccount`
--
ALTER TABLE `emailaccount`
MODIFY `id` int(11) unsigned NOT NULL AUTO_INCREMENT;
--
-- AUTO_INCREMENT for table `emailbox`
--
ALTER TABLE `emailbox`
MODIFY `id` int(11) unsigned NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=4;
--
-- AUTO_INCREMENT for table `emailfolder`
--
ALTER TABLE `emailfolder`
MODIFY `id` int(11) unsigned NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=18;
--
-- AUTO_INCREMENT for table `emailmessage`
--
ALTER TABLE `emailmessage`
MODIFY `id` int(11) unsigned NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=38;
--
-- AUTO_INCREMENT for table `emailmessageactivity`
--
ALTER TABLE `emailmessageactivity`
MODIFY `id` int(11) unsigned NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=40;
--
-- AUTO_INCREMENT for table `emailmessagecontent`
--
ALTER TABLE `emailmessagecontent`
MODIFY `id` int(11) unsigned NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=38;
--
-- AUTO_INCREMENT for table `emailmessagerecipient`
--
ALTER TABLE `emailmessagerecipient`
MODIFY `id` int(11) unsigned NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=38;
--
-- AUTO_INCREMENT for table `emailmessagerecipient_item`
--
ALTER TABLE `emailmessagerecipient_item`
MODIFY `id` int(11) unsigned NOT NULL AUTO_INCREMENT;
--
-- AUTO_INCREMENT for table `emailmessagesender`
--
ALTER TABLE `emailmessagesender`
MODIFY `id` int(11) unsigned NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=38;
--
-- AUTO_INCREMENT for table `emailmessagesenderror`
--
ALTER TABLE `emailmessagesenderror`
MODIFY `id` int(11) unsigned NOT NULL AUTO_INCREMENT;
--
-- AUTO_INCREMENT for table `emailmessagesender_item`
--
ALTER TABLE `emailmessagesender_item`
MODIFY `id` int(11) unsigned NOT NULL AUTO_INCREMENT;
--
-- AUTO_INCREMENT for table `emailmessageurl`
--
ALTER TABLE `emailmessageurl`
MODIFY `id` int(11) unsigned NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=20;
--
-- AUTO_INCREMENT for table `emailsignature`
--
ALTER TABLE `emailsignature`
MODIFY `id` int(11) unsigned NOT NULL AUTO_INCREMENT;
--
-- AUTO_INCREMENT for table `emailtemplate`
--
ALTER TABLE `emailtemplate`
MODIFY `id` int(11) unsigned NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=14;
--
-- AUTO_INCREMENT for table `exportfilemodel`
--
ALTER TABLE `exportfilemodel`
MODIFY `id` int(11) unsigned NOT NULL AUTO_INCREMENT;
--
-- AUTO_INCREMENT for table `exportitem`
--
ALTER TABLE `exportitem`
MODIFY `id` int(11) unsigned NOT NULL AUTO_INCREMENT;
--
-- AUTO_INCREMENT for table `exportitem_read`
--
ALTER TABLE `exportitem_read`
MODIFY `id` int(11) unsigned NOT NULL AUTO_INCREMENT;
--
-- AUTO_INCREMENT for table `filecontent`
--
ALTER TABLE `filecontent`
MODIFY `id` int(11) unsigned NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=3;
--
-- AUTO_INCREMENT for table `filemodel`
--
ALTER TABLE `filemodel`
MODIFY `id` int(11) unsigned NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=3;
--
-- AUTO_INCREMENT for table `gamebadge`
--
ALTER TABLE `gamebadge`
MODIFY `id` int(11) unsigned NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=33;
--
-- AUTO_INCREMENT for table `gamecoin`
--
ALTER TABLE `gamecoin`
MODIFY `id` int(11) unsigned NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=2;
--
-- AUTO_INCREMENT for table `gamecollection`
--
ALTER TABLE `gamecollection`
MODIFY `id` int(11) unsigned NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=32;
--
-- AUTO_INCREMENT for table `gamelevel`
--
ALTER TABLE `gamelevel`
MODIFY `id` int(11) unsigned NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=22;
--
-- AUTO_INCREMENT for table `gamenotification`
--
ALTER TABLE `gamenotification`
MODIFY `id` int(11) unsigned NOT NULL AUTO_INCREMENT;
--
-- AUTO_INCREMENT for table `gamepoint`
--
ALTER TABLE `gamepoint`
MODIFY `id` int(11) unsigned NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=24;
--
-- AUTO_INCREMENT for table `gamepointtransaction`
--
ALTER TABLE `gamepointtransaction`
MODIFY `id` int(11) unsigned NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=227;
--
-- AUTO_INCREMENT for table `gamereward`
--
ALTER TABLE `gamereward`
MODIFY `id` int(11) unsigned NOT NULL AUTO_INCREMENT;
--
-- AUTO_INCREMENT for table `gamerewardtransaction`
--
ALTER TABLE `gamerewardtransaction`
MODIFY `id` int(11) unsigned NOT NULL AUTO_INCREMENT;
--
-- AUTO_INCREMENT for table `gamereward_read`
--
ALTER TABLE `gamereward_read`
MODIFY `id` int(11) unsigned NOT NULL AUTO_INCREMENT;
--
-- AUTO_INCREMENT for table `gamescore`
--
ALTER TABLE `gamescore`
MODIFY `id` int(11) unsigned NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=43;
--
-- AUTO_INCREMENT for table `globalmetadata`
--
ALTER TABLE `globalmetadata`
MODIFY `id` int(11) unsigned NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=22;
--
-- AUTO_INCREMENT for table `imagefilemodel`
--
ALTER TABLE `imagefilemodel`
MODIFY `id` int(11) unsigned NOT NULL AUTO_INCREMENT;
--
-- AUTO_INCREMENT for table `import`
--
ALTER TABLE `import`
MODIFY `id` int(11) unsigned NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=5;
--
-- AUTO_INCREMENT for table `importtable1`
--
ALTER TABLE `importtable1`
MODIFY `id` int(11) unsigned NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=60;
--
-- AUTO_INCREMENT for table `importtable2`
--
ALTER TABLE `importtable2`
MODIFY `id` int(11) unsigned NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=61;
--
-- AUTO_INCREMENT for table `importtable3`
--
ALTER TABLE `importtable3`
MODIFY `id` int(11) unsigned NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=62;
--
-- AUTO_INCREMENT for table `importtable4`
--
ALTER TABLE `importtable4`
MODIFY `id` int(11) unsigned NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=60;
--
-- AUTO_INCREMENT for table `item`
--
ALTER TABLE `item`
MODIFY `id` int(11) unsigned NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=862;
--
-- AUTO_INCREMENT for table `jobinprocess`
--
ALTER TABLE `jobinprocess`
MODIFY `id` int(11) unsigned NOT NULL AUTO_INCREMENT;
--
-- AUTO_INCREMENT for table `joblog`
--
ALTER TABLE `joblog`
MODIFY `id` int(11) unsigned NOT NULL AUTO_INCREMENT;
--
-- AUTO_INCREMENT for table `kanbanitem`
--
ALTER TABLE `kanbanitem`
MODIFY `id` int(11) unsigned NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=5;
--
-- AUTO_INCREMENT for table `marketinglist`
--
ALTER TABLE `marketinglist`
MODIFY `id` int(11) unsigned NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=7;
--
-- AUTO_INCREMENT for table `marketinglistmember`
--
ALTER TABLE `marketinglistmember`
MODIFY `id` int(11) unsigned NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=62;
--
-- AUTO_INCREMENT for table `meeting`
--
ALTER TABLE `meeting`
MODIFY `id` int(11) unsigned NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=39;
--
-- AUTO_INCREMENT for table `meeting_read_subscription`
--
ALTER TABLE `meeting_read_subscription`
MODIFY `id` int(11) unsigned NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=2;
--
-- AUTO_INCREMENT for table `messagesource`
--
ALTER TABLE `messagesource`
MODIFY `id` int(11) unsigned NOT NULL AUTO_INCREMENT;
--
-- AUTO_INCREMENT for table `messagetranslation`
--
ALTER TABLE `messagetranslation`
MODIFY `id` int(11) unsigned NOT NULL AUTO_INCREMENT;
--
-- AUTO_INCREMENT for table `mission`
--
ALTER TABLE `mission`
MODIFY `id` int(11) unsigned NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=6;
--
-- AUTO_INCREMENT for table `modelcreationapisync`
--
ALTER TABLE `modelcreationapisync`
MODIFY `id` int(11) unsigned NOT NULL AUTO_INCREMENT;
--
-- AUTO_INCREMENT for table `multiplevaluescustomfield`
--
ALTER TABLE `multiplevaluescustomfield`
MODIFY `id` int(11) unsigned NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=10;
--
-- AUTO_INCREMENT for table `namedsecurableitem`
--
ALTER TABLE `namedsecurableitem`
MODIFY `id` int(11) unsigned NOT NULL AUTO_INCREMENT;
--
-- AUTO_INCREMENT for table `note`
--
ALTER TABLE `note`
MODIFY `id` int(11) unsigned NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=26;
--
-- AUTO_INCREMENT for table `notification`
--
ALTER TABLE `notification`
MODIFY `id` int(11) unsigned NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=4;
--
-- AUTO_INCREMENT for table `notificationmessage`
--
ALTER TABLE `notificationmessage`
MODIFY `id` int(11) unsigned NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=4;
--
-- AUTO_INCREMENT for table `notificationsubscriber`
--
ALTER TABLE `notificationsubscriber`
MODIFY `id` int(11) unsigned NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=3;
--
-- AUTO_INCREMENT for table `opportunity`
--
ALTER TABLE `opportunity`
MODIFY `id` int(11) unsigned NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=80;
--
-- AUTO_INCREMENT for table `opportunitystarred`
--
ALTER TABLE `opportunitystarred`
MODIFY `id` int(11) unsigned NOT NULL AUTO_INCREMENT;
--
-- AUTO_INCREMENT for table `opportunity_project`
--
ALTER TABLE `opportunity_project`
MODIFY `id` int(11) unsigned NOT NULL AUTO_INCREMENT;
--
-- AUTO_INCREMENT for table `ownedsecurableitem`
--
ALTER TABLE `ownedsecurableitem`
MODIFY `id` int(11) unsigned NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=510;
--
-- AUTO_INCREMENT for table `permission`
--
ALTER TABLE `permission`
MODIFY `id` int(11) unsigned NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=142;
--
-- AUTO_INCREMENT for table `permitable`
--
ALTER TABLE `permitable`
MODIFY `id` int(11) unsigned NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=21;
--
-- AUTO_INCREMENT for table `person`
--
ALTER TABLE `person`
MODIFY `id` int(11) unsigned NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=43;
--
-- AUTO_INCREMENT for table `personwhohavenotreadlatest`
--
ALTER TABLE `personwhohavenotreadlatest`
MODIFY `id` int(11) unsigned NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=39;
--
-- AUTO_INCREMENT for table `perusermetadata`
--
ALTER TABLE `perusermetadata`
MODIFY `id` int(11) unsigned NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=13;
--
-- AUTO_INCREMENT for table `policy`
--
ALTER TABLE `policy`
MODIFY `id` int(11) unsigned NOT NULL AUTO_INCREMENT;
--
-- AUTO_INCREMENT for table `portlet`
--
ALTER TABLE `portlet`
MODIFY `id` int(11) unsigned NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=52;
--
-- AUTO_INCREMENT for table `product`
--
ALTER TABLE `product`
MODIFY `id` int(11) unsigned NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=61;
--
-- AUTO_INCREMENT for table `productcatalog`
--
ALTER TABLE `productcatalog`
MODIFY `id` int(11) unsigned NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=3;
--
-- AUTO_INCREMENT for table `productcatalog_productcategory`
--
ALTER TABLE `productcatalog_productcategory`
MODIFY `id` int(11) unsigned NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=9;
--
-- AUTO_INCREMENT for table `productcategory`
--
ALTER TABLE `productcategory`
MODIFY `id` int(11) unsigned NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=8;
--
-- AUTO_INCREMENT for table `productcategory_producttemplate`
--
ALTER TABLE `productcategory_producttemplate`
MODIFY `id` int(11) unsigned NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=35;
--
-- AUTO_INCREMENT for table `producttemplate`
--
ALTER TABLE `producttemplate`
MODIFY `id` int(11) unsigned NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=34;
--
-- AUTO_INCREMENT for table `product_productcategory`
--
ALTER TABLE `product_productcategory`
MODIFY `id` int(11) unsigned NOT NULL AUTO_INCREMENT;
--
-- AUTO_INCREMENT for table `project`
--
ALTER TABLE `project`
MODIFY `id` int(11) unsigned NOT NULL AUTO_INCREMENT;
--
-- AUTO_INCREMENT for table `projectauditevent`
--
ALTER TABLE `projectauditevent`
MODIFY `id` int(11) unsigned NOT NULL AUTO_INCREMENT;
--
-- AUTO_INCREMENT for table `project_read`
--
ALTER TABLE `project_read`
MODIFY `id` int(11) unsigned NOT NULL AUTO_INCREMENT;
--
-- AUTO_INCREMENT for table `role`
--
ALTER TABLE `role`
MODIFY `id` int(11) unsigned NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=5;
--
-- AUTO_INCREMENT for table `savedcalendar`
--
ALTER TABLE `savedcalendar`
MODIFY `id` int(11) unsigned NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=3;
--
-- AUTO_INCREMENT for table `savedcalendarsubscription`
--
ALTER TABLE `savedcalendarsubscription`
MODIFY `id` int(11) unsigned NOT NULL AUTO_INCREMENT;
--
-- AUTO_INCREMENT for table `savedcalendar_read`
--
ALTER TABLE `savedcalendar_read`
MODIFY `id` int(11) unsigned NOT NULL AUTO_INCREMENT;
--
-- AUTO_INCREMENT for table `savedreport`
--
ALTER TABLE `savedreport`
MODIFY `id` int(11) unsigned NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=7;
--
-- AUTO_INCREMENT for table `savedsearch`
--
ALTER TABLE `savedsearch`
MODIFY `id` int(11) unsigned NOT NULL AUTO_INCREMENT;
--
-- AUTO_INCREMENT for table `savedworkflow`
--
ALTER TABLE `savedworkflow`
MODIFY `id` int(11) unsigned NOT NULL AUTO_INCREMENT;
--
-- AUTO_INCREMENT for table `securableitem`
--
ALTER TABLE `securableitem`
MODIFY `id` int(11) unsigned NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=511;
--
-- AUTO_INCREMENT for table `sellpriceformula`
--
ALTER TABLE `sellpriceformula`
MODIFY `id` int(11) unsigned NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=34;
--
-- AUTO_INCREMENT for table `shorturl`
--
ALTER TABLE `shorturl`
MODIFY `id` int(11) unsigned NOT NULL AUTO_INCREMENT;
--
-- AUTO_INCREMENT for table `socialitem`
--
ALTER TABLE `socialitem`
MODIFY `id` int(11) unsigned NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=19;
--
-- AUTO_INCREMENT for table `stuckjob`
--
ALTER TABLE `stuckjob`
MODIFY `id` int(11) unsigned NOT NULL AUTO_INCREMENT;
--
-- AUTO_INCREMENT for table `task`
--
ALTER TABLE `task`
MODIFY `id` int(11) unsigned NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=22;
--
-- AUTO_INCREMENT for table `taskchecklistitem`
--
ALTER TABLE `taskchecklistitem`
MODIFY `id` int(11) unsigned NOT NULL AUTO_INCREMENT;
--
-- AUTO_INCREMENT for table `task_read_subscription`
--
ALTER TABLE `task_read_subscription`
MODIFY `id` int(11) unsigned NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=3;
--
-- AUTO_INCREMENT for table `workflowmessageinqueue`
--
ALTER TABLE `workflowmessageinqueue`
MODIFY `id` int(11) unsigned NOT NULL AUTO_INCREMENT;
--
-- AUTO_INCREMENT for table `_group`
--
ALTER TABLE `_group`
MODIFY `id` int(11) unsigned NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=10;
--
-- AUTO_INCREMENT for table `_group__user`
--
ALTER TABLE `_group__user`
MODIFY `id` int(11) unsigned NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=3;
--
-- AUTO_INCREMENT for table `_right`
--
ALTER TABLE `_right`
MODIFY `id` int(11) unsigned NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=63;
--
-- AUTO_INCREMENT for table `_user`
--
ALTER TABLE `_user`
MODIFY `id` int(11) unsigned NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=12;
--
-- AUTO_INCREMENT for table `_user_meeting`
--
ALTER TABLE `_user_meeting`
MODIFY `id` int(11) unsigned NOT NULL AUTO_INCREMENT;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
