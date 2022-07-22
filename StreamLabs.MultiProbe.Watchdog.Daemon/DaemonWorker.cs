using StreamLabs.MultiProbe.Watchdog.Core;

namespace StreamLabs.MultiProbe.Watchdog.Daemon;

public class DaemonWorker: BackgroundService
{
private readonly ILogger<DaemonWorker> _logger;

	public DaemonWorker (ILogger<DaemonWorker> logger)
	{
		_logger = logger;
	}

	public override Task StartAsync (CancellationToken ct)
	{
		_logger?.LogInformation("Request to start the daemon received.");

		return base.StartAsync(ct);
	}

	protected override async Task ExecuteAsync (CancellationToken ct)
	{
		try
		{
			_logger?.LogInformation("Ingressing background task.");

			await Watch.RunAsync(ct);

			_logger?.LogInformation("Egressing background task.");
		}
		catch (Exception x)
		{
			if (x is OperationCanceledException)
				_logger?.LogInformation("Cancel request received and aborted background task.");
			else
				_logger?.LogError(x,"Unhandled exception aborted background task.");
		}
	}

	public override Task StopAsync (CancellationToken ct)
	{
		_logger?.LogInformation("Request to stop the daemon received.");

		return base.StopAsync(ct);
	}
}
