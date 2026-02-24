WITH RankedPosts AS (
    SELECT 
        p.Id AS PostID,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        u.DisplayName AS OwnerName,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS PostRank,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 2) AS UpvoteCount,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 3) AS DownvoteCount
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= (cast('2024-10-01' as date) - INTERVAL '1 year')
),
PostDetails AS (
    SELECT 
        rp.PostID,
        rp.Title,
        rp.ViewCount,
        rp.Score,
        rp.OwnerName,
        rp.PostRank,
        COALESCE(rp.UpvoteCount, 0) AS Upvotes,
        COALESCE(rp.DownvoteCount, 0) AS Downvotes,
        CASE 
            WHEN rp.Score IS NULL THEN 'No Score'
            WHEN rp.Score > 0 THEN 'Positive Score'
            ELSE 'Negative Score'
        END AS ScoreStatus
    FROM 
        RankedPosts rp
)
SELECT 
    pd.PostID,
    pd.Title,
    pd.ViewCount,
    pd.Score,
    pd.OwnerName,
    pd.PostRank,
    pd.Upvotes,
    pd.Downvotes,
    pd.ScoreStatus,
    (SELECT COUNT(*) FROM PostHistory ph WHERE ph.PostId = pd.PostID AND ph.PostHistoryTypeId IN (10, 11)) AS CloseReopenCount
FROM 
    PostDetails pd
WHERE 
    pd.PostRank <= 5  
ORDER BY 
    pd.Score DESC,
    pd.ViewCount DESC;