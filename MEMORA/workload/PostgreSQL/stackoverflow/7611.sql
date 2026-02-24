
WITH UserStats AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName, 
        u.Reputation, 
        COUNT(DISTINCT p.Id) AS TotalPosts, 
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN p.PostTypeId = 2 AND p.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedAnswerCount,
        SUM(CASE WHEN b.UserId IS NOT NULL THEN 1 ELSE 0 END) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
PostEngagement AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.ViewCount, 
        p.Score, 
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '30 days'
    GROUP BY 
        p.Id, p.Title, p.ViewCount, p.Score
),
UserPostEngagement AS (
    SELECT 
        us.DisplayName,
        us.Reputation,
        us.TotalPosts,
        us.QuestionCount,
        us.AnswerCount,
        us.AcceptedAnswerCount,
        pe.PostId,
        pe.Title,
        pe.ViewCount,
        pe.Score,
        pe.CommentCount,
        pe.VoteCount
    FROM 
        UserStats us
    JOIN 
        PostEngagement pe ON us.UserId = pe.PostId
)
SELECT 
    DisplayName AS UserDisplayName,
    Reputation,
    TotalPosts,
    QuestionCount,
    AnswerCount,
    AcceptedAnswerCount,
    Title AS RecentPostTitle,
    ViewCount,
    Score,
    CommentCount,
    VoteCount
FROM 
    UserPostEngagement
ORDER BY 
    Reputation DESC, 
    TotalPosts DESC
LIMIT 10;
