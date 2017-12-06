// login script
function coffeefy(info) {
    var $ = function(selector){ return document.querySelector(selector) };

	// name
	$('input[name="userNm"]').value = info.name;

	// email
	$('input[name="cust_email_addr"]').value = info.email;

	// phone
	// $('input[name="cust_hp_no"]').value = info.phone;
    // $('input[name="cust_hp_cp"][value="l"]').checked = true;

	// agreement on Personal Information
	$('#agree1').checked = true;
    if ( $('#agree2') ) {
        $('#agree2').checked = true;
    }

	// override alert
	window.alert = function(message) {
		window.webkit.messageHandlers.coffeefy.postMessage('alert:'+message);
	}

	window.goAct();
}

// first page
if (typeof window.NextPage === 'function') {
    window.NextPage('0');
}

// form page
if (typeof window.goAct === 'function') {
	// request user information
    document.getElementById('purpose_agree').checked = true;
    goAct();
}

