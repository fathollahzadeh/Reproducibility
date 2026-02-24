
WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COALESCE(SUM(CASE WHEN b.Id IS NOT NULL THEN 1 ELSE 0 END), 0) AS BadgeCount
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON p.Id = v.PostId
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id, u.DisplayName, u.Reputation
),
PostActivity AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        EXTRACT(YEAR FROM p.CreationDate) AS PostYear,
        COUNT(c.Id) AS CommentCount,
        COALESCE(MAX(h.CreationDate), '1970-01-01') AS LastEditDate
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN PostHistory h ON p.Id = h.PostId
    GROUP BY p.Id, p.Title, p.CreationDate
),
TopUsers AS (
    SELECT 
        us.UserId,
        us.DisplayName,
        us.Reputation,
        RANK() OVER (ORDER BY us.Reputation DESC) AS UserRank
    FROM UserStats us
    WHERE us.PostCount > 0
)
SELECT 
    tu.UserId,
    tu.DisplayName,
    tu.Reputation,
    tu.UserRank,
    pa.Title,
    pa.CommentCount,
    pa.LastEditDate,
    pa.PostYear,
    us.TotalBounty,
    us.UpVotes,
    us.DownVotes,
    us.BadgeCount
FROM TopUsers tu
JOIN UserStats us ON tu.UserId = us.UserId
JOIN PostActivity pa ON us.UserId = pa.PostId
WHERE pa.PostYear = 2023
ORDER BY tu.UserRank, pa.CommentCount DESC
LIMIT 50;
