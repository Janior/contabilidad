class LibroController < ApplicationController
  before_action :set_nombres_all_cuentas

  def mayor
  end

  def balance
  end

  private

  def set_nombres_all_cuentas
    @cuentas = Cuenta.all.group(:nombre_).count
  end
end
