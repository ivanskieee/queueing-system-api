class JobProcessorWorker
  include Sidekiq::Worker
  
  sidekiq_options queue: 'default', retry: 3
  
  def perform(job_id)
    job = Job.find(job_id)
    job.processing!
    
    # Broadcast status update
    ActionCable.server.broadcast('jobs_channel', {
      type: 'job_updated',
      job: job_data(job)
    })
    
    begin
      # Simulate work based on job data
      process_job(job)
      
      job.complete!
      
      # Broadcast completion
      ActionCable.server.broadcast('jobs_channel', {
        type: 'job_completed',
        job: job_data(job)
      })
      
    rescue StandardError => e
      job.fail!(e.message)
      
      # Broadcast failure
      ActionCable.server.broadcast('jobs_channel', {
        type: 'job_failed',
        job: job_data(job)
      })
      
      raise e
    end
  end
  
  private
  
  def process_job(job)
    # Parse job data and perform actual work
    data = JSON.parse(job.data) rescue {}
    duration = data['duration'] || 5
    
    # Simulate processing time
    sleep(duration)
    
    # Add your actual job processing logic here
    case data['type']
    when 'email'
      send_email(data)
    when 'report'
      generate_report(data)
    when 'import'
      import_data(data)
    else
      # Default processing
      Rails.logger.info "Processing job: #{job.title}"
    end
  end
  
  def send_email(data)
    # Email sending logic
    Rails.logger.info "Sending email to: #{data['recipient']}"
  end
  
  def generate_report(data)
    # Report generation logic
    Rails.logger.info "Generating report: #{data['report_type']}"
  end
  
  def import_data(data)
    # Data import logic
    Rails.logger.info "Importing data from: #{data['source']}"
  end
  
  def job_data(job)
    {
      id: job.id,
      title: job.title,
      status: job.status,
      priority: job.priority,
      created_at: job.created_at,
      started_at: job.started_at,
      completed_at: job.completed_at,
      error_message: job.error_message
    }
  end
end