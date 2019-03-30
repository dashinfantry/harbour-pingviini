/*
    Copyright (C) 2012 Dickson Leong
    This file is part of Tweetian.

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program. If not, see <http://www.gnu.org/licenses/>.
*/

.pragma library
.import QtQuick.LocalStorage 2.0 as LS
Qt.include("common.js")
Qt.include("twitter-text.js")

var UNIQUE_MSGIDS = [];
var OAUTH_CONSUMER_KEY = "BsVdhEDHrLgE8SUfAUEoVdnwD"
var OAUTH_CONSUMER_SECRET = "UtGso4Buc2bX3FlBmYrwamKIuPRfwBfptO0we935jyRF90RboK"
var OAUTH_TOKEN
var OAUTH_TOKEN_SECRET
var USER_AGENT = "Pingviini Client"
var SCREEN_NAME
var USER_ID

function getConfTW(){
    return {
        OAUTH_CONSUMER_KEY: OAUTH_CONSUMER_KEY,
        OAUTH_CONSUMER_SECRET: OAUTH_CONSUMER_SECRET,
        OAUTH_TOKEN: OAUTH_TOKEN,
        OAUTH_TOKEN_SECRET: OAUTH_TOKEN_SECRET,
        USER_AGENT: USER_AGENT,
        SCREEN_NAME: SCREEN_NAME,
        USER_ID: USER_ID,
        modelUsers: modelUsers
    }
}

function customBase64Encode (inputStr) {
    var
        bbLen               = 3,
        enCharLen           = 4,
        inpLen              = inputStr.length,
        inx                 = 0,
        jnx,
        keyStr              = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"
                            + "0123456789+/=",
        output              = "",
        paddingBytes        = 0;
    var
        bytebuffer          = new Array (bbLen),
        encodedCharIndexes  = new Array (enCharLen);

    while (inx < inpLen) {
        for (jnx = 0;  jnx < bbLen;  ++jnx) {
            /*--- Throw away high-order byte, as documented at:
              https://developer.mozilla.org/En/Using_XMLHttpRequest#Handling_binary_data
            */
            if (inx < inpLen)
                bytebuffer[jnx] = inputStr.charCodeAt (inx++) & 0xff;
            else
                bytebuffer[jnx] = 0;
        }

        /*--- Get each encoded character, 6 bits at a time.
            index 0: first  6 bits
            index 1: second 6 bits
                        (2 least significant bits from inputStr byte 1
                         + 4 most significant bits from byte 2)
            index 2: third  6 bits
                        (4 least significant bits from inputStr byte 2
                         + 2 most significant bits from byte 3)
            index 3: forth  6 bits (6 least significant bits from inputStr byte 3)
        */
        encodedCharIndexes[0] = bytebuffer[0] >> 2;
        encodedCharIndexes[1] = ( (bytebuffer[0] & 0x3) << 4)   |  (bytebuffer[1] >> 4);
        encodedCharIndexes[2] = ( (bytebuffer[1] & 0x0f) << 2)  |  (bytebuffer[2] >> 6);
        encodedCharIndexes[3] = bytebuffer[2] & 0x3f;

        //--- Determine whether padding happened, and adjust accordingly.
        paddingBytes          = inx - (inpLen - 1);
        switch (paddingBytes) {
            case 1:
                // Set last character to padding char
                encodedCharIndexes[3] = 64;
                break;
            case 2:
                // Set last 2 characters to padding char
                encodedCharIndexes[3] = 64;
                encodedCharIndexes[2] = 64;
                break;
            default:
                break; // No padding - proceed
        }

        /*--- Now grab each appropriate character out of our keystring,
            based on our index array and append it to the output string.
        */
        for (jnx = 0;  jnx < enCharLen;  ++jnx)
            output += keyStr.charAt ( encodedCharIndexes[jnx] );
    }
    return output;
}

var modelTL = Qt.createQmlObject('import QtQuick 2.0; ListModel {   }', Qt.application, 'InternalQmlObject');
var modelMN = Qt.createQmlObject('import QtQuick 2.0; ListModel {   }', Qt.application, 'InternalQmlObject');
var modelSE = Qt.createQmlObject('import QtQuick 2.0; ListModel {   }', Qt.application, 'InternalQmlObject');
var modelDM = Qt.createQmlObject('import QtQuick 2.0; ListModel {   }', Qt.application, 'InternalQmlObject');
var modelDMraw = Qt.createQmlObject('import QtQuick 2.0; ListModel {   }', Qt.application, 'InternalQmlObject');

var modelUsers = Qt.createQmlObject('import QtQuick 2.0; ListModel { dynamicRoles: true; function cleanup(){ console.log("Users" + count) }  }', Qt.application, 'InternalQmlObject');

var mediator = (function(){
    var subscribe = function(channel, fn){
        if(!mediator.channels[channel]) mediator.channels[channel] = [];
        console.log("object subscribed to "+channel)
        mediator.channels[channel].push({ context : this, callback : fn });
        return this;
    };
    var publish = function(channel){
        console.log("Mediator publish on channel >" + channel)
        if(!mediator.channels[channel]) return false;
        var args = Array.prototype.slice.call(arguments, 1);
        for(var i = 0, l = mediator.channels[channel].length; i < l; i++){
            var subscription = mediator.channels[channel][i];
            subscription.callback(args);
        };
        return this;
    };
    return {
        channels : {},
        publish : publish,
        subscribe : subscribe,
        installTo : function(obj){
            obj.subscribe = subscribe;
            obj.publish = publish;
        }
    };
}());

var db = LS.LocalStorage.openDatabaseSync("pingviini", "", "pingviini", 100000);
var conf = {}



function initialize() {
    console.log("db.version: "+db.version);
    if(db.version === '') {
        db.transaction(function(tx) {
            tx.executeSql('CREATE TABLE IF NOT EXISTS settings ('
                          + ' key TEXT UNIQUE, '
                          + ' value TEXT '
                          +');');
            tx.executeSql('INSERT INTO settings (key, value) VALUES (?, ?)', ["conf", "{}"]);
        });
        db.changeVersion('', '0.1', function(tx) {

        });
    }

    db.transaction(function(tx) {
        var rs = tx.executeSql('SELECT * FROM settings;');
        for (var i = 0; i < rs.rows.length; i++) {
            //var json = JSON.parse(rs.rows.item(i).value);
            console.log("READED "+rs.rows.item(i).key+" in DB: "+rs.rows.item(i).value)
            //if ( rs.rows.item(i).key === "favourite" && rs.rows.item(i).value !== null)
            //    favouriteItems = JSON.parse(rs.rows.item(i).value);
            if ( rs.rows.item(i).key === "conf" && rs.rows.item(i).value !== null){
                conf= JSON.parse(rs.rows.item(i).value);
                if (conf.OAUTH_TOKEN)
                    OAUTH_TOKEN = conf.OAUTH_TOKEN;
                if (conf.OAUTH_TOKEN_SECRET)
                    OAUTH_TOKEN_SECRET = conf.OAUTH_TOKEN_SECRET;
                if (conf.SCREEN_NAME)
                    SCREEN_NAME = conf.SCREEN_NAME;

            }
        }
        mediator.publish('confLoaded', { loaded: true});
    });
}

function saveData() {
    db.transaction(function(tx) {
        if (conf.OAUTH_TOKEN){
            var rs2 = tx.executeSql('UPDATE settings SET value = ? WHERE key = ?', [JSON.stringify(conf), "conf"]);
            console.log("Saving... "+JSON.stringify(conf)+"\n"+JSON.stringify(rs2))
        }
    });
}

var parseDM = (function(){
    var user_id = 0;
    var participiants = [];
    var data = [];
    var append = function(items) {
        if (!items) {
            return
        }

        var length = items.length - 1;
        while(length){
            var item = items[length];
            var tmp = {
                id 					: item.id,
                sent                : conf.USER_ID == item.message_create.sender_id ? false : true,
                                                                                      createdAt           : new Date(item.created_timestamp*1),
                                                                                      sender_id			: item.message_create.sender_id,
                                                                                      reciever_id			: item.message_create.target.recipient_id,
                                                                                      text				: item.message_create.message_data.text
            };
            if (item.message_create.message_data.entities)
                tmp['text'] = parseEntities(tmp['text'], item.message_create.message_data.entities);

            if (participiants.filter(function(e){ if ( e.user_id === tmp.sender_id ) return true; }).length === 0) {
                participiants.push({user_id : tmp.sender_id, name : "Name " + tmp.sender_id })
                modelUsers.append({user_id : tmp.sender_id })
            }
            if (participiants.filter(function(e){ if ( e.user_id === tmp.reciever_id ) return true; }).length === 0) {
                participiants.push({user_id : tmp.reciever_id, name : "Name " + tmp.reciever_id })
            }
            if (data.filter(function(e){ if ( e.id === tmp.id ) return true; }).length === 0) {
                data.push( tmp )
            }

            length--;
        }
        modelDM.clear();
        modelDM.append(getList())
    }
    var getThread = function(id) {

        var modelThread  = Qt.createQmlObject('import QtQuick 2.0; ListModel {   }', Qt.application, 'InternalQmlObject');
        var thread = data.filter(function(el) {
            //console.log(typeof conf.USER_ID + " " + conf.USER_ID)
            //console.log(typeof el.sender_id + " " + el.sender_id)
            return (el.sender_id == id && el.reciever_id == conf.USER_ID) || (el.sender_id == conf.USER_ID && el.reciever_id == id);
        })
        modelThread.append(thread)
        return modelThread;
    }
    var setUserId = function(id) {
        user_id = id;
    }
    var getList = function() {
        var list = [];
        for (var i = participiants.length - 1; i >= 0; i--) {
            var participiant = participiants[i];
            //console.log(JSON.stringify(participiant));

            var msgsByUser = data.filter(function(el) {
                return (el.sender_id == participiant.user_id && el.reciever_id == user_id) || (el.sender_id == user_id && el.reciever_id == participiant.user_id);
            }).sort(function(a,b){
                return a.createdAt - b.createdAt;
            });

            var text = "";
            var replied = false;
            var createdAt;
            if(msgsByUser.length) {
                var lastMsg = msgsByUser[msgsByUser.length-1]
                text = lastMsg.text;
                replied = lastMsg.sender_id == conf.USER_ID;
                createdAt = lastMsg.createdAt;
            }



            list.push({
                          user_id: participiant.user_id,
                          text: text,
                          replied: replied,
                          createdAt: createdAt
                      })
        }
        return list;
    }
    return {
        setUserId: setUserId,
        getUserId: user_id,
        append: append,
        data: data,
        participiants: participiants,
        getThread: getThread,
        getList: getList
    }
})();


var getUserData= function(uid, key) {
    for(var i = 0; i < modelUsers.count; i++){
        if (modelUsers.get(i).user_id == uid && modelUsers.get(i)[key].length>2)
            return modelUsers.get(i)[key]
    }
    return ""
}
var getIncompleteUsers = function() {
    var incomplete = [];
    // user_id, name, screen_name, avatar
    for (var i = 0; i < modelUsers.count; i++){
        var item = modelUsers.get(i)
        if ( item.name === "")
            incomplete.push(item.user_id)
    }
    return incomplete.join(",")
}
