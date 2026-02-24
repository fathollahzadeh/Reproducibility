WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        u.DisplayName AS OwnerName,
        p.LastActivityDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(p.Score) AS TotalScore,
        AVG(p.ViewCount) AS AvgViewCount,
        SUM(p.AnswerCount) AS TotalAnswers
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
    HAVING 
        COUNT(p.Id) > 50
),
UserBadges AS (
    SELECT 
        ub.UserId,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Badges ub
    JOIN 
        Badges b ON ub.Id = b.Id
    GROUP BY 
        ub.UserId
)
SELECT 
    ru.DisplayName AS TopUser,
    ru.TotalPosts,
    ru.TotalScore,
    ru.AvgViewCount,
    ru.TotalAnswers,
    ub.BadgeNames,
    rp.Title AS LatestPostTitle,
    rp.CreationDate AS LatestPostDate
FROM 
    TopUsers ru
LEFT JOIN 
    UserBadges ub ON ru.UserId = ub.UserId
LEFT JOIN 
    RankedPosts rp ON ru.UserId = rp.PostId
WHERE 
    rp.PostRank = 1
ORDER BY 
    ru.TotalScore DESC, 
    ru.TotalPosts DESC;
