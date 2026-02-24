WITH RECURSIVE UserBadges AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
TopPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.OwnerUserId,
        p.Score,
        p.CreationDate,
        ROW_NUMBER() OVER(PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  
      AND 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'  
),
BadgeRankings AS (
    SELECT 
        ub.UserId,
        ub.DisplayName,
        ub.BadgeCount,
        RANK() OVER (ORDER BY ub.BadgeCount DESC) AS BadgeRank
    FROM 
        UserBadges ub
    WHERE 
        ub.BadgeCount > 0
),
PostHistoryAnalysis AS (
    SELECT 
        ph.UserId,
        COUNT(ph.Id) AS EditCount,
        SUM(CASE WHEN ph.PostHistoryTypeId IN (4, 5) THEN 1 ELSE 0 END) AS TitleAndBodyEdits,
        COUNT(DISTINCT ph.PostId) AS UniquePostsEdited
    FROM 
        PostHistory ph
    GROUP BY 
        ph.UserId
)
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    u.Reputation,
    COALESCE(b.BadgeCount, 0) AS BadgeCount,
    COALESCE(badge_rank.BadgeRank, NULL) AS BadgeRank,
    cp.TopPostCount AS TopPostsCount,
    ph.EditCount AS TotalEditCount,
    ph.TitleAndBodyEdits AS TitleAndBodyEdits,
    ph.UniquePostsEdited AS UniquePostsEdited
FROM 
    Users u
LEFT JOIN 
    UserBadges b ON u.Id = b.UserId
LEFT JOIN (
    SELECT 
        OwnerUserId, 
        COUNT(*) AS TopPostCount
    FROM 
        TopPosts
    WHERE 
        rn = 1  
    GROUP BY 
        OwnerUserId
) cp ON u.Id = cp.OwnerUserId
LEFT JOIN 
    BadgeRankings badge_rank ON u.Id = badge_rank.UserId
LEFT JOIN 
    PostHistoryAnalysis ph ON u.Id = ph.UserId
WHERE 
    u.Reputation > 1000  
ORDER BY 
    u.Reputation DESC, 
    COALESCE(badge_rank.BadgeRank, 999) ASC;