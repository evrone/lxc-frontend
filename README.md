![](http://f.cl.ly/items/2V1L3Y0y1S1K2z392x3n/Screen%20Shot%202012-09-17%20at%2012.09.56%20PM.png)

The `lxc-frontend` is a small Sinatra app which was created to speed-up the monitoring and management of LXC containers. You can start/stop/restart any container, change the container config and network interfaces. NB: it's an interface to [lxc-ruby](https://github.com/sosedoff/lxc-ruby) gem.

In Evrone we're using it with Ubuntu 12.04 and the default path to containers is defined in [frontend.rb](https://github.com/evrone/lxc-frontend/blob/master/frontend.rb#L3).

#Requirements:
* the user which runs the Sinatra app should have sudo permissions without a password prompt
* LXC containers configs should have a write permission under the app. It can be fixed by assigning the `a+w` rule to container config and rootfs/network/interfaces files

#How to use

1. Download the app: `git clone ...`
2. Add a capistrano receipe. You can use Evrone's template as an example: [deploy.rb](https://gist.github.com/3743779)
3. You may add the project with capistrano files into the private git repo to share it inside your company.
4. `cap deploy:cold`
5. ???
6. PROFIT!