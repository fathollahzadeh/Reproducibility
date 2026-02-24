
WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 AND 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
), TopPosts AS (
    SELECT 
        rp.OwnerDisplayName,
        COUNT(*) AS TotalPosts,
        SUM(rp.Score) AS TotalScore,
        AVG(rp.ViewCount) AS AvgViewCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.PostRank <= 5
    GROUP BY 
        rp.OwnerDisplayName
), UsersWithBadges AS (
    SELECT 
        u.Id,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
), FinalResults AS (
    SELECT 
        up.OwnerDisplayName AS DisplayName,
        up.TotalPosts,
        up.TotalScore,
        up.AvgViewCount,
        ub.BadgeCount
    FROM 
        TopPosts up
    JOIN 
        UsersWithBadges ub ON up.OwnerDisplayName = ub.DisplayName
)
SELECT 
    fr.DisplayName,
    fr.TotalPosts,
    fr.TotalScore,
    fr.AvgViewCount,
    fr.BadgeCount,
    CASE 
        WHEN fr.BadgeCount > 0 THEN 'Has Badges' 
        ELSE 'No Badges' 
    END AS BadgeStatus 
FROM 
    FinalResults fr
ORDER BY 
    fr.TotalScore DESC, 
    fr.TotalPosts DESC;
