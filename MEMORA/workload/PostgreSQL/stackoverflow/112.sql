
WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        u.DisplayName,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotesCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotesCount,
        COUNT(DISTINCT p.Id) AS PostsCount,
        AVG(COALESCE(EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - p.CreationDate)), 0)) AS AvgPostAgeInSeconds
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE u.Reputation > 0
    GROUP BY u.Id, u.Reputation, u.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        Reputation,
        DisplayName,
        UpVotesCount,
        DownVotesCount,
        PostsCount,
        AvgPostAgeInSeconds,
        RANK() OVER (ORDER BY Reputation DESC) AS Rank
    FROM UserStats
    WHERE PostsCount > 0
)
SELECT 
    t.DisplayName,
    t.Reputation,
    t.UpVotesCount,
    t.DownVotesCount,
    t.PostsCount,
    t.AvgPostAgeInSeconds,
    CASE 
        WHEN t.PostsCount > 50 THEN 'High Activity'
        WHEN t.PostsCount BETWEEN 20 AND 50 THEN 'Moderate Activity'
        ELSE 'Low Activity'
    END AS ActivityLevel,
    COALESCE((
        SELECT STRING_AGG(title, ', ')
        FROM Posts pp
        WHERE pp.OwnerUserId = t.UserId AND pp.PostTypeId = 1
    ), 'No Questions') AS RecentQuestions
FROM TopUsers t
WHERE t.Rank <= 10
ORDER BY t.Reputation DESC;
