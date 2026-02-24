WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.ViewCount IS NOT NULL THEN p.ViewCount ELSE 0 END) AS TotalViews
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY u.Id, u.DisplayName, u.Reputation
),
TopContributors AS (
    SELECT 
        us.UserId,
        us.DisplayName,
        us.Reputation,
        us.PostCount,
        us.AnswerCount,
        us.QuestionCount,
        us.TotalViews,
        RANK() OVER (ORDER BY us.Reputation DESC) AS ReputationRank
    FROM UserStats us
    WHERE us.PostCount > 0
),
TopPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        p.OwnerUserId,
        ROW_NUMBER() OVER (ORDER BY p.Score DESC) AS ScoreRank
    FROM Posts p
    WHERE p.PostTypeId = 1
)
SELECT 
    tc.UserId,
    tc.DisplayName,
    tc.Reputation,
    tc.PostCount,
    tc.AnswerCount,
    tc.QuestionCount,
    tc.TotalViews,
    tp.PostId,
    tp.Title,
    tp.Score,
    tp.ViewCount AS PostViewCount,
    tp.CreationDate AS PostCreationDate
FROM TopContributors tc
JOIN TopPosts tp ON tp.OwnerUserId = tc.UserId
WHERE tc.ReputationRank <= 10
  AND tp.ScoreRank <= 5
ORDER BY tc.Reputation DESC, tp.Score DESC;
