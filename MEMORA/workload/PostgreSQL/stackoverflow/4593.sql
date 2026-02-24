WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionsCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswersCount,
        SUM(CASE WHEN p.PostTypeId IN (10, 12) THEN 1 ELSE 0 END) AS ClosedPostsCount,
        SUM(COALESCE(v.VoteCount, 0)) AS TotalVotes
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(*) AS VoteCount
        FROM Votes
        GROUP BY PostId
    ) v ON p.Id = v.PostId
    GROUP BY u.Id, u.DisplayName, u.Reputation
),

QuestionStats AS (
    SELECT 
        p.Id AS QuestionId,
        p.Title,
        p.LastActivityDate,
        COUNT(DISTINCT c.Id) AS CommentsCount,
        MAX(b.Date) AS LastBadgeDate,
        DENSE_RANK() OVER (ORDER BY p.LastActivityDate DESC) AS ActivityRank
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Badges b ON p.OwnerUserId = b.UserId
    WHERE p.PostTypeId = 1
    GROUP BY p.Id, p.Title, p.LastActivityDate
),

FinalStats AS (
    SELECT 
        us.UserId,
        us.DisplayName,
        us.Reputation,
        us.TotalPosts,
        us.QuestionsCount,
        us.AnswersCount,
        us.ClosedPostsCount,
        us.TotalVotes,
        qs.QuestionId,
        qs.Title,
        qs.LastActivityDate,
        qs.CommentsCount,
        qs.LastBadgeDate,
        qs.ActivityRank
    FROM UserStats us
    LEFT JOIN QuestionStats qs ON us.UserId = qs.QuestionId
)

SELECT 
    fs.DisplayName,
    fs.Reputation,
    fs.TotalPosts,
    fs.QuestionsCount,
    fs.AnswersCount,
    fs.ClosedPostsCount,
    fs.TotalVotes,
    fs.Title AS QuestionTitle,
    fs.LastActivityDate,
    fs.CommentsCount,
    CASE 
        WHEN fs.LastBadgeDate IS NOT NULL THEN 'Yes' 
        ELSE 'No' 
    END AS HasBadge,
    COALESCE(fs.ActivityRank, 999) AS ActivityRank
FROM FinalStats fs
WHERE fs.TotalPosts > 5
ORDER BY fs.Reputation DESC, fs.LastActivityDate DESC
LIMIT 10;
