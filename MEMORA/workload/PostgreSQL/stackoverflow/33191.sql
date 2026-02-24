
WITH RECURSIVE UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.CreationDate,
        u.LastAccessDate,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        u.Reputation > 0
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation, u.CreationDate, u.LastAccessDate
),
RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.CreationDate > (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '30 days')
),
TagsAggregate AS (
    SELECT 
        t.TagName,
        COUNT(DISTINCT p.Id) AS PostCount
    FROM 
        Tags t
    INNER JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    GROUP BY 
        t.TagName
    HAVING 
        COUNT(DISTINCT p.Id) > 10
)
SELECT 
    ua.DisplayName,
    ua.Reputation,
    ua.PostCount,
    ua.QuestionCount,
    ua.AnswerCount,
    ua.UpVoteCount,
    rp.Title AS RecentPostTitle,
    rp.Score AS RecentPostScore,
    rp.ViewCount AS RecentPostViews,
    ta.TagName AS PopularTag
FROM 
    UserActivity ua
LEFT JOIN 
    RecentPosts rp ON ua.UserId = rp.OwnerUserId AND rp.rn = 1
LEFT JOIN 
    TagsAggregate ta ON ta.PostCount > 5
WHERE 
    ua.PostCount > 5
ORDER BY 
    ua.Reputation DESC, RecentPostScore DESC
LIMIT 50;
