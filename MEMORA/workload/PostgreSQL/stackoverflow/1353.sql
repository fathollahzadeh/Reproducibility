
WITH UserStats AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName, 
        u.Reputation, 
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        AVG(CASE WHEN p.ViewCount IS NOT NULL THEN p.ViewCount ELSE 0 END) AS AvgViewCount
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY u.Id, u.DisplayName, u.Reputation
),
PopularTags AS (
    SELECT 
        unnest(string_to_array(Tags, '>')) AS TagName,
        COUNT(*) AS TagUsage
    FROM Posts
    WHERE Tags IS NOT NULL
    GROUP BY TagName
    ORDER BY TagUsage DESC
    LIMIT 10
),
PostHistoryStats AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        COUNT(*) AS ActionFrequency
    FROM PostHistory ph
    GROUP BY ph.PostId, ph.PostHistoryTypeId
)
SELECT 
    us.UserId,
    us.DisplayName,
    us.Reputation,
    us.PostCount,
    us.QuestionCount,
    us.AnswerCount,
    us.AvgViewCount,
    COALESCE(pt.TagName, 'No Tags') AS PopularTag,
    COALESCE(pht.ActionFrequency, 0) AS PostActionFrequency
FROM UserStats us
LEFT JOIN PopularTags pt ON us.PostCount > 2
LEFT JOIN PostHistoryStats pht ON us.UserId = pht.PostId
WHERE us.Reputation > (SELECT AVG(Reputation) FROM Users)
ORDER BY us.Reputation DESC
LIMIT 100;
