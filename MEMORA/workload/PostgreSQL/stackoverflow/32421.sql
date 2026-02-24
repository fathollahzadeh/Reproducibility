
WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.OwnerUserId,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId IN (1, 2) 
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(COALESCE(p.Score, 0)) AS TotalScore
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
    HAVING 
        COUNT(DISTINCT p.Id) > 5 
),
PostHistoryEntry AS (
    SELECT 
        ph.PostId,
        ph.CreationDate AS HistoryDate,
        p.Title,
        p.Body,
        ph.Comment,
        ht.Name AS HistoryType
    FROM 
        PostHistory ph
    JOIN 
        Posts p ON ph.PostId = p.Id
    JOIN 
        PostHistoryTypes ht ON ph.PostHistoryTypeId = ht.Id
    WHERE 
        ph.CreationDate >= CURRENT_DATE - INTERVAL '6 months'
),
UserBadges AS (
    SELECT 
        ub.UserId,
        COUNT(*) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Badges ub
    JOIN 
        Users u ON ub.UserId = u.Id
    JOIN 
        Badges b ON ub.Id = b.Id
    GROUP BY 
        ub.UserId
),
CombinedResults AS (
    SELECT 
        tu.UserId,
        tu.DisplayName,
        tu.TotalPosts,
        tu.TotalScore,
        COALESCE(ub.BadgeCount, 0) AS BadgeCount,
        COALESCE(ub.BadgeNames, 'No Badges') AS BadgeNames,
        COUNT(DISTINCT phe.PostId) AS TotalPostHistoryEntries
    FROM 
        TopUsers tu
    LEFT JOIN 
        UserBadges ub ON tu.UserId = ub.UserId
    LEFT JOIN 
        PostHistoryEntry phe ON phe.PostId IN (SELECT Id FROM RankedPosts WHERE OwnerUserId = tu.UserId)
    GROUP BY 
        tu.UserId, tu.DisplayName, tu.TotalPosts, tu.TotalScore, ub.BadgeCount, ub.BadgeNames
)
SELECT 
    cr.UserId,
    cr.DisplayName,
    cr.TotalPosts,
    cr.TotalScore,
    cr.BadgeCount,
    cr.BadgeNames,
    cr.TotalPostHistoryEntries,
    CASE 
        WHEN cr.TotalScore > 1000 THEN 'High Score'
        WHEN cr.TotalScore BETWEEN 500 AND 1000 THEN 'Moderate Score'
        ELSE 'Low Score' 
    END AS ScoreCategory
FROM 
    CombinedResults cr
WHERE 
    cr.TotalPosts > 10
ORDER BY 
    cr.TotalScore DESC, cr.DisplayName;
