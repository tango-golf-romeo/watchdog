using System.Data;
using System.Data.Common;
using System.Data.SqlClient;
using System.Net;
using System.Net.Sockets;

namespace StreamLabs.MultiProbe.Watchdog.Core;

internal class CmsEventLog
{
	public CmsEventLog ()
	{
	}

	public async Task reportAsync (CancellationToken ct)
	{
	SqlConnection? cnn = null;

		try
		{
			//this.testConnectivity();

			//cnn = new SqlConnection("Data Source = host.docker.internal,1433; Initial Catalog = CircuitWatchdog; User ID = watchdog; Password = watchdog");
			//cnn = new SqlConnection("Data Source = 192.168.65.2,1433; Initial Catalog = CircuitWatchdog; User ID = watchdog; Password = watchdog");
			cnn = new SqlConnection("Data Source = alphablack,1433; Initial Catalog = CircuitWatchdog; User ID = watchdog; Password = watchdog");
			await cnn.OpenAsync(ct);

			using (DbTransaction tran = await cnn.BeginTransactionAsync(IsolationLevel.Serializable,ct).ConfigureAwait(false))
			{
				try
				{
					using (SqlCommand cmd = new SqlCommand(@"INSERT INTO Events ([Level],Source,Message)
VALUES(@Level,@Source,@Message)",cnn,tran as SqlTransaction))
					{
						cmd.CommandType = CommandType.Text;
						cmd.Parameters.Add("Level",SqlDbType.Int).Value = 0;
						CmsEventLog.AddNullableParam(cmd,"Source","Test Source",32);
						CmsEventLog.AddNullableParam(cmd,"Message","Test message goes here...",256);

						await cmd.ExecuteNonQueryAsync(ct).ConfigureAwait(false);

						await tran.CommitAsync(ct).ConfigureAwait(false);
					}
				}
				catch
				{
					await tran.RollbackAsync(ct).ConfigureAwait(false);
					throw;
				}
			}
		}
		finally
		{
			CmsEventLog.Destroy(ref cnn);
		}
	}

	private bool testConnectivity ()
	{
		try
		{
			using (TcpClient tcp = new TcpClient())
			{
			IPHostEntry hEntry = Dns.GetHostEntry("alphablack");
			IPAddress? addr = (hEntry.AddressList.Length > 0)?hEntry.AddressList[0]:null;
			//IPAddress addr = IPAddress.Parse("192.168.65.2");
				if (addr != null)
				{
				IPEndPoint ep = new IPEndPoint(addr,1433);
					tcp.Connect(ep);
				}
			}

			return true;
		}
		catch (Exception x)
		{
		string sErr = x.Message;
			return false;
		}
	}

	private static void Destroy (ref SqlDataReader? rec)
	{
		if (rec == null) return;
		if (CmsEventLog.CanClose(rec)) rec.Close();
		rec.Dispose();
		rec = null;
	}

	private static bool CanClose (SqlDataReader rec)
	{
	bool bOpen = ((rec != null) && !rec.IsClosed);
		return bOpen;
	}

	private static bool CanClose (SqlConnection cnn)
	{
	bool bOpen = ((cnn != null) && ((cnn.State & ConnectionState.Open) == ConnectionState.Open));
		return bOpen;
	}

	private static void Destroy (ref SqlConnection? cnn)
	{
		if (cnn == null) return;
		if (CmsEventLog.CanClose(cnn)) cnn.Close();
		SqlConnection.ClearPool(cnn);
		cnn.Dispose();
		cnn = null;
	}

	private static void AddNullableParam (SqlCommand cmd, string sName, string sData, int iMaxSize)
	{
	string? s = string.IsNullOrEmpty(sData)?null:sData;
		
		//ado.net will truncate the string if required
		cmd.Parameters.Add(sName,SqlDbType.NVarChar,CmsEventLog.MakeStringSize(s,iMaxSize)).Value =
CmsEventLog.MakeStringData(s);
	}

	private static object MakeStringData (string? sData)
	{
		//we must return object so cannot use short notation
		if (sData == null)
			return DBNull.Value;
		else
			return sData;
	}

	private static object MakeStringData (string? sData, int iMaxSize)
	{
		if (sData == null) return DBNull.Value;
		else
		{
			if (iMaxSize < 0) return sData;

		int iLength = sData.Length;
			if (iLength <= iMaxSize) return sData;

			return sData.Substring(0,iMaxSize);
		}
	}

	private static int MakeStringSize (string? sData) => sData?.Length ?? 0;

	private static int MakeStringSize (string? sData, int iMaxSize)
	{
		if (sData == null) return 0;
		else
		{
			if (iMaxSize < 0) return sData.Length;

		int iLength = sData.Length;
			return (iMaxSize < iLength)?iMaxSize:iLength;
		}
	}
}
