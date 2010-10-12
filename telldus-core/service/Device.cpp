#include "Device.h"

class Device::PrivateData {
public:
	std::wstring name;
	Protocol* protocol;
};

Device::Device(){

	d = new PrivateData;
	//vid skapande, h�mta settings fr�n registret, vissa s�tts i protokollet, vid dess skapande
	//n�r n�got uppdateras, spara ocks� till registret
	//Denna klass har alla metoder (turnOn, turnOff etc)... 
	//Men t.ex. att om modellen �r bell, d� ska turnon returnera bell... eller isDimmer, ska returnera annat... hur g�ra? - l�t vara i samma klass till att b�rja med
	//Men skulle egentligen vilja ha tagit st�llning till modell redan i initieringen... �tminstone spara undan det i en egen variabel
}

Device::~Device(void) {
	delete d->protocol;
	delete d;
}

std::wstring Device::getName(){
	return d->name;
}

int Device::turnOn(Controller *controller) {
	Protocol *p = this->retrieveProtocol();

	//p->turnOn(controller);
	return 0;
}

Protocol *Device::retrieveProtocol() {
	if (d->protocol) {
		return d->protocol;
	}

	d->protocol = new Protocol();
	return d->protocol;
}