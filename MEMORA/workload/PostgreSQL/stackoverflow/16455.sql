SELECT u.DisplayName, COUNT(p.Id) AS PostCount, SUM(v.BountyAmount) AS TotalBounties
FROM Users u
LEFT JOIN Posts p ON u.Id = p.OwnerUserId
LEFT JOIN Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (8, 9)  
GROUP BY u.DisplayName
ORDER BY PostCount DESC, TotalBounties DESC;