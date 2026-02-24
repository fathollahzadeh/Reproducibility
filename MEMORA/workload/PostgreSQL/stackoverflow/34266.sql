
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS RankByUser,
        u.DisplayName AS OwnerDisplayName,
        u.Reputation
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    LEFT JOIN 
        Users u ON u.Id = p.OwnerUserId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
        AND (p.Score > 0 OR p.OwnerUserId IS NOT NULL)
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, u.DisplayName, u.Reputation
),
HighScorePosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.CommentCount,
        rp.Upvotes,
        rp.Downvotes,
        rp.OwnerDisplayName,
        rp.Reputation,
        CASE 
            WHEN rp.Score > 50 THEN 'High Scorer'
            WHEN rp.Score BETWEEN 20 AND 50 THEN 'Medium Scorer'
            ELSE 'Low Scorer'
        END AS ScoreCategory
    FROM 
        RankedPosts rp
    WHERE 
        rp.RankByUser <= 10
),
ClosedPosts AS (
    SELECT 
        p.Id AS ClosedPostId,
        ph.CreationDate AS ClosedDate,
        ph.UserId AS CloserUserId,
        ph.Comment AS CloseReason,
        p.Title
    FROM 
        PostHistory ph
    INNER JOIN 
        Posts p ON p.Id = ph.PostId
    WHERE 
        ph.PostHistoryTypeId = 10
)
SELECT 
    hsp.PostId,
    hsp.Title,
    hsp.CreationDate,
    hsp.Score,
    hsp.CommentCount,
    hsp.Upvotes,
    hsp.Downvotes,
    hsp.OwnerDisplayName,
    hsp.Reputation,
    hsp.ScoreCategory,
    cp.ClosedDate,
    cp.ClosedPostId,
    cp.CloseReason
FROM 
    HighScorePosts hsp
LEFT JOIN 
    ClosedPosts cp ON hsp.PostId = cp.ClosedPostId
ORDER BY 
    hsp.Score DESC, hsp.CreationDate DESC
LIMIT 100;
