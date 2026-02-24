
WITH PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Badges b ON p.OwnerUserId = b.UserId
    WHERE 
        p.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year'  
    GROUP BY 
        p.Id, p.Title, p.CreationDate
),
PostHistoryCounts AS (
    SELECT
        ph.PostId,
        COUNT(*) AS HistoryCount
    FROM
        PostHistory ph
    GROUP BY
        ph.PostId
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.CreationDate,
    ps.CommentCount,
    ps.UpVotes,
    ps.DownVotes,
    phc.HistoryCount
FROM 
    PostStatistics ps
LEFT JOIN 
    PostHistoryCounts phc ON ps.PostId = phc.PostId
ORDER BY 
    ps.UpVotes DESC, ps.CommentCount DESC;
