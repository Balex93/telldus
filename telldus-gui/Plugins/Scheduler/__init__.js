__setupPackage__( __extension__ );

__postInit__ = function() {
	application.allDoneLoading.connect( com.telldus.scheduler.init );
}
	
com.telldus.scheduler = function() {
	
	var storedJobs = new MappedList();
	var joblist;
	var timerid;
	var queuedJob;
	
	
	//1. hämta redan satta jobb
	//(kolla om något jobb borde ha körts sedan förra ggn (och att det inte kördes då))
	//2. räkna ut när de ska köras nästa ggn, inkludera solens upp/nergång, fuzziness etc
	//3. ordna i lista, spara undan första tidsvärdet enkelt åtkomligt
	//4. kör tills tidsvärdet <= timestamp, kolla en ggn/sekund...
	
	// räkna om varje ggn ngn ändring sker med tider, läggs till/tas bort...


	//hur ska jobb sparas?
	//vilka typer av tider ska finnas?
	// absoluta värden - ett enda tillfälle
	// fr.o.m viss tidpunkt:
	// återkommande, viss tid varje dag
	// återkommande, viss tid vissa veckodagar (ev. var x:e vecka) (samlat i ett jobb, eller samma tid för alla markerade dagar?)
	// återkommande, viss tid vissa dagar i månaden (datum och "siste", eventuellt (är detta någonsin intressant för tellstickstyrning?) första-andra-tredje-fjärde-sista veckodagen i månaden)
	// återkommande, viss tid var x:e dag (hyfsat enkelt att implementera, men är detta intressant för tellstickstyrning?)
	// fuzzy på alla, x min före och x min efter (kan klart sättas till noll), vid TelldusCenter-start slumpas ett absolutvärde inom detta intervall fram
	// solens upp/nedgång kan väljas som tidpunkt på alla dagar
	// viss tid från viss action bestäms från den actionen, om t.ex. en scen ska utföra ngt efter en viss tid så får den göra ett exakt-tid-tillägg (hur det ska fungera vet jag inte, 
			//men tycker att scener ska kunna innehålla tidsfördröjningar mha detta... Men hur återuppta scen liksom? Kanske kunde man låta "värde" i en scen vara from vilket steg det ska
			//återupptas? Varför inte? I framtiden alltså. Execute får alltså ett värde (default inget = från start))
	// varje jobbtidpunkt måste alltså lagras som: 
	// ----------------------------
	// typ - dagintervall (det normala, 1), - viss veckodag (lista med aktiva veckodagar), - viss dag i månaden, speciellt värde för "den siste", - speciella tidpunkt(er)
	// varje dag/tidpunkt kan ha följande värden (om man gör det per dag):
		// fuzzy innan
		// fuzzy efter
		// använd solens uppgång/nedgång/absolut tidpunkt
		// på/avdrag från solens upp/nedgång
	// startdag
	// tid för föregående körning, om någon
	// -------------------------------
	// Framtidssäkring: condition för t.ex. väderstation - nej, inga conditions finns ännu... vill man ha det i framtiden?
	// typ, när schemat ska exekveras, kolla om ngt är uppfyllt... Nej, det får i så fall ske i en scen (inte scen, något annat mellansteg i TelldusCenter (inte tellduscore)...
	// när scenen körs, kolla väderdata, om det är gråmulet=tänd, annars kör scen som pausar i 30 minuter och tänder då...
	// Samma sak med villkoret "hemma" och "borta"... Det får vara per scen (mellanstegsscen). Andra events (t.ex. rörelsekontrollevents) vill ju vara villkorade på precis samma sätt,
	// alltså kör scenen om villkoret är "borta" eller temperatur < -10...
	// Och en mellanstegsscen kan (ska kunna innehålla) en "stopscen" som ska köras en viss tid senare (t.ex. låta ljuset vara igång i 2 minuter, sedan släcka), då skapar scenen
	// ett nytt schemajobb med argumentet +2 minuter...
	// solen går upp/ner +/- visst antal minuter...
	// hur kommer net:en + schemaläggare att fungera? Kommer det att finnas en webvariant?
	//jobben i listan = deviceid (även grupp/scen såklart), action, värde. En enda / jobb, får grupperas med grupper/scener om man vill att mer ska hända på en ggn
	//"repeat", t.ex. om villkor inte uppfylls så vill man göra ett nytt försök, även det får vara en funktion i extended scen/makro. if->false->tryAgainAfterXSeconds...
	
	//TODO ordna upp, dela upp i flera filer, inte ladda jobb här (per plugin istället), bara "add job" här...
	//var ska "job" och "event" vara? Går det att ha inne i scheduler på ngt sätt? (och ändå kunna ärva utifrån)
	//eller ha dem som egna "klasser"?
	//ta bort loadJobs
	//updateLastRun... måste anpassas för storage... på defaultjobben alltså...
	//TODO ta bort absoluta events efter att de har passerats? Kan inte göras härifrån, får på ngt sätt ske därifrån de sparas/laddas
	//det enda varje jobb har är getNextRunTime (som ska override:as) (och ev. updateLastRun)
	//TODO nextRunTime = 0 ska ju inte köras, men negativa värden ska ju köras ibland (med graceTime)

	
	function init(){
		JobDaylightSavingReload.prototype = new com.telldus.scheduler.Job();
		loadJobs(); //load jobs from permanent storage TODO move
	}
	
	
	function addJob(job){
		if(storedJobs.length == 0){
			print("Adding daylight saving time");
			var daylightSavingReloadKey = storedJobs.push(getDaylightSavingReloadJob());
			updateJobInList(daylightSavingReloadKey);
		}
		var key = storedJobs.push(job);
		job.key = key;
		print("Add job");
		updateJobInList(key);
		return key;
	}
	
	function fuzzify(currentTimestamp, fuzzinessBefore, fuzzinessAfter){
		if(fuzzinessAfter != 0 || fuzzinessBefore != 0){
			var interval = fuzzinessAfter + fuzzinessBefore;
			var rand =  Math.random(); //Random enough at the moment
			var fuzziness = Math.floor((interval+1) * rand);
			fuzziness = fuzziness - fuzzinessBefore;
			currentTimestamp += (fuzziness * 1000);
		}
		return currentTimestamp;
	}
	
	function getDaylightSavingReloadJob(){
		return new JobDaylightSavingReload();
	}
	
	function recalculateAllJobs(){
		print("Recalculating all jobs");
		
		joblist = new Array();
		
		for(var key in storedJobs.container){
			var job = storedJobs.get(key);
			var nextRunTime = job.getNextRunTime();
			print("Run time: " + new Date(nextRunTime));
			if(nextRunTime === null){
				print("Will not run");
				continue;
			}
			joblist.push(new RunJob(key, nextRunTime));
		}
			
		joblist.sort(compareTime);
		runNextJob();
	}
	
	function removeFromJobList(id){
		if(!joblist){
			return;
		}
		for(i=0;i<joblist.length;i++){
			if(id==joblist[i].id){
				joblist.splice(i, 1);
				return;
			}
		}
	}
	
	function removeJob(id){
		storedJobs.remove(id);
		updateJobInList(id);
		if(storedJobs.length == 1){
			//only one job left, it's only the DaylightSaving reload job, remove that too
			for(var key in storedJobs.container){
				storedJobs.remove(key);
				updateJobInList(key);
			}
		}
	}
	
	function runJob(id){
		print("Running job, will execute");
		queuedJob = null;
		var success = storedJobs.get(id).execute();
		print("Job run, after delay " + id);
		updateJobInList(id);	
	}
	
	function runNextJob(){
		clearTimeout(timerid);
		print("Timer interrupted");
		if(joblist.length <= 0){
			print("No jobs");
			return; //no jobs, abort
		}
		if(queuedJob){
			//put the currently queued job back in the list, so that it can be compared again
			print("Queued job is something, put it back in list");
			joblist.push(queuedJob);
			joblist.sort(compareTime);
		}
		
		var job = joblist.shift(); //get first job in list (and remove it from the list)
		queuedJob = job; //put it in list, to keep track of current job
		var nextRunTime = job.nextRunTime;
		
		if(nextRunTime === null){
			//something is wrong
			print("Something is wrong");
			updateJobInList(job.id); //This will just recalculate the job, and probably return 0 again, but updateJobInList won't add it to the list in that case (shouldnt end up here at all now actually)
			return;
		}
		
		var runJobFunc = function(){ runJob(job.id); };
		var now = new Date().getTime();
		var delay = nextRunTime - now;
		print("Will run " + storedJobs.get(job.id).v.name + " (" + job.id + ") at " + new Date(nextRunTime)); //Note not all will have a name
		print("(Now is " + new Date() + ")");
		print("Delay: " + delay);
		timerid = setTimeout(runJobFunc, delay); //start the timer
		print("Has started a job wait");
	}
	
	function updateJobInList(id){
		if(!joblist){
			joblist = new Array();
		}
		
		if(!storedJobs.contains(id)){
			removeFromJobList(id);
			runNextJob();
			return;
		}
		var job = storedJobs.get(id);
		var nextRunTime = job.getNextRunTime();
		print("Time updated to: " + new Date(nextRunTime));
		
		if(nextRunTime === null){
			print("Will not run this one");
			removeFromJobList(id); //remove from joblist if it exists there (run time may have been updated to something invalid/already passed)
			runNextJob(); //resort list (may have changed), run next
			return;
		}
		
		joblist.push(new RunJob(id, nextRunTime));
		
		joblist.sort(compareTime);
		runNextJob();
	}
	
	function updateJob(key, job){
		if(!storedJobs.contains(key)){
			return;
		}
		storedJobs.update(key, job);
		updateJobInList(key);
	}
	
	function updateLastRun(id, lastRun){
		print("Update last run: " + id + " to " + lastRun);
		storedJobs.get(id).v.lastRun = lastRun; //update current list
	}
	
	
	function JobDaylightSavingReload(){}
	
	JobDaylightSavingReload.prototype.execute = function(){
		//override default
		print("Daylight savings job");
		//TODO Make sure this job is run "last", if other jobs are set to be runt the same second
		setTimeout(recalculateAllJobs(), 1); //sleep for one ms, to avoid strange calculations
		//this may lead to that things that should be executed exactly at 3.00 when
		//moving time forward one hour won't run, but that should be the only case
		return 0;
	};
	
	JobDaylightSavingReload.prototype.getNextRunTime = function(){
		print("getNextRunTime DaylightSaving");
		var dst = DstDetect();
		if(dst[0] == ""){
			//not using dst in this timezone, still add it to the lists to keep it consistent (will be added as 1/1 1970)
			print("Not using timezone");
			return null;
		}
		var now = new Date().getTime();
		var time = dst[0].getTime();
		if(now > time){
			//already passed
			time = dst[1].getTime();
		}
		return time;
	}
	
	
	function MappedList() {
		this.container = {};
		this.length = 0;
	}
	
	MappedList.prototype.contains = function(key){
		return !(this.container[key] === undefined);
	}
	
	MappedList.prototype.get = function(key){
		return this.container[key];
	}
	
	MappedList.prototype.push = function(element){
		//TODO reusing keys at the moment, that's ok, right?
		var length = this.length;
		this.container[length] = element;
		this.length = length + 1;
		return length;
	}
	
	MappedList.prototype.remove = function(key){
		delete this.container[key];
		this.length--;
	}
	
	MappedList.prototype.update = function(key, element){
		this.container[key] = element;
	}

	function RunJob(id, nextRunTime){ //, type, device, method, value){
		this.id = id;
		this.nextRunTime = nextRunTime;
	}	

	return { //Public functions
		addJob: addJob, //job, returns: storage id
		fuzzify: fuzzify, //timestamp, max fuzziness before, max fuzziness after, returns: new random timestamp within min/max fuzziness-boundries
		removeJob: removeJob, //storage id
		updateJob: updateJob, //storage id, job
		updateLastRun: updateLastRun, //id, datetimestamp
		//TODO getNextRunForJob? For all? (to see when job is due to run next)
		init:init
	}
}();

function compareTime(a, b) {
	return a.nextRunTime - b.nextRunTime;
}

com.telldus.scheduler.Job = function(jobdata) {
	if(jobdata){
		this.v = jobdata;
	}
	else{
		this.v = {};
	}
}

com.telldus.scheduler.Job.prototype.execute = function(){
	//may be overridden if other than device manipulation should be performed
	var success = 0;
	print("Job id: " + this.v.deviceid);
	deviceid = this.v.deviceid;
	var method = parseInt(this.method);
	switch(method){
		case com.telldus.core.TELLSTICK_TURNON:
			success = com.telldus.core.turnOn(deviceid);
			break;
		case com.telldus.core.TELLSTICK_TURNOFF:
			success = com.telldus.core.turnOff(deviceid);
			break;
		case com.telldus.core.TELLSTICK_DIM:
			success = com.telldus.core.dim(deviceid, this.v.value);
			break;
		case com.telldus.core.TELLSTICK_BELL:
			success = com.telldus.core.bell(deviceid);
			break;	
		default:
			break;
	}
	//if(success){
		//update last run even if not successful, else it may become an infinite loop (if using pastGracePeriod)
		this.updateJobLastRun();
	//}
	return success;
};

com.telldus.scheduler.Job.prototype.getNextRunTime = function(){
	print("getNextRunTime default");
	return null; //default
}

com.telldus.scheduler.Job.prototype.updateJobLastRun = function(){
	var timestamp = new Date().getTime();
	com.telldus.scheduler.updateLastRun(this.key, timestamp);
	//override this to save last run to storage too, but don't forget to call the above method too		
}

include("DefaultJobTypes.js");
include("DaylightSavingTime.js");