
WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(CASE WHEN v.VoteTypeId IN (2, 3) THEN 1 ELSE 0 END), 0) AS VoteCount,
        COALESCE(SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END), 0) AS QuestionCount,
        COALESCE(SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END), 0) AS AnswerCount,
        COUNT(DISTINCT c.Id) AS CommentCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        u.Reputation > 100
    GROUP BY 
        u.Id, u.DisplayName
),
PostStats AS (
    SELECT 
        p.OwnerUserId AS UserId,
        COUNT(CASE WHEN p.AcceptedAnswerId IS NOT NULL THEN 1 END) AS AcceptedAnswerCount,
        COUNT(p.Id) AS TotalPosts,
        AVG(EXTRACT(EPOCH FROM (TIMESTAMP '2024-10-01 12:34:56' - p.CreationDate)) / 3600) AS AvgPostAgeHours
    FROM 
        Posts p
    GROUP BY 
        p.OwnerUserId
),
FinalStats AS (
    SELECT 
        ua.UserId,
        ua.DisplayName,
        ua.VoteCount,
        ua.QuestionCount,
        ua.AnswerCount,
        ua.CommentCount,
        COALESCE(ps.AcceptedAnswerCount, 0) AS AcceptedAnswerCount,
        COALESCE(ps.TotalPosts, 0) AS TotalPosts,
        COALESCE(ps.AvgPostAgeHours, 0) AS AvgPostAgeHours
    FROM 
        UserActivity ua
    LEFT JOIN 
        PostStats ps ON ua.UserId = ps.UserId
)
SELECT 
    fs.DisplayName,
    fs.VoteCount,
    fs.QuestionCount,
    fs.AnswerCount,
    fs.CommentCount,
    fs.AcceptedAnswerCount,
    fs.TotalPosts,
    fs.AvgPostAgeHours,
    CASE 
        WHEN fs.AvgPostAgeHours > 24 THEN 'Inactive'
        WHEN fs.TotalPosts > 50 THEN 'Active Contributor'
        ELSE 'New Contributor'
    END AS ContributorStatus
FROM 
    FinalStats fs
WHERE 
    fs.QuestionCount > 5
ORDER BY 
    fs.VoteCount DESC, fs.QuestionCount DESC;
