$(document).ready(function(){

	var noticia = $('#notice');
	var alerta = $('#alert');

	if (!$(notice).text()  == "") {
		$("#notice").animate({
			top: "10%"});
		$('#notice').delay(4000).fadeOut(2000);
	};

	var objeto = $('.jumbotron .objeto');

	$(objeto).click(function() {
		var popover = $(this).children("div");
		$(popover).slideToggle(400);
	});

	var popover = $(objeto).children("div");
	
  $(popover).mouseleave(function() {
   $(this).slideUp(400);
});

  $('a').click(function  () {
    if ($(this).attr("href") !== "#") 
    {
        if ($(this).attr("href") !== "/") 
        {
            window.open(this.href,'ventana','width=800,height=500'); return false;        
        };
        
    }
    

})

})