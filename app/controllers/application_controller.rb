class ApplicationController < ActionController::Base
# Prevent CSRF attacks by raising an exception.
# For APIs, you may want to use :null_session instead.
protect_from_forgery with: :exception

before_action :authenticate_usuario!
before_action :set_user_as_u
before_action :current_period
before_action :set_balance
before_action :configure_permitted_parameters, if: :devise_controller?
before_action :set_libro_diario
before_action :partidas_primarias
before_action :crear_folios


protected

def set_user_as_u
  @u = current_usuario
end


#Setear Libro Diario
def set_libro_diario
  if usuario_signed_in? && current_usuario.establecimiento_id && current_usuario.mes != "Selecciona un Mes" && current_usuario.year != "Selecciona un Año"
    establecimiento = @u.establecimiento_id
    mes = @u.mes
    year = @u.year
    libro = LibroDiario.find_by(mes: mes, year: year, balance_id: @balance.id)
    if libro != nil
      @libro_diario = libro
    else
      @libro_diario = LibroDiario.create!(balance_id: @balance.id, establecimiento_id: establecimiento, mes: mes, year: year, periodo: @periodo )
    end
  end
end

#Login con username
def configure_permitted_parameters
  devise_parameter_sanitizer.for(:sign_up) { |u| u.permit(:username, :email, :password, :password_confirmation, :remember_me) }
  devise_parameter_sanitizer.for(:sign_in) { |u| u.permit(:login, :username, :email, :password, :remember_me) }
  devise_parameter_sanitizer.for(:account_update) { |u| u.permit(:username,:nombre, :apellido,:contribuyente_id, :establecimiento_id, :email, :mes, :year, :password, :password_confirmation, :current_password) }
end

def validar_datos_para_trabajar
  u = @u

  if u.contribuyente_id == nil
    flash.now[:alert] = 'No has Seleccionado ningun Contribuyente para trabajar!'
  elsif u.establecimiento_id == nil
    flash.now[:alert] = 'No has Seleccionado ningun Establecimiento para trabajar!'
  elsif u.mes == "Selecciona un Mes"
    flash.now[:alert] = 'No has Seleccionado ningun Mes para trabajar!'
  elsif u.year == "Selecciona un Año"
    flash.now[:alert] = 'No has Seleccionado ningun Año para trabajar!'
  end
end

def partidas_primarias
  if usuario_signed_in? && current_usuario.establecimiento_id && current_usuario.mes != "Selecciona un Mes" && current_usuario.year != "Selecciona un Año"
    ventas_base = VentaLibro.where(establecimiento_id: current_usuario.establecimiento_id, mes: current_usuario.mes).sum(:base)
    ventas_iva = VentaLibro.where(establecimiento_id: current_usuario.establecimiento_id, mes: current_usuario.mes).sum(:iva)
    ventas_caja = ventas_base + ventas_iva
    compras_base = CompraLibro.where(establecimiento_id: current_usuario.establecimiento_id, mes: current_usuario.mes).sum(:base)
    compras_iva = CompraLibro.where(establecimiento_id: current_usuario.establecimiento_id, mes: current_usuario.mes).sum(:iva)
    compras_caja = compras_base + compras_iva


    partida1 = @libro_diario.partidas.find_by(numero_partida: 1)
    if partida1 == nil
      params = {
       partida:  {
        numero_partida: 1, dia: 1, establecimiento_id: @libro_diario.establecimiento_id, 
        cuentas_attributes: [
          { nombre: "Caja", debe: ventas_caja, haber: 0.00, posicion: 1 , balance_id: @balance.id},
          { nombre: "Ventas", debe: 0.00, haber: ventas_base, posicion: 2, balance_id: @balance.id},
          { nombre: "Iva por Pagar", debe: 0.00, haber: ventas_iva, posicion: 3, balance_id: @balance.id}
          ],
          descripcion: "Por favor añade una descripción"}
        }
        partida1 = @libro_diario.partidas.new(params[:partida])
        partida1.save
      else
        caja = partida1.cuentas.find_by(posicion: 1)
        ventas = partida1.cuentas.find_by(posicion: 2)
        iva = partida1.cuentas.find_by(posicion: 3)
        caja.debe = ventas_caja
        ventas.haber = ventas_base
        iva.haber = ventas_iva
        caja.save
        ventas.save
        iva.save
      end

      partida2 = @libro_diario.partidas.find_by(numero_partida: 2)
      if partida2 == nil
        params = { 
          partida:{
            numero_partida: 2, dia:1, establecimiento_id: @libro_diario.establecimiento_id, 
            cuentas_attributes: [
              { nombre: "Caja", debe: 0.00, haber: compras_caja, posicion: 900, balance_id: @balance.id},
              { nombre: "Iva por cobrar", debe: compras_iva, haber: 0.00, posicion: 899, balance_id: @balance.id}
              ],
              descripcion: "Por favor añade una descripción"}
            }
            partida2 = @libro_diario.partidas.new(params[:partida])
            partida2.save
          else
            caja2 = partida2.cuentas.find_by(posicion: 900)
            iva2 = partida2.cuentas.find_by(posicion: 899)
            caja2.haber = compras_caja
            iva2.debe = compras_iva
            caja2.save
            iva2.save
          end
        end
      end

      def current_period
        if usuario_signed_in?
          mes = @u.mes
          if mes == "Selecciona un Mes"
            @periodo = 0
          elsif mes == "Enero" || mes == "Febrero" || mes == "Marzo"
            @periodo = 1
          elsif mes == "Abril" || mes == "Mayo" || mes == "Junio"
            @periodo = 2 
          elsif mes == "Julio" || mes == "Agosto" || mes == "Septiembre"
            @periodo = 3
          elsif mes == "Octubre" || mes == "Noviembre" || mes == "Diciembre"
            @periodo = 4 
          else
            @periodo = nil
          end
        end
      end


      def set_balance
        if usuario_signed_in? && current_usuario.establecimiento_id != nil && current_usuario.mes != "Selecciona un Mes" && current_usuario.year != "Selecciona un Año"
          @balance = Balance.find_or_create_by(establecimiento_id: current_usuario.establecimiento_id, year: current_usuario.year, periodo: @periodo )
        end
      end

      def crear_folios
        @folios_compras = {max:50, used:10}
        @folios_ventas = {max:50, used:0}
        @folios_mayor = {max:50, used:0}
        @folios_balance = {max:50, used:0}
      end
    end

