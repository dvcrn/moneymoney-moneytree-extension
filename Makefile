dist/out.lua: src/Main.hx src/JsonHelper.hx src/RequestHelper.hx src/Storage.hx src/Moneytree.hx
	mkdir -p dist
	cd src/ && haxe --lua ../dist/out.lua --main Main -D lua-vanilla -D lua-return
	sed -i '' 's/    error(\"Failed to load bit or bit32\")/-- &/' dist/out.lua
	cp dist/out.lua /Users/david/Library/Containers/com.moneymoney-app.retail/Data/Library/Application\ Support/MoneyMoney/Extensions/moneytree.lua

