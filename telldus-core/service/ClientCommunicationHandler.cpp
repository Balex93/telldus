#include "ClientCommunicationHandler.h"

class ClientCommunicationHandler::PrivateData {
public:
	std::wstring clientMessage;
};

ClientCommunicationHandler::ClientCommunicationHandler(const std::wstring &clientMessage)
	:Thread()
{
	d = new PrivateData;
	d->clientMessage = clientMessage;
	
}

ClientCommunicationHandler::~ClientCommunicationHandler(void)
{
	delete d;
}

void ClientCommunicationHandler::run(){
	//run thread

//	std::wstring clientMessage = s->read();

	if(d->clientMessage == L"tdGetNumberOfDevices"){
		//starta ny tr�d (ny klass, �rv fr�n Thread)
		//skicka in meddelandet i denna tr�d
		//kolla d�r vad det �r f�r meddelande
		//do stuff
		//TODO
	}

//	delete s;	//TODO: Cleanup
}


