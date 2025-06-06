class Api::V1::QueueController < ApplicationController
  def stats
    stats = {
      total_jobs: Job.count,
      pending_jobs: Job.where(status: 'pending').count,
      processing_jobs: Job.where(status: 'processing').count,
      completed_jobs: Job.where(status: 'completed').count,
      failed_jobs: Job.where(status: 'failed').count,
      queue_size: Sidekiq::Queue.new.size,
      workers_busy: Sidekiq::Workers.new.size
    }
    
    render json: { stats: stats }
  end
end