WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY EXTRACT(YEAR FROM p.CreationDate) ORDER BY p.ViewCount DESC) AS RankByViews,
        ROW_NUMBER() OVER (PARTITION BY EXTRACT(YEAR FROM p.CreationDate) ORDER BY p.Score DESC) AS RankByScore
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1
        AND p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '5 years'
),
TopRankedPosts AS (
    SELECT
        PostId,
        Title,
        CreationDate,
        ViewCount,
        Score,
        OwnerDisplayName,
        RankByViews,
        RankByScore
    FROM 
        RankedPosts
    WHERE 
        RankByViews <= 10 OR RankByScore <= 10
),
PostBadges AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
TopUsers AS (
    SELECT 
        u.Id,
        u.DisplayName,
        u.Reputation,
        pb.BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        PostBadges pb ON u.Id = pb.UserId
    WHERE 
        EXISTS (SELECT 1 FROM Posts p WHERE p.OwnerUserId = u.Id AND p.PostTypeId = 1)
    ORDER BY 
        u.Reputation DESC
    LIMIT 5
)
SELECT 
    trp.Title,
    trp.CreationDate,
    trp.ViewCount,
    trp.Score,
    trp.OwnerDisplayName,
    tu.DisplayName AS TopUserDisplayName,
    tu.Reputation AS TopUserReputation,
    tu.BadgeCount AS TopUserBadgeCount
FROM 
    TopRankedPosts trp
JOIN 
    TopUsers tu ON trp.OwnerDisplayName = tu.DisplayName
ORDER BY 
    trp.CreationDate DESC;