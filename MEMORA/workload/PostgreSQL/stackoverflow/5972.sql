WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(c.Score) AS CommentScore
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        u.Id, u.Reputation
), BadgeCounts AS (
    SELECT 
        UserId,
        COUNT(*) AS BadgeCount
    FROM 
        Badges
    GROUP BY 
        UserId
), TagUsage AS (
    SELECT 
        t.Id AS TagId,
        t.TagName,
        COUNT(p.Id) AS PostCount
    FROM 
        Tags t
    LEFT JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    GROUP BY 
        t.Id, t.TagName
), PopularTags AS (
    SELECT 
        TagId,
        TagName,
        PostCount,
        RANK() OVER (ORDER BY PostCount DESC) AS TagRank
    FROM 
        TagUsage
)
SELECT 
    us.UserId,
    us.Reputation,
    us.PostCount,
    us.QuestionCount,
    us.AnswerCount,
    us.CommentScore,
    COALESCE(bc.BadgeCount, 0) AS BadgeCount,
    pt.TagId,
    pt.TagName,
    pt.PostCount AS TagPostCount
FROM 
    UserStats us
LEFT JOIN 
    BadgeCounts bc ON us.UserId = bc.UserId
LEFT JOIN 
    PopularTags pt ON us.PostCount > 0 AND pt.TagRank <= 5
WHERE 
    us.Reputation > 1000
ORDER BY 
    us.Reputation DESC, us.PostCount DESC;
