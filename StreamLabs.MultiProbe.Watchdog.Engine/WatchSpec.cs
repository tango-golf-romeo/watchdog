using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace StreamLabs.MultiProbe.Watchdog.Engine;

public class WatchSpec
{
private List<string> mHosts = null!;

	public WatchSpec ()
	{
		mHosts = new List<string>();
	}

	public WatchSpec (string[] args)
	{
		mHosts = this.parseHosts(args);
	}

	private List<string> parseHosts (string[] args)
	{
		if (args == null) return new List<string>();

	string sTargetSql = args.First(e => e.StartsWith("/sql:",StringComparison.InvariantCultureIgnoreCase) ||
			e.StartsWith("-sql:",StringComparison.InvariantCultureIgnoreCase) ||
			e.StartsWith("--sql:",StringComparison.InvariantCultureIgnoreCase));

		sTargetSql = (sTargetSql ?? "").Trim();
		if (sTargetSql.Length < 1) return new List<string>();

	int idx = sTargetSql.IndexOf("sql:",StringComparison.InvariantCultureIgnoreCase);
		if (idx < 0) return new List<string>();

	int iStart = idx + 4;
		if (iStart >= sTargetSql.Length) return new List<string>();

	string sList = sTargetSql.Substring(iStart);
		sList = sList.Replace("\"","");

	string[] ss = sList.Split(' ',StringSplitOptions.TrimEntries|StringSplitOptions.RemoveEmptyEntries);
		return new List<string>(ss);
	}

	public IEnumerable<string> hosts
	{
		get => mHosts.ToList();
	}
}