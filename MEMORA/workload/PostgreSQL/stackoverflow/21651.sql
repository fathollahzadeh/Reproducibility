
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate ASC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.ViewCount > 100
),
UserBadgeCounts AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldCount,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverCount,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeCount
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
PostHistoryExtensions AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.CreationDate,
        ph.UserId,
        ph.Comment,
        COALESCE(CAST(ph.Text AS JSON), CAST('{}' AS JSON)) AS PostHistoryDetails
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11, 12, 13)  
),
ModerationComments AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentCount
    FROM 
        Comments c
    JOIN 
        Posts p ON c.PostId = p.Id
    WHERE 
        c.CreationDate > p.CreationDate
    GROUP BY 
        c.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.ViewCount,
    ub.BadgeCount,
    ub.GoldCount,
    ub.SilverCount,
    ub.BronzeCount,
    ph.PostHistoryDetails,
    COALESCE(mc.CommentCount, 0) AS ModerationCommentCount,
    CASE 
        WHEN ub.BadgeCount IS NULL THEN 'No Badges'
        WHEN ub.BadgeCount > 10 THEN 'Active User'
        ELSE 'New User'
    END AS UserCategory
FROM 
    RankedPosts rp
LEFT JOIN 
    UserBadgeCounts ub ON rp.PostId = ub.UserId
LEFT JOIN 
    PostHistoryExtensions ph ON rp.PostId = ph.PostId
LEFT JOIN 
    ModerationComments mc ON rp.PostId = mc.PostId
WHERE 
    rp.Rank <= 5
    AND (ph.PostHistoryTypeId IS NULL OR ph.Comment IS NOT NULL)
ORDER BY 
    rp.CreationDate DESC;
