
WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes,
        SUM(CASE WHEN b.Id IS NOT NULL THEN 1 ELSE 0 END) AS TotalBadges,
        MAX(p.CreationDate) AS LastPostDate
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON p.Id = v.PostId
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id, u.DisplayName
),
ActivityRanks AS (
    SELECT 
        UserId,
        DisplayName,
        TotalPosts,
        TotalQuestions,
        TotalAnswers,
        TotalUpVotes,
        TotalDownVotes,
        TotalBadges,
        LastPostDate,
        RANK() OVER (ORDER BY TotalPosts DESC, TotalUpVotes DESC, TotalBadges DESC) AS UserRank
    FROM UserActivity
)
SELECT 
    ar.UserId,
    ar.DisplayName,
    ar.TotalPosts,
    ar.TotalQuestions,
    ar.TotalAnswers,
    ar.TotalUpVotes,
    ar.TotalDownVotes,
    ar.TotalBadges,
    ar.LastPostDate,
    ar.UserRank
FROM ActivityRanks ar
WHERE ar.UserRank <= 10
ORDER BY ar.UserRank;
