#include "ClientMessageHandler.h"

class ClientMessageHandler::PrivateData {
public:
	std::wstring clientMessage;
};

ClientMessageHandler::ClientMessageHandler(const std::wstring &clientMessage)
	:Thread()
{
	d = new PrivateData;
	d->clientMessage = clientMessage;
	
}

ClientMessageHandler::~ClientMessageHandler(void)
{
	delete d;
}

void ClientMessageHandler::run(){
	//run thread
	if(d->clientMessage == L"tdGetNumberOfDevices"){
		//starta ny tr�d (ny klass, �rv fr�n Thread)
		//skicka in meddelandet i denna tr�d
		//kolla d�r vad det �r f�r meddelande
		//do stuff
		//TODO
	}
}


