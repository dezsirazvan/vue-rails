# frozen_string_literal: true

class Api::V1::MetricsController < ApplicationController
  include Api::V1::MetricsControllerDoc

  before_action :find_metric, except: [:index, :create, :timeline]

  def index
    @metrics = Metric.all

    @metrics = metrics_in_interval if params[:from_date] && params[:to_date]

    render json: @metrics, each_serializer: Metric::ListSerializer
  end

  def create
    @metric = Metric.new(metric_params)
    if @metric.save
      render json: @metric, serializer: Metric::ObjectSerializer
    else
      render json: { errors: @metric.errors }, status: :unprocessable_entity
    end
  end

  def show
    render json: @metric, serializer: Metric::ObjectSerializer
  end

  def update
    if @metric.update(metric_params)
      render json: @metric, serializer: Metric::ObjectSerializer
    else
      render json: { errors: @metric.errors }, status: :unprocessable_entity
    end
  end

  def destroy
    if @metric.destroy
      render json: { message: 'Metric was successfully deleted.' }
    else
      render json: { errors: @metric.errors, status: :unprocessable_entity }
    end
  end

  def timeline
    @metrics = Metric.all

    @metrics = metrics_in_interval if params[:from_date] && params[:to_date]

    @metrics = GroupMetricsService.new(@metrics, params[:average_type]).group

    result = TimelineCalculatorService.new(@metrics).calculate

    render json: result
  end

  private

    def metric_params
      params.require(:metric).permit(:id, :name, :value)
    end

    def find_metric
      @metric = Metric.find(params[:id])
    rescue StandardError
      render json: { error: 'Metric not found' }, status: :not_found
      nil
    end

    def metrics_in_interval
      @metrics.in_interval(params[:from_date], params[:to_date])
    rescue ArgumentError => error
      Rails.logger(error)
      []
    end
end