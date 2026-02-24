
WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName, 
        COUNT(p.Id) AS PostCount, 
        SUM(COALESCE(p.Score, 0)) AS TotalScore, 
        AVG(COALESCE(p.ViewCount, 0)) AS AvgViewCount,
        RANK() OVER (ORDER BY COUNT(p.Id) DESC) AS RankByPosts,
        ROW_NUMBER() OVER (PARTITION BY u.Location ORDER BY COUNT(p.Id) DESC) AS PostRankInLocation
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName, u.Location
), 
PopularTags AS (
    SELECT 
        TRIM(t.TagName) AS Tag, 
        COUNT(pt.Id) AS PostCount
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE CONCAT('%<', t.TagName, '>%')
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    WHERE 
        pt.Name = 'Question'
    GROUP BY 
        TRIM(t.TagName)
    HAVING 
        COUNT(pt.Id) > 5
), 
UserBadges AS (
    SELECT 
        b.UserId, 
        COUNT(b.Id) AS BadgeCount
    FROM 
        Badges b
    GROUP BY 
        b.UserId
)
SELECT 
    ups.UserId, 
    ups.DisplayName, 
    ups.PostCount, 
    ups.TotalScore, 
    ups.AvgViewCount, 
    p.Tag AS PopularTag, 
    ub.BadgeCount,
    CASE 
        WHEN ups.PostCount > 10 THEN 'Prolific'
        ELSE 'Novice'
    END AS UserType
FROM 
    UserPostStats ups
LEFT JOIN 
    PopularTags p ON ups.PostCount > 5
LEFT JOIN 
    UserBadges ub ON ups.UserId = ub.UserId
WHERE 
    (ups.PostCount IS NOT NULL OR p.Tag IS NOT NULL)
ORDER BY 
    ups.TotalScore DESC, 
    ups.PostCount DESC
LIMIT 50;
