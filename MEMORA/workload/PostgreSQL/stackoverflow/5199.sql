WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(UpVotes) AS TotalUpVotes,
        SUM(DownVotes) AS TotalDownVotes,
        DENSE_RANK() OVER (ORDER BY SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) DESC) AS QuestionRank
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
ActiveTags AS (
    SELECT 
        t.TagName,
        COUNT(DISTINCT p.Id) AS UsageCount
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    GROUP BY 
        t.TagName
    HAVING 
        COUNT(DISTINCT p.Id) > 1
),
TopTags AS (
    SELECT 
        TagName,
        ROW_NUMBER() OVER (ORDER BY UsageCount DESC) AS TagRank
    FROM 
        ActiveTags
),
UserBadgeStats AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
)
SELECT 
    us.UserId,
    us.DisplayName,
    us.TotalPosts,
    us.TotalQuestions,
    us.TotalAnswers,
    us.TotalUpVotes,
    us.TotalDownVotes,
    ut.TagName,
    ub.BadgeCount,
    ut.TagRank,
    us.QuestionRank
FROM 
    UserStats us
LEFT JOIN 
    TopTags ut ON ut.TagRank <= 10
LEFT JOIN 
    UserBadgeStats ub ON us.UserId = ub.UserId
WHERE 
    us.TotalPosts > 5
ORDER BY 
    us.TotalUpVotes DESC, us.TotalPosts DESC;
