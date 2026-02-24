
WITH TagStatistics AS (
    SELECT 
        t.TagName,
        COUNT(DISTINCT p.Id) AS QuestionCount,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(p.AnswerCount, 0)) AS TotalAnswers,
        SUM(COALESCE(p.CommentCount, 0)) AS TotalComments
    FROM 
        Tags t
    LEFT JOIN 
        Posts p ON p.Tags LIKE CONCAT('%', t.TagName, '%')
    WHERE 
        p.PostTypeId = 1  
    GROUP BY 
        t.TagName
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON b.UserId = u.Id
    WHERE 
        u.Reputation > 1000  
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
PostActivity AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount,
        MAX(p.CreationDate) AS LastActivityDate
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    WHERE 
        p.PostTypeId IN (1, 2)  
    GROUP BY 
        p.Id, p.Title
)
SELECT 
    ts.TagName,
    ts.QuestionCount,
    ts.TotalViews,
    ts.TotalAnswers,
    ts.TotalComments,
    ur.DisplayName AS ActiveUser,
    ur.Reputation AS UserReputation,
    ur.BadgeCount AS UserBadges,
    pa.Title AS PopularPostTitle,
    pa.CommentCount AS PopularPostComments,
    pa.VoteCount AS PopularPostVotes,
    pa.LastActivityDate AS PopularPostLastActivity
FROM 
    TagStatistics ts
JOIN 
    UserReputation ur ON ur.Reputation = (SELECT MAX(Reputation) FROM UserReputation)
JOIN 
    PostActivity pa ON pa.CommentCount = (SELECT MAX(CommentCount) FROM PostActivity)
ORDER BY 
    ts.QuestionCount DESC, ts.TotalViews DESC
LIMIT 10;
