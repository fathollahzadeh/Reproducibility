
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.ViewCount DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),
BestPosts AS (
    SELECT 
        PostId, 
        Title, 
        ViewCount, 
        Score, 
        CreationDate, 
        OwnerDisplayName
    FROM 
        RankedPosts
    WHERE 
        PostRank = 1
),
PostStats AS (
    SELECT 
        bp.PostId,
        bp.Title,
        bp.ViewCount,
        bp.Score,
        bp.CreationDate,
        bp.OwnerDisplayName,
        COALESCE(COUNT(c.Id), 0) AS CommentCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpvoteCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownvoteCount
    FROM 
        BestPosts bp
    LEFT JOIN 
        Comments c ON bp.PostId = c.PostId
    LEFT JOIN 
        Votes v ON bp.PostId = v.PostId
    GROUP BY 
        bp.PostId, bp.Title, bp.ViewCount, bp.Score, bp.CreationDate, bp.OwnerDisplayName
)
SELECT 
    PostId,
    Title,
    ViewCount,
    Score,
    CreationDate,
    OwnerDisplayName,
    CommentCount,
    UpvoteCount,
    DownvoteCount,
    (ViewCount + UpvoteCount - DownvoteCount) AS EngagementScore
FROM 
    PostStats
ORDER BY 
    EngagementScore DESC
LIMIT 10;
