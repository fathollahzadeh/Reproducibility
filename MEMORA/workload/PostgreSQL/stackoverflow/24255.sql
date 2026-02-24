WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 2) AS UpvoteCount,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 3) AS DownvoteCount,
        COALESCE((SELECT pt.Name FROM PostTypes pt WHERE pt.Id = p.PostTypeId), 'Unknown') AS PostType
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
        AND p.Score IS NOT NULL
),
PostWithComments AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.Rank,
        rp.UpvoteCount,
        rp.DownvoteCount,
        rp.PostType,
        COUNT(c.Id) AS CommentCount
    FROM 
        RankedPosts rp
    LEFT JOIN 
        Comments c ON c.PostId = rp.PostId
    GROUP BY 
        rp.PostId, rp.Title, rp.CreationDate, rp.Score, rp.ViewCount, rp.Rank, rp.UpvoteCount, rp.DownvoteCount, rp.PostType
),
PostHistoryData AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS EditCount,
        MAX(ph.CreationDate) AS LastEditDate
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5)  
    GROUP BY 
        ph.PostId
),
CommentedPosts AS (
    SELECT 
        pwc.PostId,
        pwc.Title,
        pwc.CreationDate,
        pwc.Score,
        pwc.ViewCount,
        pwc.Rank,
        pwc.UpvoteCount,
        pwc.DownvoteCount,
        pwc.PostType,
        pwc.CommentCount,
        COALESCE(ph.EditCount, 0) AS EditCount,
        ph.LastEditDate
    FROM 
        PostWithComments pwc
    LEFT JOIN 
        PostHistoryData ph ON pwc.PostId = ph.PostId
)
SELECT 
    cp.PostId,
    cp.Title,
    cp.CreationDate,
    cp.Score,
    cp.ViewCount,
    cp.Rank,
    cp.UpvoteCount,
    cp.DownvoteCount,
    cp.PostType,
    cp.CommentCount,
    cp.EditCount,
    cp.LastEditDate,
    GREATEST(cp.UpvoteCount, cp.ViewCount / NULLIF(cp.CommentCount, 0)) AS EngagementScore 
FROM 
    CommentedPosts cp
WHERE 
    cp.CommentCount > 5 
ORDER BY 
    EngagementScore DESC, cp.Score DESC
FETCH FIRST 10 ROWS ONLY;