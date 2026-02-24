
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS RankByScore
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 
        AND p.Score IS NOT NULL 
        AND p.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 YEAR'
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
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
PostMetrics AS (
    SELECT 
        rp.PostId,
        rp.Title,
        u.DisplayName AS OwnerName,
        rp.Score,
        ur.Reputation,
        ur.GoldBadges,
        ur.SilverBadges,
        ur.BronzeBadges,
        COALESCE(phRecent.RecentEdits, 0) AS RecentEdits,
        COALESCE(phClosed.ClosedPosts, 0) AS ClosedPosts,
        rp.RankByScore
    FROM 
        RankedPosts rp
    JOIN 
        Users u ON rp.OwnerUserId = u.Id
    JOIN 
        UserReputation ur ON u.Id = ur.UserId
    LEFT JOIN (
        SELECT 
            p.OwnerUserId, COUNT(*) AS RecentEdits
        FROM 
            PostHistory ph
        JOIN 
            Posts p ON ph.PostId = p.Id
        WHERE 
            ph.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '30 DAYS'
            AND ph.PostHistoryTypeId IN (4, 5, 6) 
        GROUP BY 
            p.OwnerUserId
    ) phRecent ON u.Id = phRecent.OwnerUserId
    LEFT JOIN (
        SELECT 
            p.OwnerUserId, COUNT(*) AS ClosedPosts
        FROM 
            PostHistory ph
        JOIN 
            Posts p ON ph.PostId = p.Id
        WHERE 
            ph.PostHistoryTypeId IN (10, 11) 
        GROUP BY 
            p.OwnerUserId
    ) phClosed ON u.Id = phClosed.OwnerUserId
)
SELECT 
    pm.PostId,
    pm.Title,
    pm.OwnerName,
    pm.Score,
    pm.Reputation,
    pm.GoldBadges,
    pm.SilverBadges,
    pm.BronzeBadges,
    pm.RecentEdits,
    pm.ClosedPosts,
    CASE 
        WHEN pm.Score > 100 THEN 'High Score'
        WHEN pm.Score BETWEEN 50 AND 100 THEN 'Medium Score'
        ELSE 'Low Score'
    END AS ScoreCategory,
    CASE 
        WHEN pm.Reputation > 1000 THEN 'Influencer'
        ELSE 'Contributor'
    END AS UserCategory
FROM 
    PostMetrics pm
WHERE 
    pm.RankByScore <= 5
ORDER BY 
    pm.Score DESC, 
    pm.Reputation DESC;
