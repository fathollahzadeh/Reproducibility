
WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS RankByScore,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    WHERE p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(v.BountyAmount) AS TotalBounty,
        SUM(u.UpVotes) - SUM(u.DownVotes) AS NetVotes
    FROM Users u
    LEFT JOIN Votes v ON u.Id = v.UserId
    GROUP BY u.Id, u.DisplayName
),
PopularPosts AS (
    SELECT 
        rp.Id,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.CommentCount,
        ur.TotalBounty,
        ur.NetVotes
    FROM RankedPosts rp
    JOIN UserReputation ur ON rp.Id IN (SELECT AcceptedAnswerId FROM Posts WHERE OwnerUserId = ur.UserId)
    WHERE rp.RankByScore = 1
)
SELECT 
    pp.Id,
    pp.Title,
    pp.CreationDate,
    pp.Score,
    pp.CommentCount,
    COALESCE(pp.TotalBounty, 0) AS TotalBounty,
    COALESCE(pp.NetVotes, 0) AS NetVotes
FROM PopularPosts pp
FULL OUTER JOIN Users u ON pp.Id = u.Id
ORDER BY pp.Score DESC, pp.CommentCount DESC
LIMIT 50;
