#include "EventUpdateManager.h"

class EventUpdateManager::PrivateData {
public:

};

EventUpdateManager::EventUpdateManager(){
	d = new PrivateData;
}

EventUpdateManager::~EventUpdateManager(void) {
	/*
	for (ControllerMap::iterator it = d->controllers.begin(); it != d->controllers.end(); ++it) {
		delete( it->second );
	}
	*/
	delete d;
}

void EventUpdateManager::sendUpdateMessage(int eventDeviceChanges, int eventChangeType, int eventMethod, int deviceType, int deviceId){
	/*
	for(){
		if(isalive){
			
			it++;
		}
		else{
			//ta bort
			delete *it;
			it = ngt.erase(it);
		}
	}
	*/

	//meddela alla klienter i listan 
				//eventdata - vad som har h�nt
				//m�ste kolla s� att de inte har kopplats ifr�n, ta bort fr�n listan d� ocks�
				//t�mma listan vid delete, deletea respektive
}