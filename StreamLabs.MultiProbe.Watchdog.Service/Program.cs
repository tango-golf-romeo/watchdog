using StreamLabs.MultiProbe.Watchdog.Service;

IHost host = Host.CreateDefaultBuilder(args)
	.UseWindowsService(opts =>
	{
		opts.ServiceName = "StreamLabsWatchdog";
	})
	.ConfigureServices(services =>
	{
		//log provider will be added later

		//root watchdog class not injected so far
		services.AddHostedService<ServiceWorker>();
	})
	.Build();

await host.RunAsync();
