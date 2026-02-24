WITH UserPostCounts AS (
    SELECT 
        u.Id AS UserId,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id
),
UserBadgeCounts AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
UserVoteCounts AS (
    SELECT 
        v.UserId,
        COUNT(v.Id) AS VoteCount
    FROM 
        Votes v
    GROUP BY 
        v.UserId
)

SELECT 
    u.Id AS UserId,
    u.DisplayName,
    COALESCE(up.PostCount, 0) AS TotalPosts,
    COALESCE(up.QuestionCount, 0) AS TotalQuestions,
    COALESCE(up.AnswerCount, 0) AS TotalAnswers,
    COALESCE(ub.BadgeCount, 0) AS TotalBadges,
    COALESCE(uv.VoteCount, 0) AS TotalVotes,
    u.Reputation,
    u.CreationDate
FROM 
    Users u
LEFT JOIN 
    UserPostCounts up ON u.Id = up.UserId
LEFT JOIN 
    UserBadgeCounts ub ON u.Id = ub.UserId
LEFT JOIN 
    UserVoteCounts uv ON u.Id = uv.UserId
ORDER BY 
    u.Reputation DESC;
