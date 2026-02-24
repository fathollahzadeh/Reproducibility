
WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.Reputation
),
BadgeCounts AS (
    SELECT 
        UserId,
        COUNT(*) AS BadgeCount
    FROM 
        Badges
    GROUP BY 
        UserId
),
UserPerformance AS (
    SELECT 
        us.UserId,
        us.Reputation,
        us.PostCount,
        us.QuestionCount,
        us.AnswerCount,
        us.UpVotes,
        us.DownVotes,
        COALESCE(bc.BadgeCount, 0) AS BadgeCount
    FROM 
        UserStats us
    LEFT JOIN 
        BadgeCounts bc ON us.UserId = bc.UserId
)
SELECT 
    UserId,
    Reputation,
    PostCount,
    QuestionCount,
    AnswerCount,
    UpVotes,
    DownVotes,
    BadgeCount,
    (PostCount * 1.0 / NULLIF(QuestionCount, 0)) AS AnswerQuestionRatio,
    (UpVotes * 1.0 / NULLIF(PostCount, 0)) AS UpvotePostRatio
FROM 
    UserPerformance
ORDER BY 
    Reputation DESC;
