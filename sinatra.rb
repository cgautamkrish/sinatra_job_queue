require 'sinatra'
require 'yaml/store'
require 'securerandom'
require 'json'
require 'thread'

# intialize job queues
job_queue = Queue.new
priority_job_queue = Queue.new

def authenticate(hashvalue)
  @store = YAML::Store.new 'resources/grants.yml'
  @grants = @store.transaction { @store['grants'] }
  @grant = @grants['consumer_agent']
  if hashvalue != @grant
    return false
  else
    return true
  end
end

post '/add' do
  params = JSON.parse(request.env["rack.input"].read)
  puts params
  @type = params['type']
  @priority = params['priority']
  @status = params['status']
  @job = params['job']
  @hashValue = params['hashValue']

  if params['type'].nil? == true || params['priority'].nil? == true || params['status'].nil? == true || params['job'].nil? == true || params['hashValue'].nil? == true
    # return 500
    error 500, {error: "Missing fields"}.to_json
  end

  # check if job has correct credentials
  @check = authenticate(@hashValue)

  if @check == false
    # return 500 
    error 500, {error: "Incorrect credentials"}.to_json 
  end

  @new_job = Hash.new
  @new_job = {"type" => @type, "priority" => @priority, "status" => @status, "job" => @job}
  @jobs = YAML::Store.new 'resources/jobs.yml'
  @jobs_data = @jobs.transaction { @jobs['jobs'] }
  
  @id = 0
  @jobs_data.each do |key, array|
    @id += 1
  end
  @id = @id + 1

  @jobs.transaction do
    @jobs['jobs'][@id] = @new_job
  end

  if @priority == 1
    priority_job_queue.push @id
  else
    job_queue.push @id
  end

  content_type :json
  { :status => 'Job added to queue', :job_id => @id, :job => @new_job }.to_json
end

get '/job' do
  if request.env['HTTP_HASHVALUE'].nil? == true || request.env['HTTP_AGENT'].nil? == true
    error 500, {error: "Missing credentials"}.to_json
  end
  
  @hashValue = request.env['HTTP_HASHVALUE']
  @agentID = request.env['HTTP_AGENT']

  # check if job has correct credentials
  @check = authenticate(@hashValue)
  if @check == false
    # return 500 
    error 500, {error: "Incorrect credentials"}.to_json 
  end

  if priority_job_queue.length > 0
    @x = priority_job_queue.pop(true)

    @jobs_allocation = YAML::Store.new 'resources/jobs_allocation.yml'
    @jobs_allocation.transaction do
      @jobs_allocation['jobs_allocation'] ||= {}
      @jobs_allocation['jobs_allocation'][@x] = @agentID
    end

    @jobs = YAML::Store.new 'resources/jobs.yml'
    @jobs_data = @jobs.transaction { @jobs['jobs'] }
    @current_job = @jobs_data[@x]
    @current_job['status'] = 'IN_PROGRESS'
    puts @current_job
    
    @jobs.transaction do
      @jobs['jobs'] ||= {}
      @jobs['jobs'][@x] = @current_job
    end

    puts @current_job.to_json
    content_type :json
    { :job_id => @x, :job => @current_job }.to_json
  end
end

get '/check' do
  if params['job'].nil? == true
    # return 500 
    error 500, {error: "Missing parameter"}.to_json   
  end

  @job_id = params['job']
  puts @job_id
  @jobs = YAML::Store.new 'resources/jobs.yml'
  @jobs_data = @jobs.transaction { @jobs['jobs'] }
  @current_job = @jobs_data[Integer(@job_id)]
  @status = @current_job['status']

  @jobs_allocation = YAML::Store.new 'resources/jobs_allocation.yml'
  @jobs_allocation = @jobs_allocation.transaction { @jobs_allocation['jobs_allocation'] }
  @current_agent = @jobs_allocation[Integer(@job_id)]

  content_type :json
  { :status => @status, :assigned_agent => @current_agent}.to_json
end