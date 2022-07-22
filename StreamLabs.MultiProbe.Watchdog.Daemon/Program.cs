using StreamLabs.MultiProbe.Watchdog.Daemon;

IHost host = Host.CreateDefaultBuilder(args)
	.ConfigureServices(services =>
	{
		services.AddHostedService<DaemonWorker>();
	})
	.Build();

await host.RunAsync();
