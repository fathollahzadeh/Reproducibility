
WITH UserPostStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 8 
    GROUP BY 
        u.Id, u.DisplayName
),
UserBadges AS (
    SELECT 
        b.UserId,
        STRING_AGG(b.Name, ', ') AS BadgeNames,
        COUNT(*) AS BadgeCount
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
PopularTags AS (
    SELECT 
        UNNEST(STRING_TO_ARRAY(p.Tags, ',')) AS TagName,
        COUNT(*) AS UsageCount
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        TagName
),
TopTags AS (
    SELECT 
        TagName
    FROM 
        PopularTags
    ORDER BY 
        UsageCount DESC
    LIMIT 5
)

SELECT 
    ups.UserId,
    ups.DisplayName,
    ups.TotalPosts,
    ups.TotalQuestions,
    ups.TotalAnswers,
    ups.TotalBounty,
    COALESCE(ub.BadgeNames, 'No Badges') AS Badges,
    ub.BadgeCount,
    tt.TagName AS MostPopularTag
FROM 
    UserPostStatistics ups
LEFT JOIN 
    UserBadges ub ON ups.UserId = ub.UserId
LEFT JOIN 
    (SELECT TagName FROM TopTags) tt ON TRUE
WHERE 
    ups.TotalQuestions > 0 AND ups.TotalAnswers = 0 
    AND NOT EXISTS (
        SELECT 1
        FROM Posts p
        WHERE p.OwnerUserId = ups.UserId AND p.PostTypeId = 2
    )
ORDER BY 
    ups.TotalBounty DESC, ups.TotalPosts DESC
LIMIT 10;
