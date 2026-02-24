
WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        u.Reputation > 100
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
PopularPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpvoteCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownvoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year') 
    GROUP BY 
        p.Id, p.Title, p.ViewCount, p.Score
    ORDER BY 
        p.ViewCount DESC 
    LIMIT 10
)
SELECT 
    u.DisplayName,
    u.Reputation,
    us.PostCount,
    us.QuestionCount,
    us.AnswerCount,
    pp.Title AS PopularPostTitle,
    pp.ViewCount AS PopularPostViews,
    pp.Score AS PopularPostScore,
    pp.UpvoteCount AS PopularPostUpvotes,
    pp.DownvoteCount AS PopularPostDownvotes
FROM 
    UserStats us
JOIN 
    Users u ON us.UserId = u.Id
LEFT JOIN 
    PopularPosts pp ON pp.UpvoteCount > 10
ORDER BY 
    u.Reputation DESC
LIMIT 20;
