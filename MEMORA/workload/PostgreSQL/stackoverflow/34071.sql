WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.Score > 0
),
RecentVotes AS (
    SELECT 
        v.PostId,
        v.VoteTypeId,
        COUNT(v.Id) AS VoteCount
    FROM 
        Votes v
    WHERE 
        v.CreationDate >= cast('2024-10-01' as date) - INTERVAL '30 days'
    GROUP BY 
        v.PostId, v.VoteTypeId
),
PostHistoryAggregates AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS EditCount,
        MAX(CASE WHEN ph.PostHistoryTypeId IN (4, 5, 6) THEN 1 ELSE 0 END) AS IsEdited,
        MAX(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 ELSE 0 END) AS IsClosed,
        MAX(CASE WHEN ph.PostHistoryTypeId = 11 THEN 1 ELSE 0 END) AS IsReopened
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.CreationDate,
        rp.OwnerDisplayName,
        pha.EditCount,
        pha.IsEdited,
        pha.IsClosed,
        pha.IsReopened,
        COALESCE(rv.VoteCount, 0) AS RecentVoteCount
    FROM 
        RankedPosts rp
    LEFT JOIN 
        PostHistoryAggregates pha ON rp.PostId = pha.PostId
    LEFT JOIN 
        RecentVotes rv ON rp.PostId = rv.PostId AND rv.VoteTypeId = 2 
    WHERE 
        rp.rn = 1
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.Score,
    fp.CreationDate,
    fp.OwnerDisplayName,
    fp.EditCount,
    fp.IsEdited,
    fp.IsClosed,
    fp.IsReopened,
    fp.RecentVoteCount,
    CASE 
        WHEN fp.IsClosed = 1 THEN 'Closed'
        WHEN fp.IsReopened = 1 THEN 'Reopened'
        ELSE 'Active'
    END AS PostStatus,
    (SELECT COUNT(*) FROM Comments c WHERE c.PostId = fp.PostId) AS CommentCount
FROM 
    FilteredPosts fp
ORDER BY 
    fp.Score DESC, 
    fp.CreationDate DESC
FETCH FIRST 10 ROWS ONLY;