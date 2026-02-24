WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Tags,
        p.ViewCount,
        p.Score,
        p.OwnerUserId,
        COUNT(c.Id) AS CommentCount,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank,
        ROW_NUMBER() OVER (ORDER BY p.CreationDate DESC) AS RecentRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1 AND 
        p.Score IS NOT NULL
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Tags, p.ViewCount, p.Score, p.OwnerUserId
), 
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        b.Class,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId 
    GROUP BY 
        u.Id, b.Class
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.CreationDate,
        COUNT(DISTINCT ph.UserId) AS EditorCount,
        STRING_AGG(DISTINCT ph.Comment, '; ') AS HistoryComments
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11, 12, 19, 20) 
    GROUP BY 
        ph.PostId, ph.PostHistoryTypeId, ph.CreationDate
)
SELECT 
    up.DisplayName AS UserDisplayName,
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.ViewCount,
    rp.Score,
    rp.CommentCount,
    CASE 
        WHEN ub.BadgeCount > 0 THEN 'Has Badges'
        ELSE 'No Badges'
    END AS BadgeStatus,
    CASE 
        WHEN phd.EditorCount IS NOT NULL THEN phd.EditorCount
        ELSE 0
    END AS TotalEditors,
    COALESCE(phd.HistoryComments, 'No Edit History') AS EditHistory
FROM 
    RankedPosts rp
JOIN 
    Users up ON rp.OwnerUserId = up.Id
LEFT JOIN 
    UserBadges ub ON up.Id = ub.UserId
LEFT JOIN 
    PostHistoryDetails phd ON rp.PostId = phd.PostId
WHERE 
    rp.PostRank = 1 
    AND rp.RecentRank <= 10
ORDER BY 
    rp.Score DESC, rp.ViewCount DESC
OFFSET 5 ROWS FETCH NEXT 5 ROWS ONLY;
