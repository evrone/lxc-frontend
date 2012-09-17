class LXCFrontend < Sinatra::Base
  MEGABYTE = 1024.0 * 1024.0 # to calculate available memory
  LXC_VM_PATH = "/var/lib/lxc" # default path to LXC data on Ubuntu
  LXC_IP_REGEXP = /lxc.network.ipv4 = ([\d.]+)\/([\d]+)/ # regexp to find server IP

  enable :sessions
  use Rack::Flash

  configure do
    set :public_folder, Proc.new { File.join(root, "static") }
  end

  helpers do
    def generate_confirm_code
      rand(1999..9999).to_s
    end

    def bytes_in_megabytes(bytes)
      (bytes / MEGABYTE).round
    end

    def lxc_ip_for(name)
      config = lxc_config_for(name)
      if config.match(LXC_IP_REGEXP)
        $1
      end
    end

    def lxc_config_for(name)
      config_path = lxc_config_path_for(name)
      File.open(config_path).read
    end

    def lxc_config_path_for(name)
      File.join(LXC_VM_PATH, name.to_s, "config")
    end

    def lxc_interfaces_path_for(name)
      File.join(LXC_VM_PATH, name.to_s, "rootfs", "etc", "network", "interfaces")
    end

    def lxc_interfaces_for(name)
      config_path = lxc_interfaces_path_for(name)
      File.open(config_path).read
    end

    def update_lxc_interfaces_for(name, content)
      config_path = lxc_interfaces_path_for(name)
      content.gsub!("\r\n", "\n") # otherwise it will be saved in DOS-format
      File.open(config_path, 'w') do |file|
        file.write(content)
      end
    end

    def update_lxc_config_for(name, content)
      config_path = lxc_config_path_for(name)
      content.gsub!("\r\n", "\n") # otherwise it will be saved in DOS-format
      File.open(config_path, 'w') do |file|
        file.write(content)
      end
    end
  end

  get "/" do
    LXC.use_sudo = true
    @containers = LXC.containers
    erb :index
  end

  get "/containers/:container/config" do
    @container = LXC.container(params[:container])
    if @container.exists?
      @config_data = lxc_config_for(@container.name)
      erb :config
    else
      halt 422
    end
  end

  get "/containers/:container/interfaces" do
    @container = LXC.container(params[:container])
    if @container.exists?
      @config_data = lxc_interfaces_for(@container.name)
      erb :interfaces
    else
      halt 422
    end
  end

  post "/containers/:container/update_config" do
    container = LXC.container(params[:container])
    if container.exists? && params[:config]
      update_lxc_config_for(container.name, params[:config])
      container.restart

      flash[:notice] = "You have successfully saved #{container.name} config. The container was restarted."
    end
    redirect "/"
  end

  post "/containers/:container/update_interfaces" do
    container = LXC.container(params[:container])
    if container.exists? && params[:interfaces]
      update_lxc_interfaces_for(container.name, params[:interfaces])
      container.restart

      flash[:notice] = "You have successfully saved #{container.name} interfaces. The container was restarted."
    end
    redirect "/"
  end

  get "/containers/:container/stop" do
   container = LXC.container(params[:container])
   if container.exists? && container.running?
     container.stop
     flash[:notice] = "You have successfully stopped #{container.name}."
     sleep 0.5 # waiting when it will be stopped
   end
   redirect "/"
  end

  get "/containers/:container/start" do
   container = LXC.container(params[:container])
   if container.exists?
     container.start
     flash[:notice] = "You have successfully started #{container.name}."
     sleep 0.5 # waiting when it will be started
   end
   redirect "/"
  end

  get "/containers/:container/secure_destroy" do
    @container = LXC.container(params[:container])
    if @container.exists?
      session[:secure_destroy_key] = generate_confirm_code
      erb :secure_destroy
    else
      halt 422
    end
  end

  post "/containers/:container/destroy" do
    container = LXC.container(params[:container])
    if container.exists? && session[:secure_destroy_key] == params[:secure_destroy_key]
     container.destroy
     flash[:notice] = "You have successfully destroyed #{container.name}."
     sleep 0.5 # waiting when it will be started
    end
    redirect "/"
  end

end
