WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS RN
    FROM Posts p
),
UserVoteAnalytics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(v.Id) AS TotalVotes,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        SUM(CASE WHEN v.VoteTypeId IN (1, 4, 7) THEN 1 ELSE 0 END) AS Acceptances
    FROM Users u
    LEFT JOIN Votes v ON u.Id = v.UserId
    GROUP BY u.Id, u.DisplayName
)
SELECT 
    up.DisplayName AS UserName,
    rp.PostId,
    rp.Title,
    rp.ViewCount,
    up.TotalVotes,
    up.UpVotes,
    up.DownVotes,
    up.Acceptances,
    CASE 
        WHEN up.TotalVotes IS NULL THEN 'No Votes'
        WHEN up.TotalVotes > 50 THEN 'High Engagement'
        ELSE 'Moderate Engagement'
    END AS EngagementLevel,
    COUNT(DISTINCT c.Id) AS CommentCount,
    COALESCE(MAX(cl.Name), 'No Close Reason') AS CloseReason
FROM RankedPosts rp
LEFT JOIN UserVoteAnalytics up ON up.UserId = rp.PostId % 1000 
LEFT JOIN Comments c ON c.PostId = rp.PostId
LEFT JOIN PostHistory ph ON ph.PostId = rp.PostId AND ph.PostHistoryTypeId = 10 
LEFT JOIN CloseReasonTypes cl ON cl.Id = CAST(ph.Comment AS INT) 
WHERE rp.RN <= 10 
GROUP BY up.DisplayName, rp.PostId, rp.Title, rp.ViewCount, up.TotalVotes, up.UpVotes, up.DownVotes, up.Acceptances
HAVING AVG(rp.ViewCount) IS NULL OR SUM(up.UpVotes) > SUM(up.DownVotes) 
ORDER BY rp.ViewCount DESC, EngagementLevel;