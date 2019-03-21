import QtQuick 2.0
import Sailfish.Silica 1.0
import "../lib/Logic.js" as Logic
import "./cmp/"



Page {
    id: mainPage
    property bool isFirstPage: true
    allowedOrientations: Orientation.All

    DockedPanel {
        id: infoPanel
        open: true
        width: mainPage.isPortrait ? parent.width : Theme.itemSizeLarge
        height: mainPage.isPortrait ? Theme.itemSizeLarge : parent.height
        dock: mainPage.isPortrait ? Dock.Bottom : Dock.Right
        Navigation {
            id: navigation
            isPortrait: !mainPage.isPortrait
            onSlideshowShow: {
                console.log(vIndex)
                slideshow.positionViewAtIndex(vIndex, ListView.SnapToItem)
            }
        }
    }


    VisualItemModel {
        id: visualModel
        //*
        MyList {
            id: timelineViewComponent
            header: PageHeader {
                title: qsTr("Timeline")
                description: qsTr("Pingviini")
            }
            mdl: Logic.modelTL
            action: "statuses_homeTimeline"
            vars: {"count":200}
            conf: Logic.getConfTW()
            width: parent.width
            height: parent.height
            onOpenDrawer:  infoPanel.open = setDrawer
            delegate: CmpTweet { tweet: model}
        }

        MyList {
            id: mentionsViewComponent
            header: PageHeader {
                title: qsTr("Mentions")
                description: qsTr("Pingviini")
            }
            mdl: Logic.modelMN
            action: "statuses_mentionsTimeline"
            vars: {"count":200}
            conf: Logic.getConfTW()
            width: parent.width
            height: parent.height
            onOpenDrawer:  infoPanel.open = setDrawer
            delegate: CmpTweet { tweet: model}
        } // */
        MyList {
            id: dmList
            property int loaded_page: 0
            header: PageHeader {
                title: qsTr("Messages")
                description: qsTr("Pingviini")
            }
            mdl: Logic.modelDM
            action: "directMessages_events_list"
            vars: {"count":46 }
            conf: Logic.getConfTW()
            width: parent.width
            height: parent.height
            onOpenDrawer:  infoPanel.open = setDrawer
            delegate: BackgroundItem {
                height: Theme.itemSizeMedium + Theme.paddingMedium*2
                anchors.left: parent.left
                anchors.right: parent.right
                Image {
                    id: mainAvatar
                    anchors {
                        top: parent.top
                        topMargin: Theme.paddingLarge
                        left: parent.left
                        leftMargin: Theme.horizontalPageMargin
                    }
                    width: Theme.iconSizeMedium
                    height: width
                    source: !model.revert ? model.sender_avatar : model.recipient_avatar
                    smooth: true
                    opacity: status === Image.Ready ? 1.0 : 0.0
                    Behavior on opacity { FadeAnimator {} }
                    asynchronous: true
                    Image {
                        anchors {
                            bottom: parent.bottom
                            bottomMargin: -width/3
                            left: parent.left
                            leftMargin: -width/3
                        }
                        asynchronous: true
                        width: Theme.iconSizeSmall
                        height: width
                        smooth: true
                        opacity: status === Image.Ready ? 1.0 : 0.0
                        Behavior on opacity { FadeAnimator {} }
                        source: model.revert ? model.sender_avatar : model.recipient_avatar
                    }
                }
                Label {
                    id: lblName
                    anchors {
                        left: mainAvatar.right
                        leftMargin: Theme.paddingLarge
                        top: parent.top
                        topMargin: Theme.paddingLarge
                        right: lblDate.left
                    }
                    text: model.recipient_id //Logic.getUserName(model.recipient_id)
                    color: (pressed ? Theme.highlightColor : Theme.primaryColor)
                    wrapMode: Text.NoWrap
                }
                Label {
                    id: lblDate
                    color: (pressed ? Theme.highlightColor : Theme.primaryColor)
                    text: Format.formatDate(created_at, new Date() - created_at < 60*60*1000 ? Formatter.DurationElapsedShort : Formatter.TimeValueTwentyFourHours)
                    font.pixelSize: Theme.fontSizeExtraSmall
                    horizontalAlignment: Text.AlignRight
                    anchors {
                        right: parent.right
                        baseline: lblName.baseline
                        rightMargin: Theme.horizontalPageMargin
                    }
                }
                Label {
                    anchors {
                        left: lblName.left
                        right: lblDate.right
                        top: lblName.bottom
                    }
                    text: model.text
                    wrapMode: Text.NoWrap
                    elide: Text.ElideRight
                    font.pixelSize: Theme.fontSizeSmall
                    maximumLineCount: 1
                    color: (pressed ? Theme.secondaryHighlightColor : Theme.secondaryColor)
                }


                onClicked: {
                    pageStack.push(Qt.resolvedUrl("Conversation.qml"), {
                                       user_id : model.sender_id,
                                       recipient_id : model.recipient_id,
                                       user_name : model.sender_name,
                                       user_screen_name : model.sender_screen_name,
                                       user_avatar: model.sender_avatar
                                   })
                    //generateDirMsgList()
                }
            }
            function loadData(mode){
                console.log(mode)
                worker.sendMessage({conf: Logic.getConfTW(), model: Logic.modelDMreceived, mode: 'append', bgAction: 'directMessages_events_list', params: {count: 41}});
                //worker.sendMessage({conf: Logic.getConfTW(), model: Logic.modelDMsent, mode: 'append', bgAction: 'directMessages_sent', params: {count: 200, skip_status: true, include_entities: true, full_text: true}});
            }
        }

        MyList{

            ListView {
                visible: tlSearch.mdl.count === 0
                model: ListModel {id: modelTrends}
                width: parent.width
                height: parent.height
                clip: true
                anchors {
                    top: parent.top
                    topMargin: Theme.itemSizeLarge
                    left: parent.left
                    right: parent.right
                    bottom: parent.bottom
                }
                delegate: BackgroundItem {
                    width: parent.width
                    height: Theme.itemSizeSmall
                    Label {
                        anchors.left: parent.left
                        anchors.leftMargin: Theme.horizontalPageMargin
                        anchors.verticalCenter: parent.verticalCenter
                        text: model.name
                        color: (pressed ? Theme.highlightColor : Theme.primaryColor)
                        font.pixelSize: Theme.fontSizeSmall
                    }
                    Label {
                        visible: model.tweets > 0
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.rightMargin: Theme.horizontalPageMargin
                        text: model.tweets.toLocaleString()
                        color: (pressed ? Theme.secondaryHighlightColor : Theme.secondaryColor)
                        font.pixelSize: Theme.fontSizeExtraSmall
                    }
                    onClicked: {
                        searchField.text = tlSearch.search = modelTrends.get(index).name
                    }
                }
                Component.onCompleted: {
                    worker.sendMessage({
                                           'bgAction'  : 'trends_place',
                                           'params'    : { id: 1 },
                                           'model'     : modelTrends,
                                           'mode'      : "append",
                                           'conf'      : Logic.getConfTW()
                                       });
                }
            }
            id: tlSearch;
            property string search;
            onSearchChanged: {
                mdl = Qt.createQmlObject('import QtQuick 2.0; ListModel {   }', Qt.application, 'InternalQmlObject');
                tlSearch.action = "search_tweets"
                //Logic.modelSE.clear()
                tlSearch.vars = {'q' : search }
                loadData("append")

            }
            onTypeChanged: {
                console.log("type changed")
            }
            title: qsTr("Search")
            type: ""
            mdl: ListModel {}
            vars: {}
            conf: Logic.getConfTW()
            width: parent.width
            height: parent.height
            onOpenDrawer:  infoPanel.open = setDrawer
            action: ""
            delegate: CmpTweet { tweet: model}
            header: Item {
                id: header
                width: tlSearchheaderContainer.width
                height: tlSearchheaderContainer.height
                Component.onCompleted: tlSearchheaderContainer.parent = header
            }
            Column {
                id: tlSearchheaderContainer

                width: tlSearch.width

                SearchField {
                    width: parent.width
                    id: searchField
                    placeholderText: qsTr("Search")
                    labelVisible: false
                    EnterKey.iconSource: "image://theme/icon-m-enter-close"
                    EnterKey.onClicked: {
                        tlSearch.search = text
                        focus = false
                    }
                    onTextChanged: {
                        if (text === "")
                            tlSearch.mdl.clear();
                    }
                }
            }
        }

    }

    SlideshowView {
        id: slideshow
        width: parent.width
        height: parent.height
        itemWidth: parent.width
        clip: true
        onCurrentIndexChanged: {
            navigation.slideshowIndexChanged(currentIndex)
        }

        anchors {
            fill: parent
            leftMargin: 0
            top: parent.top
            topMargin: 0
            rightMargin: mainPage.isPortrait ? 0 : infoPanel.visibleSize
            bottomMargin: mainPage.isPortrait ? infoPanel.visibleSize : 0
        }
        model: visualModel
        Component.onCompleted: {
        }
    }

    IconButton {
        anchors {
            right: (mainPage.isPortrait ? parent.right : infoPanel.left)
            bottom: (mainPage.isPortrait ? infoPanel.top : parent.bottom)
            margins: {
                left: Theme.paddingLarge
                bottom: Theme.paddingLarge
            }
        }

        id: newTweet
        width: Theme.iconSizeLarge
        height: width
        visible: !isPortrait ? true : !infoPanel.open
        icon.source: "image://theme/icon-l-add"
        onClicked: {
            pageStack.push(Qt.resolvedUrl("TweetDetails.qml"), {title: qsTrId("new-tweet"), tweetType: "New"})
        }
    }
    function onLinkActivated(href){
        if (href[0] === '#' || href[0] === '@' ) {
            tlSearch.search = href
            slideshow.positionViewAtIndex(3, ListView.SnapToItem)
            navigation.navigateTo('search')

        } else {
            pageStack.push(Qt.resolvedUrl("Browser.qml"), {"href" : href})
        }
    }
    WorkerScript {
        id: worker
        source: "../lib/Worker.js"
        onMessage: {
            if (messageObject.error){
                console.log(JSON.stringify(messageObject))
            }
            if (messageObject.success){
                if (["directMessages", "directMessages_sent"].indexOf(messageObject.action) > -1){
                    generateDirMsgList()
                    if(messageObject.action === "directMessages") {
                    }
                }
            }
        }
    }
    Component.onCompleted: {
        //worker.sendMessage({conf: Logic.getConfTW(), model: Logic.modelDMsent, mode: 'append', bgAction: 'directMessages_sent', params: {count: 10, include_entities: false, full_text: true}});
        /*var store = [];
        for (var i = 0; i < Logic.rec.length; i++){
            console.log(JSON.stringify(Logic.rec[i]))
            //store.push(Logic.parseDM())
        }
        Logic.modelDMreceived.append(store)*/

        var obj = {};
        Logic.mediator.installTo(obj);
        obj.subscribe('bgCommand', function(msg){
            console.log(JSON.stringify(msg))
            worker.sendMessage({conf: Logic.getConfTW(), headlessAction: msg[0].headlessAction, params: msg[0].params});
        })
    }
    function generateDirMsgList(){
        /*console.log("MDL rec " + Logic.modelDMreceived.count)
        console.log("MDL sent " + Logic.modelDMsent.count)
        console.log("MDL DMs " + Logic.modelDM.count)*/
        var msg, i;
        var msgs = [];
        var unique = []

        // curent state
        //console.log("TRAZIM TRENUTNE //////////////////////////////////////////////")
        for(i = 0; i < Logic.modelDM.count; i++){
            unique.push(Logic.modelDM.get(i).sender_id);
        }
        //console.log(JSON.stringify(unique))
        //console.log("STVARAM LISTU  //////////////////////////////////////////////")

        for(i = 0; i < Logic.modelDMreceived.count; i++){
            msg = Logic.modelDMreceived.get(i);
            if (unique.indexOf(msg.sender_id) === -1) {
                msg['revert'] = false;
                msgs.push(msg)
                unique.push(msg.sender_id);
            }
        }
        //console.log(JSON.stringify(unique))
        //console.log("//////////////////////////////////////////////")
        for(i = 0; i < unique.length; i++){
            for(var j = 0; j < Logic.modelDMsent.count; j++){
                msg = Logic.modelDMsent.get(j);
                if (unique[i] === msg.recipient_id && Logic.modelDM.count > 0) {
                    if (Logic.modelDM.get(i).created_at < msg.created_at) {
                        Logic.modelDM.set(i, {
                                              created_at: msg.created_at,
                                              text: msg.text,
                                              section: msg.section,
                                              revert: true
                                          });
                    }

                    break;
                }
            }
        }
        /*var reSort = [];


        for(i = 0; i < Logic.modelDM.count; i++){
            reSort.push(Logic.modelDM.get(i))
        }
        console.log(JSON.stringify(reSort))
        reSort.sort(function(a,b){
            return (a.created_at > b.created_at)
        })*/

        //Logic.modelDM.clear();
        Logic.modelDM.append(msgs)
        //console.log(JSON.stringify(unique))
    }
}



