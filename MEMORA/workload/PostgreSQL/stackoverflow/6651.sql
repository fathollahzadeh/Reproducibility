
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpvoteCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownvoteCount,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId 
    LEFT JOIN 
        Comments c ON p.Id = c.PostId 
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.PostTypeId
),
MostCommented AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.UpvoteCount,
        rp.DownvoteCount,
        rp.CommentCount,
        RANK() OVER (ORDER BY rp.CommentCount DESC) AS CommentRank
    FROM 
        RankedPosts rp
)
SELECT 
    mc.PostId,
    mc.Title,
    mc.CreationDate,
    mc.Score,
    mc.ViewCount,
    mc.UpvoteCount,
    mc.DownvoteCount,
    mc.CommentCount
FROM 
    MostCommented mc
WHERE 
    mc.CommentRank <= 10
ORDER BY 
    mc.CommentCount DESC, mc.CreationDate DESC;
