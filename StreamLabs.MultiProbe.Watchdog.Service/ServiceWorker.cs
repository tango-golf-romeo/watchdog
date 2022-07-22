using System.Diagnostics;
using StreamLabs.MultiProbe.Watchdog.Core;

namespace StreamLabs.MultiProbe.Watchdog.Service;

public class ServiceWorker: BackgroundService
{
private const string Name = "Stream Labs Watchdog";

private readonly ILogger<ServiceWorker> _logger;

	public ServiceWorker (ILogger<ServiceWorker> logger)
	{
		_logger = logger;
	}

	public override Task StartAsync (CancellationToken ct)
	{
		this.log("Request to start the service received.");

		return base.StartAsync(ct);
	}

	protected override async Task ExecuteAsync (CancellationToken ct)
	{
		try
		{
			this.log("Ingressing background task.");

			await Watch.RunAsync(ct);

			this.log("Egressing background task.");
		}
		catch (Exception x)
		{
			if (x is OperationCanceledException)
				this.log("Cancel request received and aborted background task.");
			else
				this.log("Unhandled exception aborted background task.",x);
		}
	}

	public override Task StopAsync (CancellationToken ct)
	{
		this.log("Request to stop the service received.");

		return base.StopAsync(ct);
	}

#pragma warning disable CA1416
	private void log (string sMessage, Exception? x = null)
	{
	string sMsg = (sMessage ?? "").Trim();

		if (x != null)
		{
			_logger?.LogError(x,sMsg);
			EventLog.WriteEntry(ServiceWorker.Name,sMsg + "\r\nDetails:\r\n" +
				x.ToString(),EventLogEntryType.Error);
		}
		else
		{
			_logger?.LogInformation(sMsg);
			EventLog.WriteEntry(ServiceWorker.Name,sMsg,EventLogEntryType.Information);
		}
	}
#pragma warning restore CA1416
}
