using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace CFrame_and_Vector3
{
	class Program
	{
		static void Main(string[] args)
		{
			CFrame dcf = new CFrame();
			CFrame cf1 = new CFrame(1, 2, 3) * CFrame.Angles((float)Math.PI / 3, (float)Math.PI / 6, 0);
			CFrame cf2 = new CFrame(-4, 5, 7.2f) * CFrame.Angles(0, (float)Math.PI / 7, -(float)Math.PI / 3);
			CFrame cf = cf1 * cf2;

			Vector3 v = new Vector3(10, -5, 6);
			Vector3 v2 = new Vector3(12.6602535f, -0.669872522f, -1.2320509f);

			Console.WriteLine(cf * cf2.inverse());
			Console.WriteLine(cf1.pointToObjectSpace(v2));
			Console.ReadLine();
		}
	}
}
