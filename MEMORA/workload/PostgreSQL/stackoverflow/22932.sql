
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.CreationDate, 
        p.Score, 
        p.ViewCount, 
        p.OwnerUserId,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS PostRank,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.OwnerUserId
),
ActiveUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostsCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        u.LastAccessDate > TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days' 
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
HighReputationBadges AS (
    SELECT 
        b.UserId,
        COUNT(*) AS HighBadgeCount
    FROM 
        Badges b
    WHERE 
        b.Class = 1  
    GROUP BY 
        b.UserId
    HAVING 
        COUNT(*) > 1  
),
FinalResults AS (
    SELECT 
        au.UserId,
        au.DisplayName,
        au.Reputation,
        hp.PostId,
        hp.Title,
        hp.CreationDate,
        hp.Score,
        hp.ViewCount,
        hp.CommentCount,
        COALESCE(hrb.HighBadgeCount, 0) AS GoldBadgeCount,
        CASE 
            WHEN hp.PostRank <= 5 THEN 'Top 5'
            ELSE 'Not Top 5'
        END AS RankCategory
    FROM 
        ActiveUsers au
    JOIN 
        RankedPosts hp ON au.UserId = hp.OwnerUserId
    LEFT JOIN 
        HighReputationBadges hrb ON au.UserId = hrb.UserId
)
SELECT DISTINCT 
    fr.UserId,
    fr.DisplayName,
    fr.Reputation,
    fr.PostId,
    fr.Title,
    fr.CreationDate,
    fr.Score,
    fr.ViewCount,
    fr.CommentCount,
    fr.GoldBadgeCount,
    fr.RankCategory,
    CASE 
        WHEN fr.GoldBadgeCount = 0 THEN 'Zero Gold Badges'
        WHEN fr.GoldBadgeCount > 0 THEN CONCAT(fr.GoldBadgeCount, ' Gold Badges')
        ELSE 'No Gold Badges'
    END AS BadgeStatus,
    CASE 
        WHEN fr.CommentCount = 0 THEN 'Zero Comments'
        ELSE CONCAT(fr.CommentCount, ' Comments')
    END AS CommentStatus
FROM 
    FinalResults fr
WHERE 
    fr.Reputation > 100 
ORDER BY 
    fr.Reputation DESC, 
    fr.Score DESC;
