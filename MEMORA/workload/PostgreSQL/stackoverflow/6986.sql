WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.CreationDate,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(v.BountyAmount) AS TotalBounty
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE u.Reputation > 100
    GROUP BY u.Id, u.DisplayName, u.Reputation, u.CreationDate
),
RankedUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        PostCount,
        QuestionCount,
        AnswerCount,
        TotalBounty,
        RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank,
        RANK() OVER (ORDER BY PostCount DESC) AS PostCountRank
    FROM UserStats
)
SELECT 
    R.UserId,
    R.DisplayName,
    R.Reputation,
    R.PostCount,
    R.QuestionCount,
    R.AnswerCount,
    R.TotalBounty,
    PH.KeyChanges,
    PH.EditHistoryCount,
    PH.ClosedPosts
FROM RankedUsers R
LEFT JOIN (
    SELECT 
        p.OwnerUserId,
        COUNT(DISTINCT ph.Id) AS EditHistoryCount,
        COUNT(DISTINCT CASE WHEN p.ClosedDate IS NOT NULL THEN p.Id END) AS ClosedPosts,
        STRING_AGG(DISTINCT CONCAT('Changed ', p.Title, ' at ', ph.CreationDate), '; ') AS KeyChanges
    FROM Posts p
    JOIN PostHistory ph ON p.Id = ph.PostId
    GROUP BY p.OwnerUserId
) PH ON R.UserId = PH.OwnerUserId
WHERE R.ReputationRank <= 10 OR R.PostCountRank <= 10
ORDER BY R.Reputation DESC, R.PostCount DESC;
