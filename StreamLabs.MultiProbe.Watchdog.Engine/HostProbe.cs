using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Net;
using System.Net.Sockets;

namespace StreamLabs.MultiProbe.Watchdog.Engine;

public static class HostProbe
{
	public static async Task<string> FindAliveAsync (IEnumerable<string> hosts, CancellationToken ct)
	{
		if (hosts == null) return "";

		foreach (string sHost in hosts)
		{
		//Task<bool> test = HostProbe.TestConnectivityAsync(sHost,ct);
		bool bTest = await HostProbe.TestConnectivityAsync(sHost,ct).ConfigureAwait(false);
			if (bTest) return sHost;
		}

		return "";
	}

	public static async Task<bool> TestConnectivityAsync (string sHost, CancellationToken ct)
	{
		try
		{
		string s = (sHost ?? "").Trim();
			if (s.Length < 1) return false;

			using (TcpClient tcp = new TcpClient())
			{
			IPHostEntry hEntry = await Dns.GetHostEntryAsync(s,ct).ConfigureAwait(false);
			IPAddress? addr = (hEntry.AddressList.Length > 0)?hEntry.AddressList[0]:null;
				if (addr == null) return false; //cannot be resolved

			//IPAddress addr = IPAddress.Parse("192.168.65.2");
			IPEndPoint ep = new IPEndPoint(addr,1433);
				await tcp.ConnectAsync(ep,ct).ConfigureAwait(false);
			}

			return true;
		}
		catch (Exception x)
		{
		string sErr = x.ToString(); //for debug puposes
			return false;
		}
	}
}
