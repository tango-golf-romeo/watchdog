using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace StreamLabs.MultiProbe.Watchdog.Core;

public static class Watch
{
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
			string sErr = x.Message;

				if (x is OperationCanceledException) throw;
			}

		bool bSignal = ct.WaitHandle.WaitOne(60 * 1000);
			if (bSignal) return;
		}
	}
}
