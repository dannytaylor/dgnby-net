// implementation of simple-peer for webrtc communication across tic80 clients
// database and simple-peer management

// firebase setup
var config = {apiKey: "AIzaSyBw_ZmIej1485GypsDtrLHscr4zr_k9zWc",authDomain: "simplepeer-xhg.firebaseapp.com",databaseURL: "https://simplepeer-xhg.firebaseio.com",projectId: "simplepeer-xhg",storageBucket: "simplepeer-xhg.appspot.com",messagingSenderId: "643438810145"  };
firebase.initializeApp(config);
var database = firebase.database();

// init vars
var peer1 = new SimplePeer({ initiator:false,trickle: false});
var peer2 = new SimplePeer({ initiator:true,trickle: false});

// various variables init
var clientID = 0;
var signalClient;
var state;
const roomCodeOptions = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
var code;
var p1send;
var p2send;

// hide host buttons til cart ready
var check_cart;

window.onload = function() {
  clientID = 0;
  check_cart = setInterval(checkCart, 500);
}


// helpers
function bits2byte(bits){
	var val = 0;
	for (i = 0; i < 8; i++) { 
		val+=(bits[i]*Math.pow(2,8-i));
	};
	return val;
}
function byte2bits(val){
	var bits = new Uint8Array(8);
	var rest = 0;
	for (i = 0; i < 8; i++) { 
		rest = Math.floor(val%2);
		bits[i]=rest;
		val=(val-rest)/2;
	};
	return bits;
}
// from https://github.com/rynobax/jump-game/
function generateRoomCode() {
  let code = '';
  for(let i=0; i<4; i++){
    const ndx = Math.floor(Math.random() * roomCodeOptions.length);
    code += roomCodeOptions[ndx];
    tic80_gpio[12+i]=roomCodeOptions[ndx].charCodeAt();
  }
  return code;
}


// wait for gpio to be ready
function checkCart() {
	var tmp = tic80_gpio[0];
	if (tmp>1 && clientID==0) {
		var tmp2 = new Uint8Array(8);
		tmp2 = byte2bits(tmp);
		if (tmp2[2]==1) { // if host
			clientID=1;
			lcode = generateRoomCode();
			console.log('created code: ', lcode);
			createRoom(lcode);
			clearTimeout(check_cart);
		} else if (tmp2[3]==1) { // if joining
			if (tic80_gpio[15]>0){
				clientID=2;
				lcode = ''
				for (i=12;i<16;i++){
					lcode += String.fromCharCode(tic80_gpio[i]);
				}
				console.log('joined code: ', lcode);
				joinRoom(lcode);
				clearTimeout(check_cart);
			}
		}
   }
}

// log simplepeer errors
peer1.on('error', function (err) { console.log('error2', err) });
peer2.on('error', function (err) { console.log('error2', err) });

// when host receives signal data
peer1.on('signal', function (data) {
	var signalHost = JSON.stringify(data);
	// add signal response to database
	database.ref('hosts/' + lcode + '/').update({
		hostData: signalHost,
	});
});

// when client received signal data (on peer creation)
peer2.on('signal', function (data) {
	// store signal data for later
	signalClient = JSON.stringify(data);
});

peer1.on('close', function () {
	tic80_gpio[8]=255;
	clearTimeout(p1send);
})

peer2.on('close', function () {
	tic80_gpio[8]=255;
	clearTimeout(p2send);
})



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
}

// called on join button pressed
function joinRoom(code) {
	if (state == null) {
		// TODO: check name is valid, alert() if not
		database.ref('hosts/' + code + '/').update({
			// add client signal data to database
			joinData: signalClient,
		});

		var hostData = firebase.database().ref('hosts/' + name + '/hostData');
		hostData.on('value', function(snapshot) {
			if(state == "client"){
				setTimeout(function(){ readAnswer(code); }, 200);
			}
		});
		state = "client";
	}
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
var uint8 = new Uint8Array(8);

// host on receive data
peer1.on('data', function (data) {
	for (i = 0; i < 8; i++) { 
		tic80_gpio[i+8] = data[i];
	}
});
// client on receive data
peer2.on('data', function (data) {
	for (i = 0; i < 8; i++) { 
		tic80_gpio[i+8] = data[i];
	}	
});

// when connection made send data on 33ms interval (~60 tick)
peer1.on('connect', function () {
	console.log('CONNECTED AS ',state);
	setTimeout(function(){ 
		p1send = setInterval(send_data, 33); 
	}, 500);
	database.ref('hosts/'+ lcode).remove();
});

peer2.on('connect', function () {
  console.log('CONNECTED AS ',state);
  setTimeout(function(){ 
  	p2send = setInterval(send_data, 33); 
  }, 500);
});



// send 8 bytes of data
function send_data(){
	for (i = 0; i < 8; i++) { 
		uint8[i] = tic80_gpio[i];
	}
  if(state=="host"){peer1.send(uint8);}
  else if(state=="client"){peer2.send(uint8);}
}