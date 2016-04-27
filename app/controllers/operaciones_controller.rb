class OperacionesController < ApplicationController
	before_action :set_compras
	before_action :set_ventas
	before_action :set_por_cuentas

	def libro_venta
		if @folios_ventas == nil
			pdf = ErrorPdf.new
			send_data pdf.render, filename: "ventas.pdf",
			type: "application/pdf",
			disposition: "inline"
		else
			@iva = VentaLibro.where(establecimiento_id: current_usuario.establecimiento_id, mes: current_usuario.mes).sum(:iva)
			@base = VentaLibro.where(establecimiento_id: current_usuario.establecimiento_id, mes: current_usuario.mes).sum(:base)
			@bienes = (VentaLibro.where(establecimiento_id: current_usuario.establecimiento_id, mes: current_usuario.mes).sum(:gravado_bienes).to_f / 1.12).round(2)
			@servicios = (VentaLibro.where(establecimiento_id: current_usuario.establecimiento_id, mes: current_usuario.mes).sum(:gravado_servicios).to_f / 1.12).round(2)
			@total = @base + @iva
			respond_to do |format|
				format.html
				format.pdf do 
					pdf = VentasPdf.new(@iva, @base, @bienes, @servicios, @total, @ventas, @u)
					send_data pdf.render, filename: "libro_ventas_" + current_usuario.establecimiento.nombre.split(" ").join("_") + "_" + current_usuario.year + ".pdf",
					type: "application/pdf",
					disposition: "inline"
				end
			end
		end
	end
	def libro_compra
		if @folios_compras == nil
			flash.now[:alert] = "Debes Registrar los Folios de este Libro"
			pdf = ErrorPdf.new
			send_data pdf.render, filename: "compras.pdf",
			type: "application/pdf",
			disposition: "inline"
		else
			@iva = CompraLibro.where(establecimiento_id: current_usuario.establecimiento_id, mes: current_usuario.mes).sum(:iva)
			@base = CompraLibro.where(establecimiento_id: current_usuario.establecimiento_id, mes: current_usuario.mes).sum(:base)
			@compras_por_dia = @compras.order(:dia)
			@total = @base + @iva
			@total_cuentas = CompraLibro.where(establecimiento_id: current_usuario.establecimiento_id, mes: current_usuario.mes).count

			respond_to do |format|
				format.html
				format.pdf do
					pdf = ComprasPdf.new(@iva, @base, @compras_por_dia, @total, @total_cuentas, @u, @compras_por_cuenta, @folios_compras)
					send_data pdf.render, filename: "libro_compras_" + current_usuario.establecimiento.nombre.split(" ").join("_") + "_" + current_usuario.year + ".pdf",
					type: "application/pdf",
					disposition: "inline"
				end
			end
		end
	end

	private


	def set_ventas
		@ventas_por_dia = VentaLibro.order(:dia).where(establecimiento_id: current_usuario.establecimiento_id, mes: current_usuario.mes).group(:dia).sum(:base)
		dias = VentaLibro.order(:serie).where(establecimiento_id: current_usuario.establecimiento_id, mes: current_usuario.mes).group(:dia).count()
		@ventas = []

		dias.each do |dia|
			numero_dia = dia[0]
			cantidad_ventas = dia[1]
			if cantidad_ventas == 1
				venta_unica = VentaLibro.find_by(establecimiento_id: current_usuario.establecimiento_id, mes: current_usuario.mes, dia: numero_dia).as_json
				venta_unica["min"] = venta_unica["numero"]
				venta_unica["max"] = venta_unica["numero"]
				@ventas.push venta_unica
			else
				resumen_dia_ventas = {}
				resumen_dia_ventas['base']  = VentaLibro.where(establecimiento_id: current_usuario.establecimiento_id, mes: current_usuario.mes, dia: numero_dia).sum(:base)
				resumen_dia_ventas['gravado_bienes'] = VentaLibro.where(establecimiento_id: current_usuario.establecimiento_id, mes: current_usuario.mes, dia: numero_dia).sum(:gravado_bienes)
				resumen_dia_ventas['gravado_servicios'] = VentaLibro.where(establecimiento_id: current_usuario.establecimiento_id, mes: current_usuario.mes, dia: numero_dia).sum(:gravado_servicios)
				resumen_dia_ventas['exento_bienes'] = VentaLibro.where(establecimiento_id: current_usuario.establecimiento_id, mes: current_usuario.mes, dia: numero_dia).sum(:exento_bienes)
				resumen_dia_ventas['exento_servicios'] = VentaLibro.where(establecimiento_id: current_usuario.establecimiento_id, mes: current_usuario.mes, dia: numero_dia).sum(:exento_servicios)
				resumen_dia_ventas['documento'] = 'FC'
				resumen_dia_ventas['numero']  = 'Pendiente'
				resumen_dia_ventas['dia'] = numero_dia
				resumen_dia_ventas['mes'] = current_usuario.mes
				resumen_dia_ventas['year'] = current_usuario.year
				resumen_dia_ventas['nit'] = 'C/F'
				resumen_dia_ventas['nombre'] = "Clientes Varios"
				resumen_dia_ventas['min'] = VentaLibro.where(establecimiento_id: current_usuario.establecimiento_id, mes: current_usuario.mes, dia: numero_dia).minimum(:numero)
				resumen_dia_ventas['max'] = VentaLibro.where(establecimiento_id: current_usuario.establecimiento_id, mes: current_usuario.mes, dia: numero_dia).maximum(:numero)
				series = []
				VentaLibro.where(establecimiento_id: current_usuario.establecimiento_id, mes: current_usuario.mes, dia: numero_dia).group(:serie).count.each do |serie| 
					series.push serie.to_a[0]
				end
				resumen_dia_ventas['serie'] = series.join(", ")

				@ventas.push resumen_dia_ventas.as_json
			end
		end
	end

	def set_por_cuentas
		cuentas = CompraLibro.where(establecimiento_id: current_usuario.establecimiento_id, mes: current_usuario.mes).group(:tipo_de_gasto_id).count()
		@compras_por_cuenta = []

		cuentas.each do |cuenta|
			nombre_cuenta = TipoDeGasto.find_by_id(cuenta[0]).nombre
			suma_base = CompraLibro.where(establecimiento_id: current_usuario.establecimiento_id, mes: current_usuario.mes, tipo_de_gasto_id: cuenta[0]).sum(:base)
			@compras_por_cuenta.push [nombre_cuenta , suma_base]
		end
	end

	def set_compras
		@compras = CompraLibro.where(establecimiento_id: current_usuario.establecimiento_id, mes: current_usuario.mes)
	end
end

