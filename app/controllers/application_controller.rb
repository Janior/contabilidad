class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
#  before_action :operacion_cambio

before_action :authenticate_usuario!  
before_action :configure_permitted_parameters, if: :devise_controller?
before_action :set_user_as_u
before_action :datos_para_operacion




protected
def set_user_as_u
  @u = current_usuario
end

#Setear Datos para uso en vistas
def datos_para_operacion
  if usuario_signed_in?
    @dato = []
    @dato[0] = @u.establecimiento_id
    @dato[1]= @u.contribuyente_id

    if @dato[0] == nil
      @establecimiento_nombre = "Selecciona establecimiento"
    else
      establecimiento = Establecimiento.find_by(id: @dato[0])
      @establecimiento_nombre = establecimiento.nombre
    end

    if @dato[1] == nil
      @contribuyente_nombre = "Selecciona contribuyente"  
      @contribuyente_nit = "Selecciona contribuyente"
    else
      contribuyente = Contribuyente.find_by(id: @dato[1])
      @contribuyente_nombre = contribuyente.nombre
      @contribuyente_nit = contribuyente.nit
    end
  else
  end
end
#Setear Libro Diario
def set_libro_diario
  if usuario_signed_in?
    establecimiento = @u.establecimiento_id
    mes = @u.mes
    year = @u.year
    buscar_libro = LibroDiario.find_by(establecimiento_id: establecimiento, mes: mes, year: year)
    if buscar_libro == nil
      nuevo_diario = LibroDiario.new(establecimiento_id: establecimiento, mes: mes, year: year)  
      nuevo_diario.save
      @libro_diario = nuevo_diario
    else
      @libro_diario = buscar_libro
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
end
