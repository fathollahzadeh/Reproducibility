
WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        SUM(CASE WHEN p.Id IS NOT NULL THEN 1 ELSE 0 END) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostStats AS (
    SELECT 
        p.OwnerUserId,
        COUNT(*) AS TotalPosts,
        SUM(p.Score) AS TotalScore,
        SUM(p.ViewCount) AS TotalViews,
        AVG(p.CommentCount) AS AvgComments,
        AVG(p.AnswerCount) AS AvgAnswers
    FROM 
        Posts p
    GROUP BY 
        p.OwnerUserId
)
SELECT 
    u.UserId,
    u.DisplayName,
    u.BadgeCount,
    u.UpVotes,
    u.DownVotes,
    p.TotalPosts,
    p.TotalScore,
    p.TotalViews,
    p.AvgComments,
    p.AvgAnswers
FROM 
    UserStats u
LEFT JOIN 
    PostStats p ON u.UserId = p.OwnerUserId
ORDER BY 
    u.UserId;
