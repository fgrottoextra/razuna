<script language="javascript">
	function addgrp(){
		// Add the new group and show the updated list
		loadcontent('admin_groups', '<cfoutput>#myself#</cfoutput>c.groups_add&kind=ecp&loaddiv=admin_groups&newgrp=' + encodeURIComponent($("#grpnew").val()));
	}
	function updategrp(grpid){
		// Hide Window
		destroywindow(2);
		// Add the new group and show the updated list
		loadcontent('admin_groups', '<cfoutput>#myself#</cfoutput>c.groups_update&kind=ecp&loaddiv=admin_groups&grp_id=' + grpid + '&grpname=' + encodeURIComponent($("#grpname").val()));
	}
</script>