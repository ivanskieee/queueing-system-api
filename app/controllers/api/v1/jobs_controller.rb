class Api::V1::JobsController < ApplicationController
  before_action :set_job, only: [:show, :destroy, :retry]
  
  def index
    @jobs = Job.includes(:class)
                .by_status(params[:status])
                .by_priority
                .page(params[:page])
                .per(params[:per_page] || 20)
    
    render json: {
      jobs: @jobs.map { |job| job_data(job) },
      pagination: {
        current_page: @jobs.current_page,
        total_pages: @jobs.total_pages,
        total_count: @jobs.total_count
      }
    }
  end
  
  def show
    render json: { job: job_data(@job) }
  end
  
  def create
    @job = Job.new(job_params)
    
    if @job.save
      # Queue the job for processing
      JobProcessorWorker.perform_async(@job.id)
      
      # Broadcast new job
      ActionCable.server.broadcast('jobs_channel', {
        type: 'job_created',
        job: job_data(@job)
      })
      
      render json: { job: job_data(@job) }, status: :created
    else
      render json: { errors: @job.errors }, status: :unprocessable_entity
    end
  end
  
  def destroy
    @job.destroy
    
    # Broadcast job deletion
    ActionCable.server.broadcast('jobs_channel', {
      type: 'job_deleted',
      job_id: @job.id
    })
    
    head :no_content
  end
  
  def retry
    if @job.status == 'failed'
      @job.update!(status: 'pending', error_message: nil)
      JobProcessorWorker.perform_async(@job.id)
      
      render json: { job: job_data(@job) }
    else
      render json: { error: 'Job cannot be retried' }, status: :unprocessable_entity
    end
  end
  
  private
  
  def set_job
    @job = Job.find(params[:id])
  end
  
  def job_params
    params.require(:job).permit(:title, :priority, :data)
  end
  
  def job_data(job)
    {
      id: job.id,
      title: job.title,
      status: job.status,
      priority: job.priority,
      data: job.data,
      error_message: job.error_message,
      created_at: job.created_at,
      started_at: job.started_at,
      completed_at: job.completed_at
    }
  end
end