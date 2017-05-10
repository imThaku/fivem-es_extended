(function(){

	let DefaultTpl = 
		'<div class="head">{{title}}</div>' +
			'<div class="menu-items">' + 
				'{{#items}}<div class="menu-item" data-remove-on-select="{{removeOnSelect}}" data-value="{{value}}">{{label}}</div>{{/items}}' +
			'</div>'+
		'</div>'
	;

	let DefaultWithTypeAndCountTpl = 
		'<div class="head">{{title}}</div>' +
			'<div class="menu-items">' + 
				'{{#items}}<div class="menu-item" data-value="{{value}}" data-remove-on-select="{{removeOnSelect}}" data-type="{{type}}" data-count="{{count}}">{{label}}</div>{{/items}}' +
			'</div>'+
		'</div>'
	;

	let DefaultWithTypeActionAndCountTpl = 
		'<div class="head">{{title}}</div>' +
			'<div class="menu-items">' + 
				'{{#items}}<div class="menu-item" data-value="{{value}}" data-remove-on-select="{{removeOnSelect}}" data-type="{{type}}" data-action="{{action}}" data-count="{{count}}">{{label}}</div>{{/items}}' +
			'</div>'+
		'</div>'
	;

	let menus = {

		inventory : {
		  title     : 'Inventaire',
		 	visible   : false,
		 	current   : -1,
		 	hasControl: false,
		 	template  : DefaultWithTypeAndCountTpl,

		  items: []
		},

		inventory_actions : {
		  title     : 'Inventaire - Actions',
		 	visible   : false,
		 	current   : -1,
		 	hasControl: false,
		 	template  : DefaultWithTypeActionAndCountTpl,

		  items: []
		}
	}

	let renderMenus = function(){
		for(let k in menus){

			let elem = $('#menu_' + k);

			elem.html(Mustache.render(menus[k].template, menus[k]));

			if(menus[k].visible)
				elem.show();
			else
				elem.hide();

		}
	}

	let showMenu = function(menu){

		currentMenu = menu;

		for(let k in menus)
			menus[k].visible = false;

		menus[menu].visible = true;

		renderMenus();

		if(menus[currentMenu].items.length > 0){

			$('#menu_' + currentMenu + ' .menu-item').removeClass('selected');
			$('#menu_' + currentMenu + ' .menu-item:eq(0)').addClass('selected');

			menus[currentMenu].current = 0;
			currentVal                 = menus[currentMenu].items[menus[currentMenu].current].value;
			currentType                = $('#menu_' + currentMenu + ' .menu-item:eq(0)').data('type');
			currentAction              = $('#menu_' + currentMenu + ' .menu-item:eq(0)').data('action');
			currentCount               = $('#menu_' + currentMenu + ' .menu-item:eq(0)').data('count');
		}

		$('#ctl_return').show();

		isMenuOpen        = true
		isShowingControls = false
	}

	let hideMenus = function(){
		
		for(let k in menus)
			menus[k].visible = false;

		renderMenus();
		isMenuOpen = false;
	}

	let showControl = function(control){

		hideControls();
		$('#ctl_' + control).show();
		isShowingControls = true;
		currentControl    = control;
	}

	let hideControls = function(){

		for(let k in menus)
			$('#ctl_' + k).hide();

		$('#ctl_return').hide();

		isShowingControls = false;
	}

	let addCommas = function(nStr) {
		nStr += '';
		var x = nStr.split('.');
		var x1 = x[0];
		var x2 = x.length > 1 ? '.' + x[1] : '';
		var rgx = /(\d+)(\d{3})/;
		while (rgx.test(x1)) {
			x1 = x1.replace(rgx, '$1' + '<span style="margin-left: 3px; margin-right: 3px;"/>' + '$2');
		}
		return x1 + x2;
	}

	let showRemoveInventoryItem = function(item){
		$('#remove_inventory_item').show();
		$('#remove_inventory_item_count').focus().click();
		$(cursor).show();
		currentInventoryItem      = item
		isRemoveInventoryItemOpen = true;
	}

	let hideRemoveInventoryItem = function(){
		$('#remove_inventory_item').hide();
		$(cursor).hide();
		isRemoveInventoryItemOpen = true;
	}

	$('#remove_inventory_item_send').click(function(){

		$.post('http://es_extended/remove_inventory_item', JSON.stringify({
			item : currentInventoryItem,
			count: parseInt($('#remove_inventory_item_count').val()),
		}))

	});

	let documentWidth  = document.documentElement.clientWidth;
	let documentHeight = document.documentElement.clientHeight;

	let cursor  = document.getElementById("cursor");
	let cursorX = documentWidth  / 2;
	let cursorY = documentHeight / 2;

	function UpdateCursorPos() {
    cursor.style.left = cursorX;
    cursor.style.top = cursorY;
	}

	function Click(x, y) {
    let element = $(document.elementFromPoint(x, y));
    element.focus().click();
	}

	function scrollMessages(direction){

		let element = $('#messages .container')[0];

		if(direction == 'UP')
			element.scrollTop -= 100;

		if(direction == 'DOWN')
			element.scrollTop += 100;

	}

  $(document).mousemove(function(event) {
    cursorX = event.pageX;
    cursorY = event.pageY;
    UpdateCursorPos();
  });

	let isMenuOpen           = false
	let isShowingControls    = false;
	let currentMenu          = null;
	let currentControl       = null;
	let currentVal           = null;
	let currentType          = null;
	let currentAction        = null;
	let currentCount         = null;
	let currentInventoryItem = null;
	let accountDivs          = {}
	
	renderMenus();

	window.onData = function(data){

		if(data.click === true){
			Click(cursorX - 1, cursorY - 1);
		}

		if(data.showControls === true){
			currentMenu = data.controls;
			showControl(data.controls);
		}

		if(data.showControls === false){
			hideControls();
		}

		if(data.showMenu === true){
			hideControls();

			if(data.items)
				menus[data.menu].items = data.items

			showMenu(data.menu);
		}

		if(data.showMenu === false){
			hideMenus();
		}

		if(data.showRemoveInventoryItem === true){
			showRemoveInventoryItem(data.item);
		}

		if(data.showRemoveInventoryItem === false){
			hideRemoveInventoryItem();
		}

		if(data.move && isMenuOpen){

			if(data.move == 'UP'){
				if(menus[currentMenu].current > 0)
					menus[currentMenu].current--;
			}

			if(data.move == 'DOWN'){
				
				let max = $('#menu_' + currentMenu + ' .menu-item').length;

				if(menus[currentMenu].current < max - 1)
					menus[currentMenu].current++;
			}

			$('#menu_' + currentMenu + ' .menu-item').removeClass('selected');
			$('#menu_' + currentMenu + ' .menu-item:eq(' + menus[currentMenu].current + ')').addClass('selected');

			currentVal    = menus[currentMenu].items[menus[currentMenu].current].value;
			currentType   = $('#menu_' + currentMenu + ' .menu-item:eq(' + menus[currentMenu].current + ')').data('type');
			currentAction = $('#menu_' + currentMenu + ' .menu-item:eq(' + menus[currentMenu].current + ')').data('action');
			currentCount  = $('#menu_' + currentMenu + ' .menu-item:eq(' + menus[currentMenu].current + ')').data('count');
		}

		if(data.enterPressed){

			if(isShowingControls){

				$.post('http://es_extended/select_control', JSON.stringify({
					control: currentControl,
				}))

				hideControls();
				showMenu(currentMenu);
			
			} else if(isMenuOpen) {		

				if(menus[currentMenu].current != -1){
					$.post('http://es_extended/select', JSON.stringify({
						menu  : currentMenu,
						val   : currentVal,
						type  : currentType,
						action: currentAction,
						count : currentCount
					}))
				}

				let elem = $('#menu_' + currentMenu + ' .menu-item.selected')

				if(elem.data('remove-on-select') == true){
					
					elem.remove();

					menus[currentMenu].items.splice(menus[currentMenu].current, 1)
					menus[currentMenu].current = 0;

					$('#menu_' + currentMenu + ' .menu-item').removeClass('selected');
					$('#menu_' + currentMenu + ' .menu-item:eq(0)').addClass('selected');
					
					currentVal    = menus[currentMenu].items[0].value;
					currentType   = $('#menu_' + currentMenu + ' .menu-item:eq(0)').data('type');
					currentAction = $('#menu_' + currentMenu + ' .menu-item:eq(0)').data('action');
					currentCount  = $('#menu_' + currentMenu + ' .menu-item:eq(0)').data('count');
				}

			} 

		}

		if(data.backspacePressed){

		}

		if(data.setmoney == true){

			for(let i=0; i<data.accounts.length; i++){
				
				let account = data.accounts[i];

				if(typeof accountDivs[account.name] == 'undefined'){
					let div = $('<div class="cash"/>');
					$('#money').append(div);
					accountDivs[account.name] = div;
				}

				accountDivs[account.name].html('<div><img src="img/accounts/' + account.name + '.png"/>&nbsp;' + addCommas(account.money) + '</div>');
			}
		}
/*				
		if(data.addcash == true){
			$(".tiny").remove();

			var element = $('<div class="tiny">+<font style="color: rgb(0, 125, 0); font-weight: 700; margin-right: 6px;""><img src="img/accounts/' + data.account.name + '.png"/></font>'+addCommas(data.money) + '</div>')
			$("#money").append(element)

			setTimeout(function(){
				$(element).fadeOut(600, function() { $(this).remove(); })
			}, 1000)
		}

		if(data.removecash == true){
			$(".tiny").remove();
			
			var element = $('<div class="tiny">-<font style="color: rgb(250, 0, 0); font-weight: 700; margin-right: 6px;""><img src="img/accounts/' + data.account.name + '.png"/></font>'+addCommas(data.money)+'</div>')
			$("#money").append(element)

			setTimeout(function(){
				$(element).fadeOut(600, function() { $(this).remove(); })
			}, 1000)
		}
*/
		if(data.setMoneyDisplay == true){
			$("#money").css('opacity', data.display)
		}

		if(data.setJobDisplay == true){
			$("#job").css('opacity', data.display)
		}

		if(data.removeInventoryItem){

			$('#inventory_notif').text('- ' + data.count + 'x ' + data.item.label)

			setTimeout(function(){
				$('#inventory_notif').fadeOut(600, function() { $(this).text('').show(); })
			}, 1000)

		}

		if(data.addInventoryItem){

			$('#inventory_notif').text('+ ' + data.count + 'x ' + data.item.label)

			setTimeout(function(){
				$('#inventory_notif').fadeOut(600, function() { $(this).text('').show(); })
			}, 1000)

		}

		if(data.setJob === true){

			if(data.job.grade_label && data.job.grade_label != '')
				$('#job').html(data.job.label + ' - ' + data.job.grade_label);
			else
				$('#job').html(data.job.label);
		}

		if(data.setJob === false){
			$('#job').html('')
		}

	}

	window.onload = function(e){ window.addEventListener('message', function(event){ onData(event.data) }); }

})()