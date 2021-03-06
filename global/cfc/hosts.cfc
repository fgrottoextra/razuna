<!---
*
* Copyright (C) 2005-2008 Razuna
*
* This file is part of Razuna - Enterprise Digital Asset Management.
*
* Razuna is free software: you can redistribute it and/or modify
* it under the terms of the GNU Affero Public License as published by
* the Free Software Foundation, either version 3 of the License, or
* (at your option) any later version.
*
* Razuna is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
* GNU Affero Public License for more details.
*
* You should have received a copy of the GNU Affero Public License
* along with Razuna. If not, see <http://www.gnu.org/licenses/>.
*
* You may restribute this Program with a special exception to the terms
* and conditions of version 3.0 of the AGPL as described in Razuna's
* FLOSS exception. You should have received a copy of the FLOSS exception
* along with Razuna. If not, see <http://www.razuna.com/licenses/>.
*
--->
<cfcomponent  output="false" extends="extQueryCaching">

<cffunction name="init" returntype="hosts" access="public" output="false">
	<cfreturn this />
</cffunction>

<!--- FUNCTION: This is called from the first time setup --->
<cffunction name="setupdb" access="public" output="false">
	<cfargument name="thestruct" type="Struct">
	<!--- Setup database --->
	<cfinvoke component="db_#arguments.thestruct.database#" method="setup" thestruct="#arguments.thestruct#">
	<!--- Create tables --->
	<cfinvoke component="db_#arguments.thestruct.database#" method="create_host" thestruct="#arguments.thestruct#">
	<!--- Add Host --->
	<cfinvoke method="add" thestruct="#arguments.thestruct#">
	<!--- Return --->
	<cfreturn />
</cffunction>

<!--- FUNCTION: CHECK FOR SAME NAME --->
<cffunction name="checkname" access="public" output="false">
	<cfargument name="thestruct" type="Struct">
	<cfset var qry = "">
	<cfquery datasource="#arguments.thestruct.razuna.application.datasource#" name="qry">
	SELECT host_name
	FROM hosts
	WHERE
	<cfif structkeyexists(arguments.thestruct, "host_name")>
		host_name = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.thestruct.host_name#">
	<cfelseif structkeyexists(arguments.thestruct, "host_path")>
		host_path = <cfqueryparam value="#arguments.thestruct.host_path#" cfsqltype="cf_sql_varchar">
	<cfelseif structkeyexists(arguments.thestruct, "host_db_prefix")>
		host_db_prefix = <cfqueryparam value="#arguments.thestruct.host_db_prefix#_" cfsqltype="cf_sql_varchar">
	</cfif>
	</cfquery>
	<cfreturn qry>
</cffunction>

<!--- FUNCTION: Add Host --->
<cffunction  name="add" access="public" output="false">
	<cfargument name="thestruct" type="Struct">
	<!--- Check for the same name --->
	<cfquery datasource="#arguments.thestruct.razuna.application.datasource#" name="same">
	SELECT host_name
	FROM hosts
	WHERE host_name = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.thestruct.host_name#">
	</cfquery>
	<!--- No record with the same name exist thus add it else throw an error --->
	<cfif same.recordcount EQ 0>
		<cftransaction>
			<cfquery datasource="#arguments.thestruct.razuna.application.datasource#" name="hostid">
			SELECT <cfif arguments.thestruct.razuna.application.thedatabase EQ "oracle" OR arguments.thestruct.razuna.application.thedatabase EQ "h2" OR arguments.thestruct.razuna.application.thedatabase EQ "db2">NVL<cfelseif arguments.thestruct.razuna.application.thedatabase EQ "mysql">ifnull<cfelseif arguments.thestruct.razuna.application.thedatabase EQ "mssql">isnull</cfif>(max(host_id),0) + 1 AS id
			FROM hosts
			</cfquery>
			<cfquery datasource="#arguments.thestruct.razuna.application.datasource#">
			INSERT INTO hosts
			(host_id)
			VALUES(<cfqueryparam value="#hostid.id#" cfsqltype="cf_sql_numeric">)
			</cfquery>
		</cftransaction>
		<!--- Set host_db_prefix & host_path--->
		<cfset arguments.thestruct.host_path = "raz" & hostid.id>
		<cfset arguments.thestruct.host_db_prefix = "raz1_">
		<cfset arguments.thestruct.host_id = hostid.id>
		<!--- Set session for the user --->
		<cfset arguments.thestruct.razuna.session.hostid = hostid.id>
		<cfset arguments.thestruct.razuna.session.hostdbprefix = arguments.thestruct.host_db_prefix>
		<cfparam name="arguments.thestruct.host_name_custom" default="" />
		<!--- NIRVANIX --->
		<!--- <cfif arguments.thestruct.razuna.application.storage EQ "nirvanix" AND NOT structkeyexists(arguments.thestruct,"restore")>
			<!--- Create a random password --->
			<cfset var passrand = createuuid()>
			<!--- Get master account --->
			<cfinvoke component="settings" method="getconfig" thenode="nirvanix_master_name" returnvariable="attributes.qry_settings_nirvanix.set2_nirvanix_name">
			<cfinvoke component="settings" method="getconfig" thenode="nirvanix_master_pass" returnvariable="attributes.qry_settings_nirvanix.set2_nirvanix_pass">
			<!--- Get session token --->
			<cfinvoke component="nirvanix" method="login" thestruct="#attributes#" returnvariable="variables.nvxsession" />
			<!--- Create Child Account --->
			<cfinvoke component="nirvanix" method="CreateChildAccount">
				<cfinvokeargument name="nvxsession" value="#variables.nvxsession#">
				<cfinvokeargument name="username" value="#hostid.id#">
				<cfinvokeargument name="password" value="#passrand#">
			</cfinvoke>
		</cfif> --->
		<cftransaction>
			<!--- Insert into Host db --->
			<cfquery datasource="#arguments.thestruct.razuna.application.datasource#">
			UPDATE hosts
			SET
			host_name = <cfqueryparam value="#arguments.thestruct.host_name#" cfsqltype="cf_sql_varchar">,
			host_path = <cfqueryparam value="#arguments.thestruct.host_path#" cfsqltype="cf_sql_varchar">,
			host_create_date = <cfqueryparam value="#now()#" cfsqltype="cf_sql_date">,
			host_db_prefix = <cfqueryparam value="#arguments.thestruct.host_db_prefix#" cfsqltype="cf_sql_varchar">,
			host_shard_group = <cfqueryparam value="#arguments.thestruct.host_db_prefix#" cfsqltype="cf_sql_varchar">,
			host_name_custom = <cfqueryparam value="#arguments.thestruct.host_name_custom#" cfsqltype="cf_sql_varchar">
			WHERE host_id = <cfqueryparam value="#hostid.id#" cfsqltype="cf_sql_numeric">
			</cfquery>
		</cftransaction>
			<cfif structkeyexists(arguments.thestruct,"from_first_time")>
				<!--- <cfinvoke component="global" method="getsequence" returnvariable="userid" database="#arguments.thestruct.razuna.application.thedatabase#" dsn="#arguments.thestruct.razuna.application.datasource#" thetable="users" theid="user_id"> --->
				<!--- Hash Password --->
				<cfset thepass = hash(arguments.thestruct.user_pass, "MD5", "UTF-8")>
				<!--- Insert the User into the DB --->
				<cfset newuserid = createuuid()>
				<cfquery datasource="#arguments.thestruct.razuna.application.datasource#">
				INSERT INTO users
				(user_id, user_login_name, user_email, user_pass, user_first_name, user_last_name, user_in_admin, user_create_date, user_active, user_in_dam)
				VALUES(
				<cfqueryparam value="#newuserid#" cfsqltype="CF_SQL_VARCHAR">,
				<cfqueryparam value="#arguments.thestruct.user_login_name#" cfsqltype="cf_sql_varchar">,
				<cfqueryparam value="#arguments.thestruct.user_email#" cfsqltype="cf_sql_varchar">,
				<cfqueryparam value="#thepass#" cfsqltype="cf_sql_varchar">,
				<cfqueryparam value="#arguments.thestruct.user_first_name#" cfsqltype="cf_sql_varchar">,
				<cfqueryparam value="#arguments.thestruct.user_last_name#" cfsqltype="cf_sql_varchar">,
				<cfqueryparam value="T" cfsqltype="cf_sql_varchar">,
				<cfqueryparam value="#now()#" cfsqltype="cf_sql_date">,
				<cfqueryparam value="T" cfsqltype="cf_sql_varchar">,
				<cfqueryparam value="T" cfsqltype="cf_sql_varchar">
				)
				</cfquery>
				<!--- Insert the user as systemadmin to the cross table --->
				<cfquery datasource="#arguments.thestruct.razuna.application.datasource#">
				INSERT INTO ct_groups_users
				(ct_g_u_user_id, ct_g_u_grp_id, rec_uuid)
				VALUES(
				<cfqueryparam value="#newuserid#" cfsqltype="CF_SQL_VARCHAR">,
				<cfqueryparam value="1" cfsqltype="CF_SQL_VARCHAR">,
				<cfqueryparam value="#createuuid()#" cfsqltype="CF_SQL_VARCHAR">
				)
				</cfquery>
			</cfif>
			<!--- COPY NEWHOST DIR --->
			<cfif !arguments.thestruct.razuna.application.isp>
				<cfinvoke component="global" method="directoryCopy">
					<cfinvokeargument name="source" value="#arguments.thestruct.pathhere#/newhost/hostfiles">
					<cfinvokeargument name="destination" value="#arguments.thestruct.pathoneup#/#arguments.thestruct.host_path#">
					<cfinvokeargument name="directoryrecursive" value="true">
				</cfinvoke>
			</cfif>
			<!--- ADD THE SYSTEMADMIN TO THE CROSS TABLE FOR THE HOSTS --->
			<cfinvoke component="global.cfc.groups_users" method="searchUsersOfGroups" returnvariable="theadmins" list_grp_name="SystemAdmin" host_id="0" thestruct="#arguments.thestruct#">
			<cfoutput query="theadmins">
				<cfquery datasource="#arguments.thestruct.razuna.application.datasource#">
				insert into ct_users_hosts
				(ct_u_h_user_id, ct_u_h_host_id, rec_uuid)
				values(
				<cfqueryparam value="#user_id#" cfsqltype="CF_SQL_VARCHAR">,
				<cfqueryparam value="#hostid.id#" cfsqltype="cf_sql_numeric">,
				<cfqueryparam value="#createuuid()#" CFSQLType="CF_SQL_VARCHAR">
				)
				</cfquery>
			</cfoutput>
			<!--- INSERT DEFAULT VALUES --->
			<cfinvoke method="insert_default_values" thestruct="#arguments.thestruct#">
			<!--- Create the fusebox files --->
			<cfif !arguments.thestruct.razuna.application.isp>
				<cfinvoke method="newHostCreateApp">
					<cfinvokeargument name="module_folder" value="dam">
					<cfinvokeargument name="thisid" value="#hostid.id#">
					<cfinvokeargument name="host_path_replace" value="#arguments.thestruct.host_path#">
					<cfinvokeargument name="host_db_prefix_replace" value="#arguments.thestruct.host_db_prefix#">
					<cfinvokeargument name="pathoneup" value="#arguments.thestruct.pathoneup#">
				</cfinvoke>
			</cfif>
			<!--- <cfinvoke method="newHostCreateApp">
				<cfinvokeargument name="module_folder" value="web">
				<cfinvokeargument name="thisid" value="#hostid.id#">
				<cfinvokeargument name="host_path_replace" value="#arguments.thestruct.host_path#">
				<cfinvokeargument name="host_db_prefix_replace" value="#arguments.thestruct.host_db_prefix#">
				<cfinvokeargument name="pathoneup" value="#arguments.thestruct.pathoneup#">
			</cfinvoke> --->
			<cfset var taskpath =  "#arguments.thestruct.razuna.session.thehttp##cgi.http_host##cgi.context_path#/admin">
			<!--- Save Folder Subscribe scheduled event in CFML scheduling engine --->
			<cfschedule action="update"
				task="RazFolderSubscribe"
				operation="HTTPRequest"
				url="#taskpath#/index.cfm?fa=c.folder_subscribe_task"
				startDate="#LSDateFormat(Now(), 'mm/dd/yyyy')#"
				startTime="00:01 AM"
				endTime="23:59 PM"
				interval="3600"
			>
			<!--- RAZ-549 As a user I want to share a file URL with an expiration date --->
			<!--- <cfschedule action="update"
				task="RazAssetExpiry"
				operation="HTTPRequest"
				url="#taskpath#/index.cfm?fa=c.w_asset_expiry_task"
				startDate="#LSDateFormat(Now(), 'mm/dd/yyyy')#"
				startTime="00:01 AM"
				endTime="23:59 PM"
				interval="300"
			> --->
			<!--- Save FTP Task in CFML scheduling engine --->
			<!--- <cfschedule action="update"
				task="RazFTPNotifications"
				operation="HTTPRequest"
				url="#taskpath#/index.cfm?fa=c.w_ftp_notifications_task"
				startDate="#LSDateFormat(Now(), 'mm/dd/yyyy')#"
				startTime="00:01 AM"
				endTime="23:59 PM"
				interval="3600"
			> --->
			<!--- Write dummy record (this fixes issues with collection not written to lucene!!!) --->
			<!--- <cftry>
				<!--- Create collection --->
				<cfset CollectionCreate(collection=hostid.id,relative=true,path="/WEB-INF/collections/#hostid.id#")>
				<cfset CollectionIndexcustom( collection=#hostid.id#, key="delete", body="#createuuid()#", title="#createuuid()#")>
				<cfcatch type="any"></cfcatch>
			</cftry> --->
			<!--- Insert label for asset expiry --->
			<cfquery datasource="#arguments.thestruct.razuna.application.datasource#">
			INSERT INTO #arguments.thestruct.host_db_prefix#labels (label_id,label_text, label_date,user_id,host_id,label_id_r,label_path)
			VALUES  (<cfqueryparam CFSQLType="CF_SQL_VARCHAR" value="#createuuid()#">,
					<cfqueryparam CFSQLType="CF_SQL_VARCHAR" value="Asset has expired">,
					<cfqueryparam CFSQLType="CF_SQL_TIMESTAMP" value="#now()#">,
					<cfqueryparam CFSQLType="CF_SQL_VARCHAR" value="1">,
					<cfqueryparam CFSQLType="CF_SQL_NUMERIC" value="#hostid.id#">,
					<cfqueryparam CFSQLType="CF_SQL_VARCHAR" value="0">,
					<cfqueryparam CFSQLType="CF_SQL_VARCHAR" value="Asset has expired">
					)
			</cfquery>
		<!--- Flush Cache --->
		<cfset resetcachetoken(type="general", hostid=arguments.thestruct.razuna.session.hostid, thestruct=arguments.thestruct)>
		<cfset resetcachetoken(type="users", hostid=arguments.thestruct.razuna.session.hostid, thestruct=arguments.thestruct)>
	</cfif>
	<cfreturn  />
</cffunction>

<!--- ------------------------------------------------------------------------------------- --->
<!--- Insert Default Values --->
<cffunction name="insert_default_values" access="public" output="false">
	<cfargument name="thestruct" type="Struct">
	<cftry>
		<!--- Param --->
		<cfparam default="" name="arguments.thestruct.oracle_url">
		<cfparam default="" name="arguments.thestruct.path_assets">
		<cfparam default="1_English" name="arguments.thestruct.langs_selected">
		<cfparam default="razuna@razuna.com" name="arguments.thestruct.email_from">
		<!--- Now add selected languages --->
		<cfloop list="#arguments.thestruct.langs_selected#" delimiters="," index="x">
			<!--- Grab lang name --->
			<cfset langname = listlast(x,"_")>
			<!--- Grab ID --->
			<cfset langid = listfirst(x,"_")>
			<!--- Insert --->
			<cfquery datasource="#arguments.thestruct.razuna.application.datasource#">
			INSERT INTO #arguments.thestruct.host_db_prefix#languages
			(lang_id, lang_name, lang_active, host_id, rec_uuid)
			VALUES(
			<cfqueryparam value="#langid#" cfsqltype="cf_sql_numeric">,
			<cfqueryparam value="#langname#" cfsqltype="cf_sql_varchar">,
			<cfqueryparam value="t" cfsqltype="cf_sql_varchar">,
			<cfqueryparam value="#arguments.thestruct.host_id#" cfsqltype="cf_sql_numeric">,
			<cfqueryparam value="#createuuid()#" CFSQLType="CF_SQL_VARCHAR">
			)
			</cfquery>
			<!--- Setting DB: Titel Intra --->
			<cfset thelang = "arguments.thestruct.set_title_intra_" & x>
			<cfset thelang = replacenocase("#thelang#","arguments.thestruct.","","ALL")>
			<cfquery datasource="#arguments.thestruct.razuna.application.datasource#">
			INSERT INTO #arguments.thestruct.host_db_prefix#settings
			(set_id, set_pref, host_id, rec_uuid)
			VALUES(
			<cfqueryparam value="#ucase(thelang)#" cfsqltype="cf_sql_varchar">,
			<cfqueryparam value="Razuna - Enterprise Digital Asset Management (DAM)" cfsqltype="cf_sql_varchar">,
			<cfqueryparam value="#arguments.thestruct.host_id#" cfsqltype="cf_sql_numeric">,
			<cfqueryparam value="#createuuid()#" CFSQLType="CF_SQL_VARCHAR">
			)
			</cfquery>
		</cfloop>
		<!--- SETTING 2 --->
		<cfquery datasource="#arguments.thestruct.razuna.application.datasource#">
		insert into #arguments.thestruct.host_db_prefix#settings_2
		(set2_id,
		set2_date_format,
		set2_date_format_del,
		set2_meta_author,
		set2_meta_publisher,
		set2_meta_copyright,
		set2_meta_robots,
		set2_meta_revisit,
		set2_create_imgfolders_where,
		set2_img_format,
		set2_img_thumb_width,
		set2_img_thumb_heigth,
		set2_img_comp_width,
		set2_img_comp_heigth,
		set2_img_download_org,
		set2_doc_download,
		set2_intranet_gen_download,
		set2_cat_web,
		set2_cat_intra,
		set2_url_website,
		set2_payment_pre,
		set2_payment_bill,
		set2_payment_pod,
		set2_payment_cc,
		set2_payment_cc_cards,
		set2_payment_paypal,
		set2_vid_preview_heigth,
		set2_vid_preview_width,
		set2_vid_preview_time,
		set2_vid_preview_start,
		set2_vid_preview_author,
		set2_cat_vid_web,
		set2_cat_vid_intra,
		set2_cat_aud_web,
		set2_cat_aud_intra,
		set2_create_vidfolders_where,
		set2_email_from,
		set2_path_to_assets,
		host_id,
		rec_uuid
		)
		Values
		(1,
		'euro',
		'/',
		'razuna.com',
		'razuna.com',
		'razuna.com',
		'all',
		'7 days',
		'0',
		'jpg',
		'400',
		'400',
		'350',
		'350',
		'T',
		'T',
		'F',
		'T',
		'T',
		'',
		'T',
		'T',
		'T',
		'F',
		'Visa,Mastercard,American Express',
		'F',
		124,
		250,
		'00:00:20',
		'00:00:03',
		'Razuna',
		'T',
		'T',
		'F',
		'F',
		0,
		<cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.thestruct.email_from#">,
		<cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.thestruct.path_assets#">,
		<cfqueryparam value="#arguments.thestruct.host_id#" cfsqltype="cf_sql_numeric">,
		<cfqueryparam value="#createuuid()#" CFSQLType="CF_SQL_VARCHAR">
		)
		</cfquery>
		<!--- Create a new ID --->
		<cfset var newfolderid = createuuid("")>
		<!--- Create the default Collections Folder --->
		<cfquery datasource="#arguments.thestruct.razuna.application.datasource#">
		Insert into #arguments.thestruct.host_db_prefix#folders
		(FOLDER_ID, FOLDER_NAME, FOLDER_LEVEL, FOLDER_ID_R, FOLDER_MAIN_ID_R, FOLDER_IS_COLLECTION, host_id)
		Values('#newfolderid#', 'Collections', 1, '#newfolderid#', '#newfolderid#', 'T', #arguments.thestruct.host_id#)
		</cfquery>
		<!--- and description with it --->
		<cfquery datasource="#arguments.thestruct.razuna.application.datasource#">
		Insert into #arguments.thestruct.host_db_prefix#folders_desc
		(FOLDER_ID_R, LANG_ID_R, FOLDER_DESC, host_id, rec_uuid)
		Values('#newfolderid#', 1, 'This is the default collections folder for storing collections.', #arguments.thestruct.host_id#, <cfqueryparam value="#createuuid()#" CFSQLType="CF_SQL_VARCHAR">)
		</cfquery>
		<!--- INTO CACHE --->
		<cfquery dataSource="#arguments.thestruct.razuna.application.datasource#">
		INSERT INTO cache
		(host_id, cache_token, cache_type)
		VALUES
		(<cfqueryparam value="#arguments.thestruct.host_id#" CFSQLType="CF_SQL_NUMERIC">, <cfqueryparam value="#newfolderid#" CFSQLType="CF_SQL_VARCHAR">, <cfqueryparam value="folders" CFSQLType="CF_SQL_VARCHAR">)
		</cfquery>
		<cfquery dataSource="#arguments.thestruct.razuna.application.datasource#">
		INSERT INTO cache
		(host_id, cache_token, cache_type)
		VALUES
		(<cfqueryparam value="#arguments.thestruct.host_id#" CFSQLType="CF_SQL_NUMERIC">, <cfqueryparam value="#newfolderid#" CFSQLType="CF_SQL_VARCHAR">, <cfqueryparam value="images" CFSQLType="CF_SQL_VARCHAR">)
		</cfquery>
		<cfquery dataSource="#arguments.thestruct.razuna.application.datasource#">
		INSERT INTO cache
		(host_id, cache_token, cache_type)
		VALUES
		(<cfqueryparam value="#arguments.thestruct.host_id#" CFSQLType="CF_SQL_NUMERIC">, <cfqueryparam value="#newfolderid#" CFSQLType="CF_SQL_VARCHAR">, <cfqueryparam value="videos" CFSQLType="CF_SQL_VARCHAR">)
		</cfquery>
		<cfquery dataSource="#arguments.thestruct.razuna.application.datasource#">
		INSERT INTO cache
		(host_id, cache_token, cache_type)
		VALUES
		(<cfqueryparam value="#arguments.thestruct.host_id#" CFSQLType="CF_SQL_NUMERIC">, <cfqueryparam value="#newfolderid#" CFSQLType="CF_SQL_VARCHAR">, <cfqueryparam value="files" CFSQLType="CF_SQL_VARCHAR">)
		</cfquery>
		<cfquery dataSource="#arguments.thestruct.razuna.application.datasource#">
		INSERT INTO cache
		(host_id, cache_token, cache_type)
		VALUES
		(<cfqueryparam value="#arguments.thestruct.host_id#" CFSQLType="CF_SQL_NUMERIC">, <cfqueryparam value="#newfolderid#" CFSQLType="CF_SQL_VARCHAR">, <cfqueryparam value="audios" CFSQLType="CF_SQL_VARCHAR">)
		</cfquery>
		<cfquery dataSource="#arguments.thestruct.razuna.application.datasource#">
		INSERT INTO cache
		(host_id, cache_token, cache_type)
		VALUES
		(<cfqueryparam value="#arguments.thestruct.host_id#" CFSQLType="CF_SQL_NUMERIC">, <cfqueryparam value="#newfolderid#" CFSQLType="CF_SQL_VARCHAR">, <cfqueryparam value="labels" CFSQLType="CF_SQL_VARCHAR">)
		</cfquery>
		<cfquery dataSource="#arguments.thestruct.razuna.application.datasource#">
		INSERT INTO cache
		(host_id, cache_token, cache_type)
		VALUES
		(<cfqueryparam value="#arguments.thestruct.host_id#" CFSQLType="CF_SQL_NUMERIC">, <cfqueryparam value="#newfolderid#" CFSQLType="CF_SQL_VARCHAR">, <cfqueryparam value="logs" CFSQLType="CF_SQL_VARCHAR">)
		</cfquery>
		<cfquery dataSource="#arguments.thestruct.razuna.application.datasource#">
		INSERT INTO cache
		(host_id, cache_token, cache_type)
		VALUES
		(<cfqueryparam value="#arguments.thestruct.host_id#" CFSQLType="CF_SQL_NUMERIC">, <cfqueryparam value="#newfolderid#" CFSQLType="CF_SQL_VARCHAR">, <cfqueryparam value="search" CFSQLType="CF_SQL_VARCHAR">)
		</cfquery>
		<cfquery dataSource="#arguments.thestruct.razuna.application.datasource#">
		INSERT INTO cache
		(host_id, cache_token, cache_type)
		VALUES
		(<cfqueryparam value="#arguments.thestruct.host_id#" CFSQLType="CF_SQL_NUMERIC">, <cfqueryparam value="#newfolderid#" CFSQLType="CF_SQL_VARCHAR">, <cfqueryparam value="settings" CFSQLType="CF_SQL_VARCHAR">)
		</cfquery>
		<cfquery dataSource="#arguments.thestruct.razuna.application.datasource#">
		INSERT INTO cache
		(host_id, cache_token, cache_type)
		VALUES
		(<cfqueryparam value="#arguments.thestruct.host_id#" CFSQLType="CF_SQL_NUMERIC">, <cfqueryparam value="#newfolderid#" CFSQLType="CF_SQL_VARCHAR">, <cfqueryparam value="users" CFSQLType="CF_SQL_VARCHAR">)
		</cfquery>
		<cfquery dataSource="#arguments.thestruct.razuna.application.datasource#">
		INSERT INTO cache
		(host_id, cache_token, cache_type)
		VALUES
		(<cfqueryparam value="#arguments.thestruct.host_id#" CFSQLType="CF_SQL_NUMERIC">, <cfqueryparam value="#newfolderid#" CFSQLType="CF_SQL_VARCHAR">, <cfqueryparam value="general" CFSQLType="CF_SQL_VARCHAR">)
		</cfquery>
		<cfcatch type="any">
			<cfset consoleoutput(true, true)>
			<cfset console("NEW HOST ERROR", cfcatch )>
		</cfcatch>
	</cftry>
	<cfreturn />
</cffunction>

<!--- ------------------------------------------------------------------------------------- --->
<!--- create Application.cfm for any module --->
<cffunction name="newHostCreateApp" access="remote" output="true" >
	<cfargument name="module_folder" type="string" required="yes" >
	<cfargument name="thisid" type="numeric" required="true">
	<cfargument name="host_path_replace" type="string" required="true">
	<cfargument name="host_db_prefix_replace" type="string" required="true">
	<cfargument name="pathoneup" type="string" required="true">
	<!--- function internal vars --->
	<cfset var something = "">
	<cfset var something2 = "">
	<!--- create the folder --->
	<cfif not DirectoryExists("#arguments.pathoneup#/#arguments.host_path_replace#/#arguments.module_folder#")>
		<cfdirectory action="create" directory="#arguments.pathoneup#/#arguments.host_path_replace#/#arguments.module_folder#" mode="775">
	</cfif>
	<!--- content of fusebox.init.cfm should be left-aligned => code moved to included-file --->
	<cfsavecontent variable="something"><cfinclude template="../../admin/newhost/#arguments.module_folder#_fuseboxinit.cfm"></cfsavecontent>
	<!--- Write the Application file in the Intra Folder --->
	<cffile action="write" file="#arguments.pathoneup#/#arguments.host_path_replace#/#arguments.module_folder#/fusebox.init.cfm" output="#something#" mode="775">
	<!--- content of fusebox.appinit.cfm --->
	<!--- <cfsavecontent variable="appinit"><cfinclude template="../../admin/newhost/#arguments.module_folder#_fuseboxappinit.cfm"></cfsavecontent> --->
	<!--- Write the Application file in the Intra Folder --->
	<!--- <cffile action="write" file="#arguments.pathoneup#/#arguments.host_path_replace#/#arguments.module_folder#/fusebox.appinit.cfm" output="#appinit#" mode="775"> --->
</cffunction>

!--- ------------------------------------------------------------------------------------- --->
<!--- Get all the records --->
<cffunction  name="getall" returntype="query" output="false" access="public">
	<cfargument name="orderBy" type="string" required="false" default="host_name ASC" "ORDER BY #yourtext#""">
	<cfargument name="thestruct" type="struct" required="true" />
	<!--- function internal vars --->
	<cfset var localquery = 0>
	<!--- Query --->
	<cfquery datasource="#arguments.thestruct.razuna.application.datasource#" name="localquery">
	SELECT host_id, host_name, host_name_custom
	FROM hosts
	ORDER BY #arguments.orderBy#
	</cfquery>
	<!--- Set the session for offset correctly if the total count of assets in lower the the total rowmaxpage --->
	<cfif localquery.recordcount LTE arguments.thestruct.razuna.session.rowmaxpage>
		<cfset arguments.thestruct.razuna.session.offset = 0>
	</cfif>
	<!--- Return --->
	<cfreturn localquery>
</cffunction>

<!--- ------------------------------------------------------------------------------------- --->
<!--- Get one detailled record --->
<cffunction name="getdetail" returntype="query" output="false" access="public">
	<cfargument name="thestruct" type="Struct">
	<cfargument name="host_id" type="String" default="1">
	<cfset arguments.thestruct.razuna.session.hostid = arguments.host_id>
	<cfset session.hostid = arguments.host_id>
	<!--- function internal vars --->
	<cfset var localquery = 0>
	<!--- function-body --->
	<cfquery datasource="#arguments.thestruct.razuna.application.datasource#" name="localquery">
	SELECT host_id, host_name, host_path, host_db_prefix, host_lang, host_type, host_shard_group, host_name_custom
	FROM hosts
	WHERE host_id = <cfqueryparam cfsqltype="cf_sql_numeric" value="#arguments.host_id#">
	</cfquery>
	<cfreturn localquery>
</cffunction>

<!--- ------------------------------------------------------------------------------------- --->
<!--- Update Host --->
<cffunction name="update" output="false" access="public" returntype="void">
	<cfargument name="thestruct" type="Struct">
	<!--- Param --->
	<cfparam name="arguments.thestruct.host_name_custom" default="">
	<!--- Update --->
	<cfquery datasource="#arguments.thestruct.razuna.application.datasource#">
	UPDATE hosts
	SET
	host_name = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.thestruct.host_name#">,
	host_name_custom = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.thestruct.host_name_custom#">
	WHERE host_id = <cfqueryparam cfsqltype="cf_sql_numeric" value="#arguments.thestruct.host_id#">
	</cfquery>
	<!--- Flush Cache --->
	<cfset resetcachetoken(type="general", hostid=arguments.thestruct.razuna.session.hostid, thestruct=arguments.thestruct)>
	<cfset resetcachetoken(type="settings", hostid=arguments.thestruct.razuna.session.hostid, thestruct=arguments.thestruct)>
	<cfreturn />
</cffunction>

<!--- This is from remote --->
<cffunction name="remove_remote" access="remote" output="true" returntype="Any">
	<cfargument name="id" type="string" required="true">
	<cfargument name="dsn" type="string" required="true">
	<cfargument name="database" type="string" required="true">
	<cfargument name="storage" type="string" required="true">
	<cfargument name="schema" type="string" required="true">
	<cfargument name="thestruct" type="struct" required="true" />
	<!--- Params --->
	<cfset arguments.thestruct.id = arguments.id>
	<!--- Now call the below function --->
	<cfinvoke method="remove" thestruct="#arguments.thestruct#">
</cffunction>

<!--- ------------------------------------------------------------------------------------- --->
<!--- Remove Host --->
<cffunction name="remove" output="true" access="public">
	<cfargument name="thestruct" type="Struct">
	<!--- Query host --->
	<cfquery datasource="#arguments.thestruct.razuna.application.datasource#" name="qry_rhost">
	SELECT host_path, host_shard_group, host_db_prefix
	FROM hosts
	WHERE host_id = <cfqueryparam cfsqltype="cf_sql_numeric" value="#arguments.thestruct.id#">
	</cfquery>
	<!--- Only if we find a record --->
	<cfif qry_rhost.recordcount EQ 1>
		<!--- Get settings --->
		<cfquery datasource="#arguments.thestruct.razuna.application.datasource#" name="qry_rhost_settings">
		SELECT set2_path_to_assets as path_to_assets
		FROM #qry_rhost.host_shard_group#settings_2
		WHERE host_id = <cfqueryparam cfsqltype="cf_sql_numeric" value="#arguments.thestruct.id#">
		</cfquery>
		<cftry>
			<!--- Remove the Host entry --->
			<cfquery datasource="#arguments.thestruct.razuna.application.datasource#">
			DELETE FROM hosts
			WHERE host_id = <cfqueryparam cfsqltype="cf_sql_numeric" value="#arguments.thestruct.id#">
			</cfquery>
			<!--- Select users to remove but only if in one host and not SystemAdmin --->
			<cfquery datasource="#arguments.thestruct.razuna.application.datasource#" name="qry_user">
			SELECT u.*
			FROM users u, ct_users_hosts ct
			WHERE ct.ct_u_h_host_id = #arguments.thestruct.id#
			AND u.user_id = ct.ct_u_h_user_id
			AND 1 = (SELECT count(cts.ct_u_h_host_id) FROM ct_users_hosts cts WHERE cts.ct_u_h_user_id = u.user_id)
			AND u.user_id NOT IN (SELECT ct_g_u_user_id FROM ct_groups_users WHERE ct_g_u_user_id = u.user_id AND ct_g_u_grp_id = '1')
			GROUP BY u.user_id
			</cfquery>
			<!--- Remove user --->
			<cfloop query="qry_user">
				<cfquery datasource="#arguments.thestruct.razuna.application.datasource#">
				DELETE FROM users
				WHERE user_id = <cfqueryparam cfsqltype="cf_sql_varchar" value="#user_id#">
				</cfquery>
			</cfloop>
			<!--- Remove any user linked to this host --->
			<cfquery datasource="#arguments.thestruct.razuna.application.datasource#">
			DELETE FROM ct_users_hosts
			WHERE ct_u_h_host_id = <cfqueryparam cfsqltype="cf_sql_numeric" value="#arguments.thestruct.id#">
			</cfquery>
			<!--- Remove from cache --->
			<cfquery datasource="#arguments.thestruct.razuna.application.datasource#">
			DELETE FROM cache
			WHERE host_id = <cfqueryparam cfsqltype="cf_sql_numeric" value="#arguments.thestruct.id#">
			</cfquery>
			<!--- REMOVE DATA RELATED TO HOST FROM groups, permissions, modules --->
			<!--- groups-permissions --->
			<cfquery datasource="#arguments.thestruct.razuna.application.datasource#">
			DELETE
			FROM ct_groups_permissions
			WHERE EXISTS(
						SELECT groups.grp_id
						FROM groups
						WHERE groups.grp_id = ct_groups_permissions.ct_g_p_grp_id
						AND groups.grp_host_id = <cfqueryparam cfsqltype="cf_sql_numeric" value="#arguments.thestruct.id#">
						)
			OR EXISTS(
						SELECT permissions.per_id
						FROM permissions
						WHERE permissions.per_id = ct_groups_permissions.ct_g_p_per_id
						AND permissions.per_host_id = <cfqueryparam cfsqltype="cf_sql_numeric" value="#arguments.thestruct.id#">
						)
			</cfquery>
			<!--- groups-users --->
			<cfquery datasource="#arguments.thestruct.razuna.application.datasource#">
			DELETE FROM	ct_groups_users
			WHERE EXISTS(
						SELECT groups.grp_id
						FROM groups
						WHERE groups.grp_id = ct_groups_users.ct_g_u_grp_id
						AND groups.grp_host_id = <cfqueryparam cfsqltype="cf_sql_numeric" value="#arguments.thestruct.id#">
						)
			</cfquery>
			<!--- remove entries from data-tables --->
			<!--- groups --->
			<cfquery datasource="#arguments.thestruct.razuna.application.datasource#">
			DELETE FROM	groups
			WHERE grp_host_id = <cfqueryparam cfsqltype="cf_sql_numeric" value="#arguments.thestruct.id#">
			</cfquery>
			<!--- permissions --->
			<cfquery datasource="#arguments.thestruct.razuna.application.datasource#">
			DELETE FROM permissions
			WHERE per_host_id = <cfqueryparam cfsqltype="cf_sql_numeric" value="#arguments.thestruct.id#">
			</cfquery>
			<!--- modules --->
			<cfquery datasource="#arguments.thestruct.razuna.application.datasource#">
			DELETE FROM	modules
			WHERE mod_host_id = <cfqueryparam cfsqltype="cf_sql_numeric" value="#arguments.thestruct.id#">
			</cfquery>

			<cfcatch type="any">
				<cfset consoleoutput(true, true)>
				<cfset console("--- Error while removing host ---")>
				<cfset console(cfcatch)>
			</cfcatch>
		</cftry>
		<!--- Since 1.4 we only remove records in the DB and don't drop tables anymore --->

		<cftry>

			<!--- Upper case the sharding group prefix --->
			<cfset host_shard_group = lcase(qry_rhost.host_shard_group)>

			<!--- Get tables with this prefix --->
			<cfquery datasource="#arguments.thestruct.razuna.application.datasource#" name="tbl">
			SELECT table_name
			FROM information_schema.tables
			WHERE lower(table_name) LIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="#host_shard_group#%">
			</cfquery>
			<!--- Loop over tables --->
			<cfloop query="tbl">
				<!--- MSSQL --->
				<cfif arguments.thestruct.razuna.application.thedatabase EQ "mssql">
					<cfquery datasource="#arguments.thestruct.razuna.application.datasource#">
					ALTER TABLE #arguments.thestruct.razuna.application.theschema#.#table_name# NOCHECK CONSTRAINT ALL
					</cfquery>
				</cfif>
				<!--- MySQL --->
				<cfif arguments.thestruct.razuna.application.thedatabase EQ "mysql">
					<cfquery datasource="#arguments.thestruct.razuna.application.datasource#">
					SET foreign_key_checks = 0
					</cfquery>
				</cfif>
				<!--- H2 --->
				<cfif arguments.thestruct.razuna.application.thedatabase EQ "h2">
					<cfquery datasource="#arguments.thestruct.razuna.application.datasource#">
					ALTER TABLE #table_name# SET REFERENTIAL_INTEGRITY false
					</cfquery>
				</cfif>
				<!--- Remove Data --->
				<cftry>
					<cfquery datasource="#arguments.thestruct.razuna.application.datasource#">
					DELETE FROM #table_name#
					WHERE host_id = <cfqueryparam cfsqltype="cf_sql_numeric" value="#arguments.thestruct.id#">
					</cfquery>
					<cfcatch type="any">
					</cfcatch>
				</cftry>
			</cfloop>

			<cfcatch>
				<cfset consoleoutput(true, true)>
				<cfset console("--- Error while removing db records host ---")>
				<cfset console(cfcatch)>
			</cfcatch>
		</cftry>

		<!--- REMOVE THE DIRECTORY ON THE FILESYSTEM --->
		<cfset console("--- Starting to remove assets on file for #arguments.thestruct.id# ---")>

		<cfset _s = StructNew()>
		<cfset _s.asset_dir = "#qry_rhost_settings.path_to_assets#/#arguments.thestruct.id#">

		<cfset console("--- Directory: #_s.asset_dir# ---")>

		<cfthread intstruct="#_s#">
			<cftry>
				<cfset console(attributes.intstruct.asset_dir)>
				<cfif directoryExists(attributes.intstruct.asset_dir)>
					<cfdirectory action="delete" directory="#attributes.intstruct.asset_dir#" mode="775" recurse="yes">
				</cfif>
				<cfcatch>
					<cfset console("--- Error while removing assets of host ---")>
					<cfset console(cfcatch)>
				</cfcatch>
			</cftry>
		</cfthread>

		<!--- Remove the Collection --->
		<cftry>
			<cfcollection action="delete" collection="#arguments.thestruct.id#" />
			<cfcatch></cfcatch>
		</cftry>

		<cfoutput>Host has been removed</cfoutput>

		<!--- Flush Cache --->
		<cfset resetcachetokenall(hostid=arguments.thestruct.razuna.session.hostid, thestruct=arguments.thestruct)>

	<cfelse>
		<cfoutput>NO Host found with #arguments.thestruct.id#</cfoutput>
		<cfreturn "NO Host found with #arguments.thestruct.id#" />
	</cfif>
</cffunction>

<!--- ------------------------------------------------------------------------------------- --->
<!--- RECREATE HOST --->
<cffunction name="hostupdate" output="true">
	<cfargument name="thestruct" type="Struct">
	<!--- function internal vars --->
	<!--- get host info for the below variables --->
	<cfset var qrythishost = getDetail(host_id=arguments.thestruct.host_id, thestruct=arguments.thestruct)>
	<cfset var iLoop = "">
	<!--- set variables which we need in the create app files below --->
	<cfset var thisid = arguments.thestruct.host_id>
	<cfset var host_path_replace = qrythishost.host_path>
	<!--- If ISP we reaplce the host path with the raz1 foler since only one folder exists --->
	<cfif arguments.thestruct.razuna.application.isp>
		<cfset var host_path_replace = "raz1">
	</cfif>
	<cfset var host_db_prefix_replace = qrythishost.host_shard_group>
	<cfset var thefiles = 0>
	<cfset var sqlStmt = "">
	<cftry>
		<!--- files --->
		<cfdirectory action="list" directory="#arguments.thestruct.pathoneup#/#host_path_replace#/dam/" name="thefiles" type="file">
		<cfloop query="thefiles">
			<cffile action="delete" file="#arguments.thestruct.pathoneup#/#host_path_replace#/dam/#name#">
		</cfloop>
		<cfcatch type="any"></cfcatch>
	</cftry>
	<!--- COPY NEWHOST DAM DIR --->
	<cfinvoke component="global" method="directoryCopy">
		<cfinvokeargument name="source" value="#arguments.thestruct.pathhere#/newhost/hostfiles/dam">
		<cfinvokeargument name="destination" value="#arguments.thestruct.pathoneup#/#host_path_replace#/dam">
		<cfinvokeargument name="directoryrecursive" value="true">
	</cfinvoke>
	<!--- Re-Write the fusebox files --->
		<cfinvoke method="newHostCreateApp">
			<cfinvokeargument name="module_folder" value="dam">
			<cfinvokeargument name="thisid" value="#thisid#">
			<cfinvokeargument name="host_path_replace" value="#host_path_replace#">
			<cfinvokeargument name="host_db_prefix_replace" value="#host_db_prefix_replace#">
			<cfinvokeargument name="pathoneup" value="#arguments.thestruct.pathoneup#">
		</cfinvoke>

	<!--- Check to see if cache values are in the DB --->
	<cfinvoke method="setcachetoken" hostid="#arguments.thestruct.host_id#" thestruct="#arguments.thestruct#" />

	<!--- Now update the language table from this host. Compare the change and id column
	<cfloop index="l" from="1" to="#qrythishost.host_lang#">
		<!--- Error check to see if the language is here, if not add all the translation from the master translation table --->
		<cfquery datasource="#arguments.thestruct.razuna.application.datasource#" name="ishere">
			SELECT trans_id
			FROM #host_db_prefix_replace#translations
			WHERE lang_id_r = <cfqueryparam cfsqltype="cf_sql_numeric" value="#l#">
		</cfquery>
		<cfif ishere.recordcount EQ 0>
			<cfquery datasource="#arguments.thestruct.razuna.application.datasource#">
				<cfset sqlStmt = "INSERT INTO #host_db_prefix_replace#translations (trans_id, lang_id_r, trans_text)
									SELECT trans_id, lang_id_r, trans_text
									FROM   translations
									WHERE  lang_id_r = #evaluate(l)# ">
				<cfstoredproc datasource="#arguments.thestruct.razuna.application.datasource#" procedure="#arguments.thestruct.razuna.session.theoraschema#.exec_insertinto_sql">
					<cfprocparam cfsqltype="CF_SQL_VARCHAR" dbvarname="sqlstatement" type="in" value="#sqlStmt#">
				</cfstoredproc>
			</cfquery>
		<!--- else do the update thing on the translations --->
		<cfelse>
			<!--- Insert all NEW Language tags from the master translation table --->
			<cfset sqlStmt = "INSERT INTO #host_db_prefix_replace#translations (trans_id, lang_id_r, trans_text)
							   (SELECT t.trans_id, t.lang_id_r, t.trans_text
								FROM   translations t
								WHERE NOT EXISTS (
									SELECT td.trans_id
									FROM   #host_db_prefix_replace#translations td
									WHERE  t.trans_id = td.trans_id)
								AND    t.lang_id_r = #evaluate(l)# )">
			<cfstoredproc datasource="#arguments.thestruct.razuna.application.datasource#" procedure="#arguments.thestruct.razuna.session.theoraschema#.exec_insertinto_sql">
				<cfprocparam cfsqltype="CF_SQL_VARCHAR" dbvarname="sqlstatement" type="in" value="#sqlStmt#">
			</cfstoredproc>
			<!--- Update all fields which have not been changed by the user (trans_changed is null) --->
			<cfquery datasource="#arguments.thestruct.razuna.application.datasource#" name="toupdate">
				SELECT dt.trans_id, dt.lang_id_r, dt.trans_text
				FROM #host_db_prefix_replace#translations dt, translations t
				WHERE dt.lang_id_r = <cfqueryparam cfsqltype="cf_sql_numeric" value="#l#">
				AND dt.trans_id = t.trans_id
				AND (dt.trans_changed IS NULL OR dt.trans_changed = '')
				GROUP BY dt.trans_id, dt.lang_id_r, dt.trans_text
			</cfquery>
			<cfoutput query="toupdate">
				<cfquery datasource="#arguments.thestruct.razuna.application.datasource#">
					UPDATE #host_db_prefix_replace#translations
					SET trans_id   = <cfqueryparam  cfsqltype="cf_sql_varchar" value="#trans_id#">,
					lang_id_r  = <cfqueryparam cfsqltype="cf_sql_numeric" value="#l#">,
					trans_text = <cfqueryparam  cfsqltype="cf_sql_varchar" value="#trans_text#">
					WHERE lang_id_r = <cfqueryparam cfsqltype="cf_sql_numeric" value="#l#">
					AND trans_id  = <cfqueryparam  cfsqltype="cf_sql_varchar" value="#trans_id#">
				</cfquery>
			</cfoutput>
		</cfif>
	</cfloop> --->
	<cfreturn />
</cffunction>

<!--- ------------------------------------------------------------------------------------- --->
<!--- Clear database: We have to go trough here since we don't initialize the DB CFC's directly --->
<cffunction name="cleardb" output="true">
	<cfargument name="thestruct" type="struct" required="true" />
	<cfinvoke component="db_#arguments.thestruct.razuna.application.thedatabase#" method="clearall" thestruct="#arguments.thestruct#" />
	<cfreturn />
</cffunction>

<!--- Save cachetoken --->
<cffunction name="setcachetoken" output="false" returntype="void">
	<cfargument name="hostid" required="true">
	<cfargument name="thestruct" type="struct" required="true" />
	<cfset var qry = "">
	<!--- Query for hostid --->
	<cfquery dataSource="#arguments.thestruct.razuna.application.datasource#" name="qry">
	SELECT host_id
	FROM cache
	WHERE host_id = <cfqueryparam value="#arguments.hostid#" CFSQLType="CF_SQL_NUMERIC">
	</cfquery>
	<!--- No cache record is here thus insert for the first time --->
	<cfif qry.recordcount EQ 0>
		<!--- Create token --->
		<cfset var t = createuuid('')>
		<!--- Inserts --->
		<cfquery dataSource="#arguments.thestruct.razuna.application.datasource#">
		INSERT INTO cache
		(host_id, cache_token, cache_type)
		VALUES
		(<cfqueryparam value="#arguments.hostid#" CFSQLType="CF_SQL_NUMERIC">, <cfqueryparam value="#t#" CFSQLType="CF_SQL_VARCHAR">, <cfqueryparam value="folders" CFSQLType="CF_SQL_VARCHAR">)
		</cfquery>
		<cfquery dataSource="#arguments.thestruct.razuna.application.datasource#">
		INSERT INTO cache
		(host_id, cache_token, cache_type)
		VALUES
		(<cfqueryparam value="#arguments.hostid#" CFSQLType="CF_SQL_NUMERIC">, <cfqueryparam value="#t#" CFSQLType="CF_SQL_VARCHAR">, <cfqueryparam value="images" CFSQLType="CF_SQL_VARCHAR">)
		</cfquery>
		<cfquery dataSource="#arguments.thestruct.razuna.application.datasource#">
		INSERT INTO cache
		(host_id, cache_token, cache_type)
		VALUES
		(<cfqueryparam value="#arguments.hostid#" CFSQLType="CF_SQL_NUMERIC">, <cfqueryparam value="#t#" CFSQLType="CF_SQL_VARCHAR">, <cfqueryparam value="videos" CFSQLType="CF_SQL_VARCHAR">)
		</cfquery>
		<cfquery dataSource="#arguments.thestruct.razuna.application.datasource#">
		INSERT INTO cache
		(host_id, cache_token, cache_type)
		VALUES
		(<cfqueryparam value="#arguments.hostid#" CFSQLType="CF_SQL_NUMERIC">, <cfqueryparam value="#t#" CFSQLType="CF_SQL_VARCHAR">, <cfqueryparam value="files" CFSQLType="CF_SQL_VARCHAR">)
		</cfquery>
		<cfquery dataSource="#arguments.thestruct.razuna.application.datasource#">
		INSERT INTO cache
		(host_id, cache_token, cache_type)
		VALUES
		(<cfqueryparam value="#arguments.hostid#" CFSQLType="CF_SQL_NUMERIC">, <cfqueryparam value="#t#" CFSQLType="CF_SQL_VARCHAR">, <cfqueryparam value="audios" CFSQLType="CF_SQL_VARCHAR">)
		</cfquery>
		<cfquery dataSource="#arguments.thestruct.razuna.application.datasource#">
		INSERT INTO cache
		(host_id, cache_token, cache_type)
		VALUES
		(<cfqueryparam value="#arguments.hostid#" CFSQLType="CF_SQL_NUMERIC">, <cfqueryparam value="#t#" CFSQLType="CF_SQL_VARCHAR">, <cfqueryparam value="labels" CFSQLType="CF_SQL_VARCHAR">)
		</cfquery>
		<cfquery dataSource="#arguments.thestruct.razuna.application.datasource#">
		INSERT INTO cache
		(host_id, cache_token, cache_type)
		VALUES
		(<cfqueryparam value="#arguments.hostid#" CFSQLType="CF_SQL_NUMERIC">, <cfqueryparam value="#t#" CFSQLType="CF_SQL_VARCHAR">, <cfqueryparam value="logs" CFSQLType="CF_SQL_VARCHAR">)
		</cfquery>
		<cfquery dataSource="#arguments.thestruct.razuna.application.datasource#">
		INSERT INTO cache
		(host_id, cache_token, cache_type)
		VALUES
		(<cfqueryparam value="#arguments.hostid#" CFSQLType="CF_SQL_NUMERIC">, <cfqueryparam value="#t#" CFSQLType="CF_SQL_VARCHAR">, <cfqueryparam value="search" CFSQLType="CF_SQL_VARCHAR">)
		</cfquery>
		<cfquery dataSource="#arguments.thestruct.razuna.application.datasource#">
		INSERT INTO cache
		(host_id, cache_token, cache_type)
		VALUES
		(<cfqueryparam value="#arguments.hostid#" CFSQLType="CF_SQL_NUMERIC">, <cfqueryparam value="#t#" CFSQLType="CF_SQL_VARCHAR">, <cfqueryparam value="settings" CFSQLType="CF_SQL_VARCHAR">)
		</cfquery>
		<cfquery dataSource="#arguments.thestruct.razuna.application.datasource#">
		INSERT INTO cache
		(host_id, cache_token, cache_type)
		VALUES
		(<cfqueryparam value="#arguments.hostid#" CFSQLType="CF_SQL_NUMERIC">, <cfqueryparam value="#t#" CFSQLType="CF_SQL_VARCHAR">, <cfqueryparam value="users" CFSQLType="CF_SQL_VARCHAR">)
		</cfquery>
		<cfquery dataSource="#arguments.thestruct.razuna.application.datasource#">
		INSERT INTO cache
		(host_id, cache_token, cache_type)
		VALUES
		(<cfqueryparam value="#arguments.hostid#" CFSQLType="CF_SQL_NUMERIC">, <cfqueryparam value="#t#" CFSQLType="CF_SQL_VARCHAR">, <cfqueryparam value="general" CFSQLType="CF_SQL_VARCHAR">)
		</cfquery>
	</cfif>
	<!--- Return --->
	<cfreturn />
</cffunction>

<!--- Function to return host size. Can be called from application and also from API. --->
<cffunction name="gethostsize" returntype="string" >
	<cfargument name="host_id" required="true" type="numeric">
	<cfargument name="thestruct" type="struct" required="true" />
	<cfset var host_size = -1>
	<cfobject component="global.cfc.global" name="gobj"> <!--- Instantiate files object for access to file manipulation functions --->
	<!--- Get path to asset directory--->
	<cfquery datasource="#arguments.thestruct.razuna.application.datasource#" name="getassetdir" cachedwithin="#CreateTimeSpan(0,3,0,0)#">
		SELECT set2_path_to_assets AS dir
		FROM #arguments.thestruct.razuna.session.hostdbprefix#settings_2
		WHERE host_id = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.host_id#">
	</cfquery>
	<cfset var assetdir = getassetdir.dir>
	<cfif !FindNoCase("Windows", server.os.name)> <!--- For non windows platforms use the native 'du' command to calculate size --->
		<!--- Create script files --->
		<cfset var thescript = createuuid() & "_hostsize">
		<cfset thesh = GetTempDirectory() & "/#thescript#.sh">
		<cffile action="write" file="#thesh#" output="du -sh #assetdir#/#arguments.host_id#" mode="777"><!--- Write out script file to disk --->
		<cfexecute name="#thesh#" variable="size" timeout="600"/> <!--- Execute the script --->
		<cfset host_size = gettoken(size,1,"#chr(9)#")> <!--- Store result --->
		<cffile action="delete" file="#thesh#"> <!--- Delete file after done executing --->
	<cfelse> <!--- For windows use the java io file operations to calculate size --->
	 	<cfset host_size = gobj.convertbytes(gobj.getsize ("#assetdir#/#arguments.host_id#"))>
	</cfif>
	<cfreturn host_size>
</cffunction>

</cfcomponent>