
WITH UserVotes AS (
    SELECT 
        v.UserId, 
        COUNT(v.Id) AS VoteCount, 
        SUM(CASE WHEN vt.Name = 'UpMod' THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN vt.Name = 'DownMod' THEN 1 ELSE 0 END) AS DownVotes
    FROM Votes v
    JOIN VoteTypes vt ON v.VoteTypeId = vt.Id
    GROUP BY v.UserId
),
PostMetrics AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.Id END) AS CloseCount,
        COUNT(DISTINCT CASE WHEN ph.PostHistoryTypeId = 11 THEN ph.Id END) AS ReopenCount,
        AVG(COALESCE(vb.BountyAmount, 0)) AS AverageBounty
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN PostHistory ph ON p.Id = ph.PostId
    LEFT JOIN (SELECT Id, UserId, SUM(BountyAmount) AS BountyAmount FROM Votes WHERE VoteTypeId = 9 GROUP BY Id, UserId) vb ON p.Id = vb.Id
    GROUP BY p.Id, p.OwnerUserId
),
RankedPosts AS (
    SELECT 
        pm.PostId,
        pm.OwnerUserId,
        pm.CommentCount,
        pm.CloseCount,
        pm.ReopenCount,
        pm.AverageBounty,
        RANK() OVER (PARTITION BY pm.OwnerUserId ORDER BY pm.CommentCount DESC, pm.CloseCount - pm.ReopenCount DESC) AS RankByMetrics
    FROM PostMetrics pm
)
SELECT 
    u.DisplayName, 
    u.Reputation,
    p.Title,
    rp.CommentCount,
    rp.CloseCount,
    rp.ReopenCount,
    rp.AverageBounty,
    COALESCE(uv.VoteCount, 0) AS TotalVotes,
    COALESCE(uv.UpVotes, 0) AS UpVoteCount,
    COALESCE(uv.DownVotes, 0) AS DownVoteCount
FROM Users u
JOIN RankedPosts rp ON u.Id = rp.OwnerUserId
LEFT JOIN UserVotes uv ON u.Id = uv.UserId
JOIN Posts p ON rp.PostId = p.Id
WHERE rp.RankByMetrics <= 5
ORDER BY u.Reputation DESC, rp.CommentCount DESC;
