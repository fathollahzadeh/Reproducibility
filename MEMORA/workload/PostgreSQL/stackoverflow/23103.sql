
WITH UserVotingStats AS (
    SELECT 
        u.Id AS UserId, 
        COUNT(v.Id) AS TotalVotes, 
        SUM(CASE WHEN vt.Name = 'UpMod' THEN 1 ELSE 0 END) AS UpVotesCount,
        SUM(CASE WHEN vt.Name = 'DownMod' THEN 1 ELSE 0 END) AS DownVotesCount,
        AVG(COALESCE(v.BountyAmount, 0)) AS AverageBountyAmount
    FROM 
        Users u
    LEFT JOIN Votes v ON u.Id = v.UserId
    LEFT JOIN VoteTypes vt ON v.VoteTypeId = vt.Id
    GROUP BY 
        u.Id
), 
PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RecentPostRank
    FROM 
        Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.Score, p.ViewCount
), 
ClosedPosts AS (
    SELECT 
        ph.PostId, 
        ph.Comment AS CloseReason,
        p.Title AS PostTitle,
        ROW_NUMBER() OVER (ORDER BY ph.CreationDate DESC) AS CloseRank
    FROM 
        PostHistory ph
    JOIN Posts p ON ph.PostId = p.Id
    WHERE 
        ph.PostHistoryTypeId = 10 
)
SELECT 
    u.DisplayName,
    u.Reputation,
    us.TotalVotes AS UserTotalVotes,
    us.UpVotesCount,
    us.DownVotesCount,
    ps.PostId,
    ps.Title AS PostTitle,
    ps.Score,
    ps.ViewCount,
    ps.CommentCount,
    cp.CloseReason AS LastCloseReason,
    cp.CloseRank
FROM 
    Users u
LEFT JOIN UserVotingStats us ON u.Id = us.UserId
LEFT JOIN PostStatistics ps ON ps.RecentPostRank = 1 AND ps.CommentCount > 0
LEFT JOIN ClosedPosts cp ON cp.PostId = ps.PostId
WHERE 
    u.Reputation > 1000 AND 
    (us.UpVotesCount > us.DownVotesCount OR us.TotalVotes > 10)
ORDER BY 
    u.Reputation DESC, 
    ps.Score DESC; 
