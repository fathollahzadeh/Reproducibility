WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank,
        COUNT(ans.Id) AS AnswerCount
    FROM
        Posts p
    LEFT JOIN
        Posts ans ON p.Id = ans.ParentId AND ans.PostTypeId = 2
    WHERE
        p.PostTypeId = 1 
        AND p.Score > 0  
    GROUP BY
        p.Id, p.Title, p.Score, p.ViewCount, p.CreationDate, p.OwnerUserId
),
UserReputation AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(b.Id) AS BadgeCount,
        COALESCE(SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END), 0) AS GoldBadges,
        COALESCE(SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END), 0) AS SilverBadges,
        COALESCE(SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END), 0) AS BronzeBadges
    FROM
        Users u
    LEFT JOIN
        Badges b ON u.Id = b.UserId
    GROUP BY
        u.Id, u.DisplayName, u.Reputation
),
PostHistoryCount AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS EditCount
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6) 
    GROUP BY 
        ph.PostId
)
SELECT 
    up.UserId,
    up.DisplayName,
    up.Reputation,
    r.PostId,
    r.Title,
    r.Score,
    r.ViewCount,
    r.CreationDate,
    COALESCE(phc.EditCount, 0) AS TotalEdits,
    up.BadgeCount,
    up.GoldBadges,
    up.SilverBadges,
    up.BronzeBadges
FROM 
    UserReputation up
JOIN 
    RankedPosts r ON up.UserId = r.PostId 
LEFT JOIN 
    PostHistoryCount phc ON r.PostId = phc.PostId
WHERE 
    r.PostRank = 1 
ORDER BY 
    up.Reputation DESC, r.Score DESC
LIMIT 100;