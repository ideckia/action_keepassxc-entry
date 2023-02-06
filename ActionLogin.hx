import api.IdeckiaApi.ItemState;

@:jsRequire("../log-in", "IdeckiaAction")
extern class ActionLogin {
	function new();
	function setup(props:Any, server:Any):Any;
	function init(state:Any):js.lib.Promise<ItemState>;
	function execute(state:Any):js.lib.Promise<ItemState>;
}
