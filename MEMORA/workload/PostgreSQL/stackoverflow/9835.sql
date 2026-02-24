WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN p.ViewCount > 100 THEN 1 ELSE 0 END) AS PopularPostCount
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY u.Id, u.DisplayName, u.Reputation
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        PostCount,
        AnswerCount,
        PopularPostCount,
        ROW_NUMBER() OVER (ORDER BY Reputation DESC) AS Rank
    FROM UserStats
),
RecentEdits AS (
    SELECT 
        ph.UserId,
        ph.PostId,
        ph.CreationDate,
        ph.Comment,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS EditRank
    FROM PostHistory ph
    WHERE ph.PostHistoryTypeId IN (4, 5, 6) 
)
SELECT 
    tu.DisplayName,
    tu.Reputation,
    tu.PostCount,
    tu.AnswerCount,
    tu.PopularPostCount,
    COUNT(re.PostId) AS RecentEditsCount,
    MAX(re.CreationDate) AS LastEditDate
FROM TopUsers tu
LEFT JOIN RecentEdits re ON tu.UserId = re.UserId AND re.EditRank = 1
WHERE tu.Rank <= 10
GROUP BY tu.UserId, tu.DisplayName, tu.Reputation, tu.PostCount, tu.AnswerCount, tu.PopularPostCount
ORDER BY tu.Reputation DESC;