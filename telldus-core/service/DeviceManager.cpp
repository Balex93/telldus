#include "DeviceManager.h"
#include "Device.h"

#include <map>

class DeviceManager::PrivateData {
public:
	std::map<int, Device> devices;
};

DeviceManager::DeviceManager(){
	d = new PrivateData;
	fillDevices();
}

DeviceManager::~DeviceManager(void) {
	//delete d->devices;
	delete d;
}

void DeviceManager::fillDevices(){
	//foreach device i registret
		//h�mta id, l�t devicen sj�lv s�tta sina v�rden i constructorn
		//l�gg till i devices-listan
}
