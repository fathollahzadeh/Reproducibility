
WITH PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 2) AS UpVotes,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 3) AS DownVotes,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        u.Reputation AS OwnerReputation
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    LEFT JOIN Users u ON p.OwnerUserId = u.Id
    LEFT JOIN Badges b ON u.Id = b.UserId
    WHERE p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'  
    GROUP BY p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, u.Reputation
)

SELECT 
    ps.PostId,
    ps.Title,
    ps.CreationDate,
    ps.Score,
    ps.ViewCount,
    ps.CommentCount,
    ps.UpVotes,
    ps.DownVotes,
    ps.BadgeCount,
    ps.OwnerReputation,
    CASE 
        WHEN ps.Score >= 0 THEN 'Positive'
        ELSE 'Negative'
    END AS Sentiment
FROM PostStatistics ps
ORDER BY ps.ViewCount DESC, ps.Score DESC
FETCH FIRST 100 ROWS ONLY;
