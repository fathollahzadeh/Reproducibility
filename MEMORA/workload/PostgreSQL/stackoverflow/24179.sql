WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        p.PostTypeId,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS RankScore,
        COUNT(v.Id) AS VoteCount,
        COALESCE(b.UserId, -1) AS BadgeOwnerId,
        MAX(b.Class) AS MaxBadgeClass
    FROM 
        Posts p
    LEFT JOIN Votes v ON p.Id = v.PostId AND v.VoteTypeId = 2 
    LEFT JOIN Badges b ON p.OwnerUserId = b.UserId
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year' 
    GROUP BY 
        p.Id, p.Title, p.Score, p.ViewCount, p.CreationDate, p.PostTypeId, b.UserId
),
PostHistoryAggregated AS (
    SELECT 
        ph.PostId,
        COUNT(ph.Id) FILTER (WHERE ph.PostHistoryTypeId IN (10, 11)) AS CloseOpenCount,
        COUNT(ph.Id) FILTER (WHERE ph.PostHistoryTypeId = 12) AS DeletionCount,
        COUNT(ph.Id) FILTER (WHERE ph.PostHistoryTypeId = 24 AND ph.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '6 MONTH') AS SuggestionsAppliedCount
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
),
PostDetails AS (
    SELECT
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.ViewCount,
        ph.CloseOpenCount,
        ph.DeletionCount,
        ph.SuggestionsAppliedCount,
        rp.RankScore,
        COALESCE(rp.BadgeOwnerId, -1) AS BadgeOwnerId,
        rp.MaxBadgeClass
    FROM 
        RankedPosts rp
    LEFT JOIN PostHistoryAggregated ph ON rp.PostId = ph.PostId
    WHERE 
        rp.RankScore <= 5 
)
SELECT 
    pd.PostId,
    pd.Title,
    pd.Score,
    pd.ViewCount,
    pd.CloseOpenCount,
    pd.DeletionCount,
    pd.SuggestionsAppliedCount,
    CASE 
        WHEN pd.MaxBadgeClass IS NULL THEN 'No Badge'
        ELSE CASE 
            WHEN pd.MaxBadgeClass = 1 THEN 'Gold'
            WHEN pd.MaxBadgeClass = 2 THEN 'Silver'
            WHEN pd.MaxBadgeClass = 3 THEN 'Bronze'
            ELSE 'Unknown Badge Class'
        END
    END AS BadgeClassification,
    CASE 
        WHEN pd.DeletionCount > 0 THEN 'Post Deleted'
        ELSE 'Active Post'
    END AS PostStatus,
    CASE 
        WHEN pd.CloseOpenCount > 0 THEN 'Partially Closed'
        ELSE 'Open'
    END AS ClosureStatus
FROM 
    PostDetails pd
WHERE 
    pd.ViewCount > 100 OR pd.Score > 5 
ORDER BY 
    pd.Score DESC, pd.ViewCount DESC
LIMIT 100;