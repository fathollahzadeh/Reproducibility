
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.Tags,
        u.DisplayName AS OwnerName,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.ViewCount DESC) AS RankByViews,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS RankByScore
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),
PostActivities AS (
    SELECT 
        rp.PostId,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 2) AS UpVoteCount,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 3) AS DownVoteCount,
        SUM(CASE WHEN bh.PostHistoryTypeId = 10 THEN 1 ELSE 0 END) AS CloseCount,
        SUM(CASE WHEN bh.PostHistoryTypeId = 11 THEN 1 ELSE 0 END) AS ReopenCount
    FROM 
        RankedPosts rp
    LEFT JOIN 
        Comments c ON c.PostId = rp.PostId
    LEFT JOIN 
        Votes v ON v.PostId = rp.PostId
    LEFT JOIN 
        PostHistory bh ON bh.PostId = rp.PostId
    GROUP BY 
        rp.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.OwnerName,
    rp.CreationDate,
    rp.ViewCount,
    rp.Score,
    rp.Tags,
    pa.CommentCount,
    pa.UpVoteCount,
    pa.DownVoteCount,
    pa.CloseCount,
    pa.ReopenCount,
    CASE 
        WHEN rp.RankByViews <= 5 THEN 'Top Views'
        WHEN rp.RankByScore <= 5 THEN 'Top Scores'
        ELSE 'Others'
    END AS PostCategory
FROM 
    RankedPosts rp
JOIN 
    PostActivities pa ON rp.PostId = pa.PostId
WHERE 
    rp.RankByViews <= 10 OR rp.RankByScore <= 10
ORDER BY 
    rp.RankByViews, rp.RankByScore DESC;
