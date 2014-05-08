-record(usr, { msisdn,						%int()
							 id,								%term()
							 status = enabled,	%atom(), enabled | disabled
							 plan,							%atom(), prepay  | postpay
							 services = []}).		%[atom()], a list of the system flags