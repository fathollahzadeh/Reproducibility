
WITH UserReputation AS (
    SELECT 
        Id AS UserId,
        DisplayName,
        Reputation,
        RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM Users
),
TopTags AS (
    SELECT 
        TagName,
        COUNT(*) AS TagCount
    FROM Tags
    GROUP BY TagName
    HAVING COUNT(*) > 5
),
AcceptedAnswers AS (
    SELECT 
        p.OwnerUserId,
        COUNT(*) AS AcceptedAnswersCount
    FROM Posts p
    WHERE p.AcceptedAnswerId IS NOT NULL
    GROUP BY p.OwnerUserId
),
PostsInfo AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        COALESCE(aa.AcceptedAnswersCount, 0) AS AcceptedAnswersCount
    FROM Posts p
    LEFT JOIN Users u ON p.OwnerUserId = u.Id
    LEFT JOIN AcceptedAnswers aa ON u.Id = aa.OwnerUserId
    WHERE p.PostTypeId = 1 
)
SELECT 
    p.Title,
    p.Score,
    p.ViewCount,
    p.CreationDate,
    p.OwnerDisplayName,
    rr.Reputation,
    rr.ReputationRank,
    tt.TagName,
    tt.TagCount,
    p.AcceptedAnswersCount
FROM PostsInfo p
JOIN UserReputation rr ON p.OwnerDisplayName = rr.DisplayName
JOIN TopTags tt ON p.Title LIKE CONCAT('%', tt.TagName, '%')
ORDER BY rr.Reputation DESC, p.Score DESC
LIMIT 50;
