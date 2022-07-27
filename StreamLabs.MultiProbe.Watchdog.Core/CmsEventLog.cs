using System.Data;
using System.Data.Common;
using System.Data.SqlClient;
using System.Net;

namespace StreamLabs.MultiProbe.Watchdog.Core;

public class CmsEventLog
{
private const string DefaultHost = "locahost";

private string m_sHost = CmsEventLog.DefaultHost;

	public CmsEventLog ()
	{
	}

	public CmsEventLog (string sHost)
	{
		this.host = sHost;
	}

	public string host
	{
		get => m_sHost;
		private set
		{
		string s = (value ?? "").Trim();
			m_sHost = (s.Length > 0)?s:CmsEventLog.DefaultHost;
		}
	}

	public async Task reportAsync (CancellationToken ct)
	{
	SqlConnection? cnn = null;

		try
		{
			//this.testConnectivity();

			//using special name mapped to docker's localhost
			//cnn = new SqlConnection("Data Source = host.docker.internal,1433; Initial Catalog = CircuitWatchdog; User ID = watchdog; Password = 18BB1E14-8837-4FD6-AB9B-72240DC3C9F4");
			
			//using known fixed IPv4 addr
			//cnn = new SqlConnection("Data Source = 192.168.65.2,1433; Initial Catalog = CircuitWatchdog; User ID = watchdog; Password = 18BB1E14-8837-4FD6-AB9B-72240DC3C9F4");

		string sCnn = $"Data Source = tcp:{this.host},1433; Initial Catalog = CircuitWatchdog; User ID = watchdog; Password = 18BB1E14-8837-4FD6-AB9B-72240DC3C9F4";
			cnn = new SqlConnection(sCnn);
			await cnn.OpenAsync(ct);

			using (DbTransaction tran = await cnn.BeginTransactionAsync(IsolationLevel.Serializable,ct).ConfigureAwait(false))
			{
				try
				{
					using (SqlCommand cmd = new SqlCommand(@"INSERT INTO Bus.Evnts (Lvl,Src,Dsc)
VALUES(@Lvl,@Src,@Dsc)",cnn,tran as SqlTransaction))
					{
						cmd.CommandType = CommandType.Text;
						cmd.Parameters.Add("Lvl",SqlDbType.Int).Value = 0;
						CmsEventLog.AddNullableParam(cmd,"Src","Test Source",32);
						CmsEventLog.AddNullableParam(cmd,"Dsc","Test message goes here...",256);

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

	private string getHostName ()
	{
	string ret = "";
		
		try
		{
			ret = Dns.GetHostName().Trim();
		}
		catch
		{
		}

		if (ret.Length > 0) return ret;

		try
		{
			ret = Environment.MachineName.Trim();
		}
		catch
		{
		}

		return ret;
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
