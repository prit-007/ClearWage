package constants

const (
	ParamUid = "uid"

	Unauthenticated     = "unauthenticated"
	ErrUnauthenticated  = "error while checking user identity"
	InvalidCredentials  = "invalid email or password"
	ErrLoginUser        = "error while login user"
	ErrKratosIDEmpty    = "kratos id is empty"
	ErrKratosAuth       = "error while kratos authentication"
	ErrKratosDataInsertion = "error while inserting kratos user"
	ErrKratosCookieTime = "error while parsing kratos cookie expiration time"

	CookieUser   = "user"
	KratosID     = "kratos_id"
	KratosCookie = "ory_kratos_session"
	ContextUid   = "uid"

	EventUserRegistered = "user:registered"
)
