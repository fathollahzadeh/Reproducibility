
WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN p.PostTypeId = 3 THEN 1 ELSE 0 END) AS WikiCount,
        MAX(u.CreationDate) AS AccountAge,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
PopularTags AS (
    SELECT 
        t.TagName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(p.ViewCount) AS TotalViews
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE CONCAT('%<', t.TagName, '>%')
    WHERE 
        p.CreationDate >= (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year')
    GROUP BY 
        t.TagName
    ORDER BY 
        PostCount DESC
    LIMIT 5
),
ActiveUsers AS (
    SELECT 
        u.Id,
        u.DisplayName,
        COUNT(c.Id) AS CommentCount
    FROM 
        Users u
    JOIN 
        Comments c ON u.Id = c.UserId
    WHERE 
        c.CreationDate >= (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '6 months')
    GROUP BY 
        u.Id, u.DisplayName
    ORDER BY 
        CommentCount DESC
    LIMIT 10
)
SELECT 
    us.UserId,
    us.DisplayName,
    us.Reputation,
    us.PostCount,
    us.QuestionCount,
    us.AnswerCount,
    us.WikiCount,
    us.AccountAge,
    us.GoldBadges,
    us.SilverBadges,
    us.BronzeBadges,
    pt.TagName,
    pt.PostCount AS TagPostCount,
    pt.TotalViews AS TagTotalViews,
    au.CommentCount
FROM 
    UserStats us
CROSS JOIN 
    PopularTags pt
JOIN 
    ActiveUsers au ON us.UserId = au.Id
ORDER BY 
    us.Reputation DESC, pt.TotalViews DESC;
