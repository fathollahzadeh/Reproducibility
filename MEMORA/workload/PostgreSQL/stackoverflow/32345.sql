
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        U.DisplayName AS OwnerDisplayName,
        COUNT(DISTINCT v.Id) AS VoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.ViewCount DESC) AS ViewRank,
        RANK() OVER (ORDER BY p.CreationDate DESC) AS LatestPostRank
    FROM 
        Posts p
    LEFT JOIN 
        Users U ON p.OwnerUserId = U.Id
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, U.DisplayName
),

ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        ph.Comment AS CloseReason,
        ph.UserDisplayName AS CloserUser
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10 
),

PostDetails AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.OwnerDisplayName,
        COALESCE(cp.CloseReason, 'Not Closed') AS CloseReason,
        COALESCE(cp.CloserUser, 'N/A') AS CloserUser,
        rp.VoteCount,
        rp.ViewRank,
        rp.LatestPostRank
    FROM 
        RankedPosts rp
    LEFT JOIN 
        ClosedPosts cp ON rp.PostId = cp.PostId
)

SELECT 
    pd.PostId,
    pd.Title,
    pd.CreationDate,
    pd.ViewCount,
    pd.OwnerDisplayName,
    pd.CloseReason,
    pd.CloserUser,
    pd.VoteCount,
    pd.ViewRank,
    pd.LatestPostRank,
    CASE 
        WHEN pd.ViewRank = 1 THEN 'Most Viewed Post by Author'
        WHEN pd.LatestPostRank <= 10 THEN 'Recent Top 10 Posts'
        ELSE 'Other Posts'
    END AS PostCategory
FROM 
    PostDetails pd
WHERE 
    pd.ViewCount > 0
ORDER BY 
    pd.ViewCount DESC, pd.CreationDate DESC;
