class CignaforhcpSearchesController < ApplicationController

  def new
    @search = CignaforhcpSearch.new
  end

  def create
    @search = CignaforhcpSearch.new(search_params)
    @results_html = @search.execute
  end

  private

  def search_params
    params.require(:cignaforhcp_search).permit(:patient_id, :last_name, :first_name)
  end
end
