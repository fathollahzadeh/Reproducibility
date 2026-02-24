
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate ASC) AS rn
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),
BadgedUsers AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        MAX(b.Class) AS HighestBadgeClass
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
ClosedPostCounts AS (
    SELECT 
        ph.PostId,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 END) AS CloseCount,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 11 THEN 1 END) AS ReopenCount
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
),
PostComments AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentCount,
        MAX(c.CreationDate) AS LastCommentDate
    FROM 
        Comments c
    GROUP BY 
        c.PostId
),
PostAggregates AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        COALESCE(pc.CommentCount, 0) AS CommentCount,
        COALESCE(cc.CloseCount, 0) AS CloseCount,
        COALESCE(cc.ReopenCount, 0) AS ReopenCount,
        bu.BadgeCount,
        bu.HighestBadgeClass
    FROM 
        RankedPosts rp
    LEFT JOIN 
        PostComments pc ON rp.PostId = pc.PostId
    LEFT JOIN 
        ClosedPostCounts cc ON rp.PostId = cc.PostId
    LEFT JOIN 
        BadgedUsers bu ON rp.PostId IN (SELECT p.Id FROM Posts p WHERE p.OwnerUserId = bu.UserId)
    WHERE 
        rp.rn <= 3  
)
SELECT 
    pa.PostId,
    pa.Title,
    pa.CreationDate,
    pa.CommentCount,
    pa.CloseCount,
    pa.ReopenCount,
    pa.BadgeCount,
    pa.HighestBadgeClass,
    CASE 
        WHEN pa.CloseCount = 0 AND pa.ReopenCount > 0 THEN 'Reopened'
        WHEN pa.CloseCount > 0 THEN 'Closed'
        ELSE 'Active'
    END AS PostStatus,
    ARRAY_AGG(DISTINCT t.TagName) AS Tags
FROM 
    PostAggregates pa 
LEFT JOIN 
    (SELECT 
         unnest(string_to_array(p.Tags, '><')) AS TagName,
         p.Id as PostId
     FROM 
         Posts p
    ) t ON pa.PostId = t.PostId
GROUP BY 
    pa.PostId, pa.Title, pa.CreationDate, pa.CommentCount, pa.CloseCount, pa.ReopenCount, pa.BadgeCount, pa.HighestBadgeClass
ORDER BY 
    pa.CommentCount DESC
LIMIT 100;
