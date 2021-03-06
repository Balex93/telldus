import Qt 4.7
import "schedulerscripts.js" as Scripts
import "actionpointscripts.js" as ActionPointScripts

Rectangle{
	id: pointRect
	property string actionTypeColor: "blue" //TODO default value
	property int actionType: 1 //TODO default value
	property int dimvalue: 50  //percent, recalucluate it before use
	property double actionTypeOpacity: 1
	property string actionTypeImage: imageActionOn
	property string isPoint: "true"
	property variant isLoaded
	//property int xvalue
	property int fuzzyBefore: 0
	property int fuzzyAfter: 0
	property int offset: -100
	property int absoluteHour: parseInt(dialog.absoluteHour, 10)
	property int absoluteMinute: parseInt(dialog.absoluteMinute, 10)
	property alias triggerstate: trigger.state
	property variant parentPoint: undefined
	property variant pointId
	property variant lastRun: 0;
	property alias deviceRow: pointRect.parent
	property variant selectedDate: (deviceRow == null || deviceRow == undefined) ? new Date() : deviceRow.selectedDate
	property int daydate: (deviceRow == null || deviceRow == undefined || deviceRow.parent == undefined || deviceRow.parent.parent == undefined) ? -1 : deviceRow.parent.parent.daydate.getDay()
	
	
	Component.onCompleted: {
		//TODO useless really, still gets Cannot anchor to a null item-warning...
		isLoaded = "true"
		var actionBar = Qt.createComponent("ActionBar.qml")
		var dynamicBar = actionBar.createObject(pointRect)
		dynamicBar.hangOnToPoint = pointRect
		dynamicBar.state = "pointLoaded"
	}
	
	//use item instead of rectangle (no border then though) to make it invisible (opacity: 0)
	width: constPointWidth
	height: constDeviceRowHeight
	border.color: "black"
	opacity: 1 //0.8
	z: 100
	state: "on"
	focus: true
	
	//reflect changes on parent/siblings:
	onAbsoluteHourChanged: {
		updateChanges();
	}
	
	onAbsoluteMinuteChanged: {
		updateChanges();
	}
	
	onFuzzyBeforeChanged: {
		updateChanges();
	}
	
	onFuzzyAfterChanged: {
		updateChanges();
	}
	
	onOffsetChanged: {
		updateChanges();
	}
	
	onDimvalueChanged: {
		updateChanges();
		updateBars();
	}
	
	onStateChanged: {
		updateChanges();
	}
	
	MouseArea {
		id: pointRectMouseArea
		acceptedButtons: Qt.LeftButton | Qt.RightButton
		
		onClicked: {
			if (mouse.button == Qt.RightButton){
				pointRect.toggleType()
			}
		}
		
		onPositionChanged: {
			var rootCoordinates = pointRect.mapToItem(pointRect.parent, mouse.x, mouse.y);
			var hourMinute = getTimeFromPosition(rootCoordinates.x - mouse.x + pointRect.width/2)
			if((hourMinute[0] >= 0) && hourMinute[0] < 24){
				pointRect.absoluteHour = hourMinute[0]
				pointRect.absoluteMinute = hourMinute[1]
			}
		}
		
		onReleased: {
			pointRect.deviceRow.setChanged();
			pointRect.deviceRow.updateContinuingBars()
			dialog.show(pointRect)  //TODO not pointRect, but parentPoint if such exists
			dialog.absoluteHour = Scripts.pad(pointRect.absoluteHour, 2)
			dialog.absoluteMinute = Scripts.pad(pointRect.absoluteMinute, 2)
			
			if(parentPoint != undefined){
				parentPoint.absoluteHour = parseInt(dialog.absoluteHour, 10);
				parentPoint.absoluteMinute = parseInt(dialog.absoluteMinute, 10);
			}
		}
		
		anchors.fill: parent
		drag.target: pointRect
		drag.axis: Drag.XAxis
		drag.minimumX: -1 * pointRect.width/2
		drag.maximumX: pointRect.parent == null ? 0 : pointRect.parent.width - pointRect.width/2
		drag.filterChildren: true
		//TODO make it impossible to overlap (on release) (why?)
		//TODO drag to most right - jumps back, why?
		
		states: State{
			id: "hidden"; when: pointRectMouseArea.drag.active
			PropertyChanges { target: pointRect; opacity: 0.5; }
		}
	}
	
	Column{
		spacing: 10
		anchors.horizontalCenter: parent.horizontalCenter
				
		Image {
			//opacity: 1
			id: actionImage
			width: 20; height: 20
			source: pointRect.actionTypeImage
		}
		
		Rectangle{
			id: trigger
			anchors.horizontalCenter: parent.horizontalCenter
				
			state: "absolute"
			width: 20; height: 20
			
			//TODO state should move the point to correct place... (sunrisetime, sunsettime or absolute (stored value, the one that is dragged)
			states: [
				State {
					//TODO if no sunrise/sunset exists (arctic circle...), check so it works anyway
					name: "sunrise"
					PropertyChanges { target: triggerImage; source: imageTriggerSunrise; opacity: 1 }
					PropertyChanges { target: triggerTime; opacity: 0 }
					PropertyChanges { target: pointRectMouseArea; drag.target: undefined }
					PropertyChanges { target: pointRect; x: getSunRiseTime.callWith(pointRect.parent.width, pointRect.width, pointRect.selectedDate) + minutesToTimelineUnits(pointRect.offset) }
				},
				State {
					name: "sunset"
					PropertyChanges { target: triggerImage; source: imageTriggerSunset; opacity: 1 }
					PropertyChanges { target: triggerTime; opacity: 0 }
					PropertyChanges { target: pointRectMouseArea; drag.target: undefined }
					PropertyChanges { target: pointRect; x: getSunSetTime.callWith(pointRect.parent.width, pointRect.width, pointRect.selectedDate) + minutesToTimelineUnits(pointRect.offset) }
				},
				State {
					name: "absolute"; when: !pointRectMouseArea.drag.active
					PropertyChanges { target: triggerImage; opacity: 0; }
					PropertyChanges { target: triggerTime; opacity: 1 }
					PropertyChanges { target: pointRectMouseArea; drag.target: parent }
					//PropertyChanges { target: pointRect; x: xvalue }
					PropertyChanges { target: pointRect; x: getAbsoluteXValue() }
				}
			]
			
			Rectangle{
				id: triggerTime
				opacity: 1
				width: 20; height: 20
				anchors.centerIn: parent
				Text{
					text: getTime(pointRect.x, pointRect.width); font.pointSize: 6; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignBottom
				}
			}
			
			Image {
				id: triggerImage
				opacity: 0
				anchors.fill: parent
				width: 20; height: 20
				source: imageTriggerAbsolute
			}
		}
	}
	
	states: [
		State {
			name: "on"
			PropertyChanges { target: pointRect; actionTypeColor: "blue"; actionTypeOpacity: 1 } 
			PropertyChanges { target: pointRect; actionTypeImage: imageActionOn }
			StateChangeScript{ name: "updateBars"; script: updateBars(); }
		},
		State{
			name: "off"
			PropertyChanges { target: pointRect; actionTypeColor: "gainsboro"; actionTypeOpacity: 0 }
			PropertyChanges { target: pointRect; actionTypeImage: imageActionOff }
			StateChangeScript{ name: "updateBars"; script: updateBars(); }
		},
		State{
			name: "dim"
			PropertyChanges { target: pointRect; actionTypeColor: "green"; actionTypeOpacity: dimvalue/100 }
			PropertyChanges { target: pointRect; actionTypeImage: imageActionDim }
			StateChangeScript{ name: "updateBars"; script: updateBars(); }
		},
		State{
			name: "bell"
			PropertyChanges { target: pointRect; actionTypeColor: getLastPointColor() }
			PropertyChanges { target: pointRect; actionTypeImage: imageActionBell }
			StateChangeScript{ name: "updateBars"; script: updateBars(); }
		}
	]
	
	Rectangle{
		//TODO continue fuzzy too into next/prev day
		width: minutesToTimelineUnits(fuzzyAfter + fuzzyBefore)
		height: constBarHeight
		anchors.verticalCenter: parent.verticalCenter
		x: parent.width/2 - minutesToTimelineUnits(fuzzyBefore)
		opacity: 0.2
		z: 140
		
		Image{
			anchors.fill: parent
			fillMode: Image.Tile
			source: "fuzzy.png"
		}
	}
	
	function updateBars(){
		if(pointRect.deviceRow != undefined){
			pointRect.deviceRow.updateContinuingBars();
		}
	}
	
	function getAbsoluteXValue(){
		if(pointRect.parent == null){
			return 0;
		}
		var hourSize = pointRect.parent.width / 24;
		var point = pointRect;
		if(pointRect.parentPoint != undefined){
			point = pointRect.parentPoint;
		}
		//print("ABSOLUTE X-value: " + (point.absoluteHour * hourSize + hourSize * (point.absoluteMinute/60) - point.width/2));
		//print("AbsoluteHour: " +point.absoluteHour+ " hourSize: " + hourSize + " AbsoluteMinute: " + point.absoluteMinute + " Width: " + point.width); 
		return point.absoluteHour * hourSize + hourSize * (point.absoluteMinute/60) - point.width/2;
	}
	
	function toggleType(){ //TODO other kind of selection method
		var index = 0;
		var activeStates = ActionPointScripts.getActiveStates();
		if(activeStates == undefined || activeStates.length == 0){
			return;
		}
		
		for(var i=0;i<activeStates.length;i++){
			if (activeStates[i] == state) {
				index = i + 1;
				break;
			}
		}
		if(index == activeStates.length){
			index = 0; //return to beginning again
		}
		pointRect.state = activeStates[index];
	}
	
	function setType(name){
		pointRect.state = name;
	}
	
	function toggleTrigger(){ //TODO other kind of selection method
		if(trigger.state == "sunrise"){
			trigger.state = "sunset";
		}
		else if(trigger.state == "sunset"){
			trigger.state = "absolute";
			pointRect.x = getAbsoluteXValue();
		}
		else if(trigger.state == "absolute"){
			//pointRect.xvalue = pointRect.x;
			trigger.state = "sunrise";
		}
		ActionPointScripts.updateParentWithCurrentValues();
		ActionPointScripts.updateChildPoints();
	}
	
	function updateChanges(){
		if(pointRect.deviceRow == null || (pointRect.deviceRow.isLoading != undefined && pointRect.deviceRow.isLoading())){
			return; //loading values from storage, wait until everything is in place
		}
		ActionPointScripts.updateParentWithCurrentValues();
		ActionPointScripts.updateChildPoints();
		if(pointRect.triggerstate == "absolute"){
			pointRect.x = getAbsoluteXValue();	
		}
	}
	
	function getLastPointColor(){
		//get previous point:
		var prevPoint = null;
		var pointList = pointRect.parent.children;
		for(var i=1;i<pointList.length;i++){
			if (pointList[i].isPoint != undefined && pointList[i] != pointRect) {
				if(pointList[i].x < pointRect.x && (prevPoint == null || pointList[i].x > prevPoint.x)){
					prevPoint = pointList[i];
				}
			}
		}
		
		if(prevPoint == null || prevPoint.actionTypeOpacity == 0){
			//no point before, no bar after either
			actionTypeOpacity = 0
			return "papayawhip" //just return a color, will not be used
		}
		
		actionTypeOpacity = prevPoint.actionTypeOpacity
		return prevPoint.actionTypeColor
	}
	
	function getTime(){
		if(pointRect.parent == null){
			return "";
		}
		
		var hours = Scripts.pad(pointRect.absoluteHour, 2);
		var minutes = Scripts.pad(pointRect.absoluteMinute, 2);
		return hours + ":" + minutes;
	}
	
	function getTimeFromPosition(mouseX){
		if(pointRect.parent == null){
			return [0,0];
		}
		var timeOfDay = mouseX;
		var hourSize = pointRect.parent.width / 24;
		var hours = Math.floor(timeOfDay / hourSize);
		var partOfHour = ((timeOfDay - (hourSize * hours))/hourSize) * 60
		partOfHour = Math.floor(partOfHour);
		partOfHour = Scripts.pad(partOfHour, 2);
		hours = Scripts.pad(hours, 2);
		return [hours, partOfHour];
	}
	
	function addActiveState(state){
		ActionPointScripts.addActiveState(state);
	}
	
	function setActiveStates(activeStates){
		ActionPointScripts.setActiveStates(activeStates);
	}
	
	function getActiveStates(){
		return ActionPointScripts.getActiveStates();
	}
	
	function setFirstState(firstState){
	
		var activeStates = ActionPointScripts.getActiveStates();
		
		if(activeStates == null || activeStates.length == 0){
			//nothing to do
			return;
		}
		
		//state may already be set:
		if(firstState != undefined && firstState != ""){
			pointRect.state = firstState;
			return;
		}
		
		//check that device has the "off" state:
		var exists = false;
		for(var i=1;i<activeStates.length;i++){
			if(activeStates[i] == "off"){
				exists = true;
				break;
			}
		}
		if(!exists){
			//no "off", just set state to the first added state
			
			pointRect.state = activeStates[0];
			return;
		}
		
		var previousState = ActionPointScripts.getPreviousState(pointRect);
		if(previousState == undefined || previousState == "" || previousState == "off"){
			//nothing on/dimmed at the moment, use first added state
			pointRect.state = activeStates[0];
			return;
		}
		
		pointRect.state = "off"; //previous point should be "on" or "dim"														 
	}
	
	function remove(keepDialogOpen, ignoreParent){
		if(keepDialogOpen == undefined && ignoreParent == undefined && pointRect.parentPoint != undefined){
			//remove from parent instead
			print(pointRect.parentPoint);
			pointRect.parentPoint.remove();
			return;
		}
		if(pointRect.hangOnToBar != null){
			hangOnToBar.destroy();
		}
		var x = pointRect.x;
		pointRect.isPoint = "false"
		var pointList = pointRect.parent.children;
		var deviceRow = pointRect.deviceRow;
		var childPoints = ActionPointScripts.getChildPoints();
		for(var child in childPoints){
			childPoints[child].remove(keepDialogOpen, "ignoreParent");
			delete childPoints[child];
		}
		pointRect.destroy();
		if(keepDialogOpen == undefined){
			dialog.hide();
		}
		deviceRow.updateContinuingBars();
	}
	
	function minutesToTimelineUnits(minutes){
		if(pointRect.parent == null){
			return 0;
		}
		return pointRect.parent.width/24 * (minutes/60);
	}
	
	function getTickedImageSource(index){
		index = Scripts.getOffsetWeekday(index);
		if(pointRect.deviceRow.parent == undefined || pointRect.deviceRow.parent.parent == undefined){ //to get rid of warnings on initialization
			//undefined, should only be in the beginning
			return "unticked.png";
		}
		var originalPoint = pointRect;
		if(pointRect.parentPoint != undefined){
			originalPoint = pointRect.parentPoint;
		}
		if(index == pointRect.daydate){
			//current day should always be ticked
			return "alwaysticked.png";
		}
		else if(originalPoint.getChildPoint(index) == undefined && index != originalPoint.daydate){
			return "unticked.png";
		}
		else{
			return "ticked.png";
		}
	}
	
	function toggleTickedWeekDay(index){
		index = Scripts.getOffsetWeekday(index);
		var originalPoint = pointRect;
		if(pointRect.parentPoint != undefined){
			originalPoint = pointRect.parentPoint;
		}
		if(index == pointRect.daydate){
			//cannot change this, do nothing
			return;
		}
		if(index == originalPoint.daydate){
			//trying to remove the parentPoint, special removal procedure needed
			originalPoint.removeParentPoint(pointRect);
		}
		else if(originalPoint.getChildPoint(index) == undefined){
			print("CREATE NEW POINT");
			originalPoint.addChildPoint(index, deviceRow.createChildPoint(index, pointRect, deviceRow.deviceId));
			pointRect.deviceRow.updateContinuingBars();
		}
		else{
			print("REMOVE A POINT");
			originalPoint.removeChildPoint(index);
			pointRect.deviceRow.updateContinuingBars();
		}
	}
	
	function getChildPoint(index){
		return ActionPointScripts.getChildPoint(index);
	}
	function getChildPoints(){
		return ActionPointScripts.getChildPoints();
	}
	function addChildPoint(index, point){
		ActionPointScripts.addChildPoint(index, point);
	}
	function removeChildPoint(index){
		ActionPointScripts.removeChildPoint(index);
	}
	function removeParentPoint(newParentPoint){
		ActionPointScripts.removeParentPoint(newParentPoint);
	}
	function setChildPoints(childPoints){
		ActionPointScripts.setChildPoints(childPoints);
	}
	function updateChildPoints(){
		ActionPointScripts.updateChildPoints();
	}
}
