WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        u.DisplayName AS Author,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS RankByScore
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.ViewCount,
        rp.Author
    FROM 
        RankedPosts rp
    WHERE 
        rp.RankByScore <= 5
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
MostActiveUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        COALESCE(ub.BadgeCount, 0) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        UserBadges ub ON u.Id = ub.UserId
    GROUP BY 
        u.Id, u.DisplayName, ub.BadgeCount
    HAVING 
        COUNT(p.Id) > 10
)
SELECT 
    TOPP.Title,
    TOPP.Score,
    TOPP.ViewCount,
    TOPP.Author,
    A.DisplayName AS ActiveUser,
    A.PostCount,
    A.BadgeCount
FROM 
    TopPosts TOPP
JOIN 
    MostActiveUsers A ON TOPP.Author = A.DisplayName
ORDER BY 
    TOPP.Score DESC, A.PostCount DESC;