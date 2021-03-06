class MayorPdf < Pdf
	def initialize(tipo, balance, u, folio, periodo, orientation, mes)
		super(tipo, u, folio, periodo, orientation)
		@u = u
		@mes = mes

		@current_balance = balance
		grid([1, 0], [9,5]).bounding_box do
			debe
		end
		go_to_page(1)
		grid([1, 6], [9,11]).bounding_box do
			haber
		end
		@cuentas = Cuenta.all.group(:nombre_).count
		enumerar_paginas("landscape")

	end

	def debe
		tamanos = []
		partidas = [
			[{content:"Debe", align: :center, font_style: :bold, border_color: "757D75", colspan:5}],
			[
				{content:"Mes", align: :center, font_style: :bold, border_color: "757D75", size: 10},
				{content:"Dia", align: :center, font_style: :bold, border_color: "757D75", size: 10},
				{content:"Descripción", align: :center, font_style: :bold, border_color: "757D75"},
				{content:"", colspan:2, align: :center, font_style: :bold, border_color: "757D75"}
			]
		]
		@cuentas.each do |nombre|
			suma = Balance.find(@current_balance).cuentas.where("mes <= ? AND nombre_ = ?", @mes, nombre[0]).sum(:debe).to_f
			if suma != 0.0
				name = Cuenta.find_by(nombre_: nombre[0]).nombre
				partida = [[{content: name, colspan:5, align: :center, font_style: :bold, border_bottom_color: "AAAAAA"}]]
				cuentas = Balance.find(@current_balance).cuentas.where("mes <= ? AND nombre_ = ?", @mes, nombre[0])
				cuentas.each do |cuenta|
					if cuenta.debe != "" && cuenta.debe!= "0.0"
						partida.push [ {content: cuenta.libro_diario.mes.to_s, size: 8, borders:[:left]} , {content: cuenta.partida.dia.to_s, size: 8, align: :center, borders:[]}, {content: cuenta.partida.descripcion.to_s, size: 9, borders:[], width: 200}, {content: "Q" + '%.2f' % cuenta.debe.to_f, size: 8, align: :right, borders:[]} , {content: "----", borders:[:right], align: :center}]
					end
				end
				partida.push [{content: "", colspan: 4, border_top_color: "AAAAAA"}, {content: "Q" + '%.2f' % suma, size: 10, align: :right}]
				partidas += partida
				tamanos += [partida.length]
			end
		end
		if partidas.length <= 1
			partidas += [[ cuenta.libro_diario.mes, "", "", "", ""]]
		end
		total_celdas = partidas.length - 2


		table( partidas, header: 2, width: 384, cell_style:{ border_color: "333333", font_color: "333333"})
	end

	def haber
		partidas = [
			[{content:"Haber", align: :center, font_style: :bold, border_color: "757D75", colspan:5}],
			[
				{content:"Mes", align: :center, font_style: :bold, border_color: "757D75", size: 10},
				{content:"Dia", align: :center, font_style: :bold, border_color: "757D75", size: 10},
				{content:"Descripción", align: :center, font_style: :bold, border_color: "757D75"},
				{content:"", colspan:2, align: :center, font_style: :bold, border_color: "757D75"}
			]
		]
		@cuentas.each do |nombre|
			suma = Balance.find(@current_balance).cuentas.where("mes <= ? AND nombre_ = ?", @mes, nombre[0]).sum(:haber).to_f
			if suma != 0.0
				name = Cuenta.find_by(nombre_: nombre[0]).nombre
				partida = [[{content: name, colspan:5, align: :center, font_style: :bold, border_bottom_color: "FAFAFA"}]]
				cuentas = Balance.find(@current_balance).cuentas.where("mes <= ? AND nombre_ = ?", @mes, nombre[0])

				cuentas.each do |cuenta|
					if cuenta.haber != "" && cuenta.haber != "0" && cuenta.haber != "0.0" && cuenta.haber != "0.00"
						partida.push [ {content: cuenta.libro_diario.mes.to_s, size: 8, borders:[:left]} , {content: cuenta.partida.dia.to_s, size: 8, align: :center, borders:[]}, {content: cuenta.partida.descripcion.to_s, size: 9, borders:[], width: 200}, {content: "Q" + '%.2f' % cuenta.haber.to_f, size: 8, align: :right, borders:[]} , {content: "----", borders:[:right], align: :center}]
					end
				end
				partida.push [{content: "", colspan: 4, border_top_color: "AAAAAA"}, {content: "Q" + '%.2f' % suma, size: 10, align: :right}]
				partidas += partida
			end
		end
		if partidas.length <= 1
			partidas += [[ cuenta.libro_diario.mes, "", "", "", ""]]
		end
		table( partidas, header: 2, width: 384, cell_style:{ border_color: "333333", font_color: "333333"})
end

end
