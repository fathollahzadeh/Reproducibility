
WITH PostMetrics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        SUM(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 ELSE 0 END) AS CloseCount,
        SUM(CASE WHEN ph.PostHistoryTypeId = 11 THEN 1 ELSE 0 END) AS ReopenCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    WHERE 
        p.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 YEAR'
    GROUP BY 
        p.Id, p.Title, p.Score, p.ViewCount, p.CreationDate
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        Score,
        ViewCount,
        CreationDate,
        CommentCount,
        UpVotes,
        DownVotes,
        CloseCount,
        ReopenCount,
        RANK() OVER (ORDER BY Score DESC, ViewCount DESC) AS RankScore,
        RANK() OVER (ORDER BY CreationDate DESC) AS RankRecent
    FROM 
        PostMetrics
)
SELECT 
    *,
    (RankScore + RankRecent) AS TotalRank
FROM 
    TopPosts
WHERE 
    (RankScore + RankRecent) <= 10
ORDER BY 
    TotalRank;
