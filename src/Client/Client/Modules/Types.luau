local Types = {}

export type ButtonConfig = {
	Icon: string,
	AppName: string,
	Background: string,
	Description: string,
	MainButtonClick: () -> (),
	MainButtonFrame: Frame | CanvasGroup?,

	SubIcons: {
		{
			Icon: string,
			Name: string,
			Frame: Frame | CanvasGroup,
			Click: () -> ()
		}
	}
}

return Types
