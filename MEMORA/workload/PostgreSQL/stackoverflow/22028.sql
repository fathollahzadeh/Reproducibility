
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Score,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS Rank,
        COUNT(c.Id) AS CommentCount,
        COALESCE(UPPER(p.Tags), 'NO TAGS') AS FormattedTags
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year' 
    GROUP BY 
        p.Id, p.Score, p.Title, p.CreationDate, p.ViewCount, p.OwnerUserId, p.Tags
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        SUM(b.Class) AS TotalBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
PostVoteCounts AS (
    SELECT 
        v.PostId, 
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes
    FROM 
        Votes v
    GROUP BY 
        v.PostId
),
PostHistorySummary AS (
    SELECT 
        ph.PostId,
        COUNT(ph.Id) AS EditCount,
        MAX(ph.CreationDate) AS LastEditDate
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 24) 
    GROUP BY 
        ph.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Score,
    rp.ViewCount,
    rp.CommentCount,
    rp.FormattedTags,
    COALESCE(up.TotalBadges, 0) AS TotalBadges,
    COALESCE(pvc.Upvotes, 0) AS Upvotes,
    COALESCE(pvc.Downvotes, 0) AS Downvotes,
    COALESCE(phs.EditCount, 0) AS EditCount,
    phs.LastEditDate,
    CASE 
        WHEN rp.Rank = 1 THEN 'Latest Post' 
        ELSE 'Older Post' 
    END AS PostStatus
FROM 
    RankedPosts rp
LEFT JOIN 
    UserReputation up ON rp.OwnerUserId = up.UserId
LEFT JOIN 
    PostVoteCounts pvc ON rp.PostId = pvc.PostId
LEFT JOIN 
    PostHistorySummary phs ON rp.PostId = phs.PostId
WHERE 
    rp.Rank <= 5
    AND (rp.ViewCount > 100 OR (phs.EditCount IS NOT NULL AND phs.EditCount > 3))
ORDER BY 
    rp.Score DESC, 
    rp.CreationDate DESC
FETCH FIRST 10 ROWS ONLY;
