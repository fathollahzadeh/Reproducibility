WITH UserVoteCounts AS (
    SELECT 
        UserId, 
        COUNT(CASE WHEN VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN VoteTypeId = 3 THEN 1 END) AS DownVotes
    FROM Votes
    GROUP BY UserId
),
PostMetrics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        COALESCE(v.UpVotes, 0) AS TotalUpVotes,
        COALESCE(v.DownVotes, 0) AS TotalDownVotes,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM Posts p
    LEFT JOIN UserVoteCounts v ON p.OwnerUserId = v.UserId
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Badges b ON p.OwnerUserId = b.UserId
    WHERE p.CreationDate > cast('2024-10-01' as date) - INTERVAL '1 year'
    GROUP BY p.Id, v.UpVotes, v.DownVotes
),
RankedPosts AS (
    SELECT 
        pm.*, 
        ROW_NUMBER() OVER (ORDER BY pm.Score DESC, pm.ViewCount DESC) AS Rank
    FROM PostMetrics pm
)
SELECT 
    rp.Rank, 
    rp.Title, 
    rp.PostId, 
    rp.ViewCount, 
    rp.Score, 
    rp.TotalUpVotes, 
    rp.TotalDownVotes, 
    rp.CommentCount, 
    rp.BadgeCount
FROM RankedPosts rp
WHERE rp.Rank <= 100
ORDER BY rp.Rank;