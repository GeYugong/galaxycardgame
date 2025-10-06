#ifndef MENU_HANDLER_H
#define MENU_HANDLER_H

#include <irrlicht.h>
#include "replay.h"

namespace ygo {

class MenuHandler: public irr::IEventReceiver {
public:
	bool OnEvent(const irr::SEvent& event) override;
	void ShowReplayWindow();

	irr::s32 prev_operation{ 0 };
	int prev_sel{ -1 };
	Replay temp_replay;

	//replay
	irr::gui::IGUIWindow* wReplay = nullptr;
	irr::gui::IGUIListBox* lstReplayList = nullptr;
	irr::gui::IGUIStaticText* stReplayInfo = nullptr;
	irr::gui::IGUIButton* btnLoadReplay = nullptr;
	irr::gui::IGUIButton* btnDeleteReplay = nullptr;
	irr::gui::IGUIButton* btnRenameReplay = nullptr;
	irr::gui::IGUIButton* btnReplayCancel = nullptr;
	irr::gui::IGUIButton* btnExportDeck = nullptr;
	irr::gui::IGUIEditBox* ebRepStartTurn = nullptr;

	void ShowSinglePlayWindow();
	//single play
	irr::gui::IGUIWindow* wSinglePlay = nullptr;
	irr::gui::IGUIListBox* lstBotList = nullptr;
	irr::gui::IGUIStaticText* stBotInfo = nullptr;
	irr::gui::IGUIButton* btnStartBot = nullptr;
	irr::gui::IGUIButton* btnBotCancel = nullptr;
	irr::gui::IGUIComboBox* cbBotDeckCategory = nullptr;
	irr::gui::IGUIComboBox* cbBotDeck = nullptr;
	irr::gui::IGUIComboBox* cbBotRule = nullptr;
	irr::gui::IGUICheckBox* chkBotHand = nullptr;
	irr::gui::IGUICheckBox* chkBotNoCheckDeck = nullptr;
	irr::gui::IGUICheckBox* chkBotNoShuffleDeck = nullptr;
	irr::gui::IGUIListBox* lstSinglePlayList = nullptr;
	irr::gui::IGUIStaticText* stSinglePlayInfo = nullptr;
	irr::gui::IGUICheckBox* chkSinglePlayReturnDeckTop = nullptr;
	irr::gui::IGUIButton* btnLoadSinglePlay = nullptr;
	irr::gui::IGUIButton* btnSinglePlayCancel = nullptr;
};

}

#endif //MENU_HANDLER_H
