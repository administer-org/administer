local Types = {}

export type ButtonConfig = {
	Icon: string,
	AppName: string,
	Background: string,
	Description: string,

	MainButtonClick: () -> (),
	MainButtonFrame: Frame | CanvasGroup?,
	ButtonID: string,

	SubIcons: {
		{
			Icon: string,
			Name: string,
			Frame: Frame | CanvasGroup,
			Click: () -> (),

			ButtonID: string,
		}
	},
}

return Types
