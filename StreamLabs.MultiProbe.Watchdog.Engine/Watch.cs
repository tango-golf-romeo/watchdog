using StreamLabs.MultiProbe.Watchdog.Core;

namespace StreamLabs.MultiProbe.Watchdog.Engine;
public class Watch
{
private const string DefaultHost = "locahost";

private const int PeriodStandBySec = 60; //period to stand by in sec
private const int PeriodStandByMsec = Watch.PeriodStandBySec * 1000; //period to stand by in msec

private string m_sHost = Watch.DefaultHost;

	public Watch ()
	{
	}

	public Watch (string sHost)
	{
		this.host = sHost;
	}

	public string host
	{
		get => m_sHost;
		private set
		{
		string s = (value ?? "").Trim();
			m_sHost = (s.Length > 0)?s:Watch.DefaultHost;
		}
	}

	/// <summary>
	/// Root entry for the watchdog service.
	/// </summary>
	/// <param name="ct"></param>
	/// <returns></returns>
	public async Task runAsync (CancellationToken ct)
	{
	CmsEventLog log = new CmsEventLog(this.host);
	int iFuseCounter = 0;

		while (true)
		{
			//no longer required as we wait
			//ct.ThrowIfCancellationRequested();

			if (++iFuseCounter > 5) return;

			try
			{
				await log.reportAsync(ct).ConfigureAwait(false);
			}
			catch (Exception x)
			{
				//if request to abort then quit immediately
				if (x is OperationCanceledException) return;

				//otherwise report and go on.
				//this is the top of exception handling stack, if any unhandled exception is captured
				//here then it means that the backgound loop didn't pass its full cycle (one pass/run)
			}

		bool bSignal = ct.WaitHandle.WaitOne(Watch.PeriodStandByMsec);
			if (bSignal) return;
		}
	}
}
