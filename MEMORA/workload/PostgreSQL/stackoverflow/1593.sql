
WITH UserStats AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName, 
        COUNT(DISTINCT p.Id) AS PostCount, 
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount, 
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount, 
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes, 
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes,
        SUM(COALESCE(b.Class, 0)) AS TotalBadges
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
RankedUsers AS (
    SELECT 
        us.*, 
        RANK() OVER (ORDER BY us.Upvotes - us.Downvotes DESC, us.PostCount DESC) AS UserRank
    FROM 
        UserStats us
)
SELECT 
    ru.UserId, 
    ru.DisplayName, 
    ru.PostCount, 
    ru.QuestionCount, 
    ru.AnswerCount, 
    ru.Upvotes, 
    ru.Downvotes, 
    ru.TotalBadges,
    (SELECT STRING_AGG(DISTINCT t.TagName, ', ') 
     FROM Posts p2 
     LEFT JOIN UNNEST(STRING_TO_ARRAY(p2.Tags, ',')) AS tag ON TRUE 
     LEFT JOIN Tags t ON t.TagName = tag 
     WHERE p2.OwnerUserId = ru.UserId) AS PopularTags
FROM 
    RankedUsers ru
WHERE 
    ru.UserRank <= 10
ORDER BY 
    ru.UserRank;
