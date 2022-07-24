using StreamLabs.MultiProbe.Watchdog.Core;

namespace StreamLabs.MultiProbe.Watchdog.Engine;
public static class Watch
{
private const int PeriodStandBySec = 60; //period to stand by in sec
private const int PeriodStandByMsec = Watch.PeriodStandBySec * 1000; //period to stand by in msec

	public static async Task RunAsync (CancellationToken ct)
	{
	CmsEventLog log = new CmsEventLog();
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
