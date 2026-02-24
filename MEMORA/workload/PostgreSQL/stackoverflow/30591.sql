
WITH RecursivePostHistory AS (
    SELECT 
        ph.Id,
        ph.PostId,
        ph.UserId,
        ph.CreationDate,
        ph.Comment,
        ph.PostHistoryTypeId,
        ROW_NUMBER() OVER (PARTITION BY PostId ORDER BY CreationDate DESC) AS rn
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11, 12)  
), 

UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositivePosts,
        SUM(CASE WHEN p.Score < 0 THEN 1 ELSE 0 END) AS NegativePosts,
        AVG(COALESCE(c.Score, 0)) AS AvgCommentScore,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),

PostMetrics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        COALESCE(ph.CloseCommentsCount, 0) AS CloseCommentsCount,
        COALESCE(ph_reopen.ReopenCommentsCount, 0) AS ReopenCommentsCount,
        COALESCE(l.LinkCount, 0) AS LinkCount
    FROM 
        Posts p
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(*) AS CloseCommentsCount
        FROM 
            RecursivePostHistory
        WHERE 
            PostHistoryTypeId = 10
        GROUP BY 
            PostId
    ) ph ON p.Id = ph.PostId
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(*) AS ReopenCommentsCount
        FROM 
            RecursivePostHistory
        WHERE 
            PostHistoryTypeId = 11
        GROUP BY 
            PostId
    ) ph_reopen ON p.Id = ph_reopen.PostId
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(*) AS LinkCount
        FROM 
            PostLinks
        GROUP BY 
            PostId
    ) l ON p.Id = l.PostId
)

SELECT 
    ua.UserId,
    ua.DisplayName,
    ua.PostCount,
    ua.PositivePosts,
    ua.NegativePosts,
    ua.AvgCommentScore,
    ua.GoldBadges,
    ua.SilverBadges,
    ua.BronzeBadges,
    pm.PostId,
    pm.Title,
    pm.ViewCount,
    pm.CreationDate,
    pm.CloseCommentsCount,
    pm.ReopenCommentsCount,
    pm.LinkCount
FROM 
    UserActivity ua
INNER JOIN 
    PostMetrics pm ON ua.PostCount > 10  
ORDER BY 
    ua.PostCount DESC,
    pm.ViewCount DESC
LIMIT 100 OFFSET 0;
