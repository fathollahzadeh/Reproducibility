
WITH UserActivity AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionsAsked,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswersGiven,
        SUM(CASE WHEN v.VoteTypeId IN (2, 3) THEN 1 ELSE 0 END) AS VotesReceived,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositiveScoredPosts
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE u.Reputation IS NOT NULL
    GROUP BY u.Id, u.DisplayName, u.Reputation
),
HighReputationUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        TotalPosts,
        QuestionsAsked,
        AnswersGiven,
        VotesReceived,
        PositiveScoredPosts,
        RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM UserActivity
    WHERE Reputation > 1000
),
ClosedVsOpenedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        MAX(CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.CreationDate END) AS ClosedDate,
        MAX(CASE WHEN ph.PostHistoryTypeId = 11 THEN ph.CreationDate END) AS ReopenedDate,
        (MAX(CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.CreationDate END) IS NOT NULL) AS IsClosed,
        (MAX(CASE WHEN ph.PostHistoryTypeId = 11 THEN ph.CreationDate END) IS NOT NULL) AS IsReopened
    FROM Posts p
    LEFT JOIN PostHistory ph ON p.Id = ph.PostId
    GROUP BY p.Id, p.Title
)
SELECT 
    u.DisplayName,
    u.Reputation,
    u.TotalPosts,
    COALESCE(cvp.IsClosed, false) AS IsClosed,
    COALESCE(cvp.IsReopened, false) AS IsReopened,
    cvp.ClosedDate,
    cvp.ReopenedDate,
    AVG(u.TotalPosts) OVER() AS AvgPostsCreated, -- Using TotalPosts for average
    STRING_AGG(DISTINCT pt.Name, ', ') AS PostTypeNames
FROM HighReputationUsers u
LEFT JOIN ClosedVsOpenedPosts cvp ON u.UserId = cvp.PostId
LEFT JOIN PostTypes pt ON pt.Id = (SELECT PostTypeId FROM Posts WHERE OwnerUserId = u.UserId LIMIT 1)
WHERE u.TotalPosts > 5
GROUP BY u.DisplayName, u.Reputation, u.TotalPosts, cvp.IsClosed, cvp.IsReopened, cvp.ClosedDate, cvp.ReopenedDate
ORDER BY u.Reputation DESC
LIMIT 10;
