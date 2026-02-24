
WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS ScoreRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
), 
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvotesReceived,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownvotesReceived
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
), 
ClosedPosts AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS CloseCount
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10
    GROUP BY 
        ph.PostId
), 
PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        COALESCE(cp.CloseCount, 0) AS TotalCloseCount,
        us.DisplayName AS OwnerDisplayName,
        us.Reputation AS OwnerReputation,
        CASE 
            WHEN p.OwnerUserId IS NULL THEN 'Deleted User'
            ELSE us.DisplayName 
        END AS EffectiveOwner
    FROM 
        Posts p
    LEFT JOIN 
        UserStats us ON p.OwnerUserId = us.UserId
    LEFT JOIN 
        ClosedPosts cp ON p.Id = cp.PostId
    WHERE 
        p.PostTypeId = 1 AND p.Score > 10
)

SELECT 
    pd.PostId,
    pd.Title,
    pd.Score,
    pd.TotalCloseCount,
    pd.OwnerDisplayName,
    pd.OwnerReputation,
    pd.EffectiveOwner
FROM 
    PostDetails pd
WHERE 
    pd.TotalCloseCount = 0
ORDER BY 
    pd.Score DESC, 
    pd.Title ASC;
