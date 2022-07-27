using StreamLabs.MultiProbe.Watchdog.Engine;
using StreamLabs.MultiProbe.Watchdog.Daemon;

IHost host = Host.CreateDefaultBuilder(args)
	.ConfigureServices(services =>
	{
		services.AddHostedService<DaemonWorker>()
			.AddTransient<WatchSpec>(spec => new WatchSpec(args));
	})
	.Build();

await host.RunAsync();
