// implementation of simple-peer for webrtc communication across tic80 clients
// database and simple-peer management



// firebase setup
var config = {apiKey: "AIzaSyBw_ZmIej1485GypsDtrLHscr4zr_k9zWc",authDomain: "simplepeer-xhg.firebaseapp.com",databaseURL: "https://simplepeer-xhg.firebaseio.com",projectId: "simplepeer-xhg",storageBucket: "simplepeer-xhg.appspot.com",messagingSenderId: "643438810145"  };
firebase.initializeApp(config);
var database = firebase.database();

// init host and client peer
var peer1 = new SimplePeer({ initiator:false,trickle: false});
var peer2 = new SimplePeer({ initiator:true,trickle: false});

// various variables init
var signalClient;
var state;


// hide host buttons til cart ready
var cart_ready = false;
var check_cart;
window.onload = function() {
  check_cart = setInterval(checkCart, 500);
};
// wait for gpio to be ready
function checkCart() {
   if (cart_ready==false && tic80_gpio[0]==1) {
       document.getElementById('loading').style.animation='0.2s fadeOut forwards';
       document.getElementById('hostbox').style.animation='0.2s fadeIn forwards';
       cart_ready = true;
       clearTimeout(check_cart);
   };
};

// log simplepeer errors
peer1.on('error', function (err) { console.log('error2', err) });
peer2.on('error', function (err) { console.log('error2', err) });

// when host receives signal data
peer1.on('signal', function (data) {
		var signalHost = JSON.stringify(data);
		// var campname = document.querySelector('#incoming').value;
		// to add entry field for lobby names
		var campname = 'dgnby';
		// add signal response to database
		database.ref('hosts/' + campname + '/').update({
			hostData: signalHost,
		});
});

// when client received signal data (on peer creation)
peer2.on('signal', function (data) {
		// store signal data for later
		signalClient = JSON.stringify(data);
});

// when connection made send data on 33ms interval (~60 tick)
peer1.on('connect', function () {
  console.log('CONNECT AS ',state);
  // tic80_gpio[4]=15;
  setInterval(send_data, 33);
});
peer2.on('connect', function () {
  console.log('CONNECT AS ',state);
  tic80_gpio[1]=2;
  setInterval(send_data, 33);
});



// called on host button pressed
function hostRoom() {
	if (state == null) {
		// var campname = document.querySelector('#incoming').value;
		var campname = 'dgnby';
		// if person entered a name
		// TODO: check for valid name
		// TODO: set alert() if bad name
		if(campname!=null){
			createRoom(campname);
		}
	}
	document.getElementById('hostbox').style.animation='0.2s fadeOut forwards';
}
function createRoom(name){
	// TODO: check if enter is not in use or expired
	database.ref('hosts/' + name + '/').set({
	  	hostData: "0",
	    createdAt : Date.now(),
	    joinData: "0",
	  });
	var joinData = firebase.database().ref('hosts/' + name + '/joinData');
	// watch client signal data for changes
	joinData.on('value', function(snapshot) {
		if(state == "host"){
		  // accept signal data when client adds it
		  peer1.signal(JSON.parse(snapshot.val()));
		}
	});
	state = "host";
	tic80_gpio[1]=1;
}

// called on join button pressed
function joinRoom() {
	if (state == null) {
		// var campname = document.querySelector('#incoming').value;
		var campname = 'dgnby';
		// TODO: check name is valid, alert() if not
		database.ref('hosts/' + campname + '/').update({
			// add client signal data to database
			joinData: signalClient,
		});

		var hostData = firebase.database().ref('hosts/' + name + '/hostData');
		// wait for host to respond to client signal data
		hostData.on('value', function(snapshot) {
			if(state == "client"){
				setTimeout(function(){ readAnswer(campname); }, 200);
			}
		});
		state = "client";
	}
	document.getElementById('hostbox').style.animation='0.2s fadeOut forwards';
}

// called when client sees host has responded to signal
function readAnswer(campname) {
	// nesting our database watch one level as the update seems to skip a tick or whatever
	database.ref('hosts/' + campname + '/hostData').once('value').then(function(snapshot) {
		// make the connection
		peer2.signal(JSON.parse(snapshot.val()));
	});
}

// data object sent by simple-peer
var uint8 = new Uint8Array(16);

// host on receive data
peer1.on('data', function (data) {
	for (i = 0; i < 8; i++) { 
		tic80_gpio[i+8] = data[i];
	}
  // console.log(data)
})
// client on receive data
peer2.on('data', function (data) {
	for (i = 0; i < 8; i++) { 
		tic80_gpio[i+8] = data[i];
	}	
  // console.log(data)
})

// send 8 bytes of data
function send_data(){
	for (i = 0; i < 8; i++) { 
		uint8[i] = tic80_gpio[i];
	}
  if(state=="host"){peer1.send(uint8);}
  else if(state=="client"){peer2.send(uint8);}
}