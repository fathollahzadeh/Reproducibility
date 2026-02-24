
WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(COALESCE(c.Score, 0)) AS CommentScore,
        SUM(CASE WHEN b.Id IS NOT NULL THEN 1 ELSE 0 END) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
RankedUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        PostCount,
        QuestionCount,
        AnswerCount,
        CommentScore,
        BadgeCount,
        RANK() OVER (ORDER BY Reputation DESC, PostCount DESC) AS ReputationRank
    FROM 
        UserStats
)
SELECT 
    ru.UserId,
    ru.DisplayName,
    ru.Reputation,
    ru.PostCount,
    ru.QuestionCount,
    ru.AnswerCount,
    ru.CommentScore,
    ru.BadgeCount,
    COALESCE(bnt.TagName, 'No Tag') AS MostPopularTag,
    COUNT(DISTINCT pl.RelatedPostId) AS LinkedPosts
FROM 
    RankedUsers ru
LEFT JOIN 
    Posts p ON ru.UserId = p.OwnerUserId
LEFT JOIN 
    PostLinks pl ON p.Id = pl.PostId
LEFT JOIN 
    (SELECT 
         unnest(string_to_array(Tags, ',')) AS TagName,
         COUNT(*) AS TagCount 
     FROM 
         Posts 
     GROUP BY 
         unnest(string_to_array(Tags, ',')) 
     ORDER BY 
         TagCount DESC 
     LIMIT 1) bnt ON true
GROUP BY 
    ru.UserId, ru.DisplayName, ru.Reputation, ru.PostCount, ru.QuestionCount, 
    ru.AnswerCount, ru.CommentScore, ru.BadgeCount, bnt.TagName
ORDER BY 
    ru.Reputation DESC, ru.PostCount DESC
LIMIT 100;
