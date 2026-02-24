
WITH UserReputation AS (
    SELECT 
        Id AS UserId, 
        Reputation, 
        CreationDate,
        RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM Users
),
TopUsers AS (
    SELECT 
        UserId,
        Reputation,
        CreationDate,
        ROW_NUMBER() OVER (PARTITION BY ReputationRank / 10 ORDER BY Reputation DESC) AS RankGroup
    FROM UserReputation
    WHERE Reputation > 1000
),
PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.PostTypeId,
        p.OwnerUserId,
        COALESCE(UPD.VoteCount, 0) AS VoteCount,
        COALESCE(ANS.AnswerCount, 0) AS AnswerCount,
        COALESCE(EDT.EditCount, 0) AS EditCount,
        EXTRACT(EPOCH FROM (p.LastActivityDate - p.CreationDate)) AS PostAgeInSeconds,
        CASE 
            WHEN p.Score IS NULL THEN NULL 
            ELSE p.Score + (10 * COALESCE(UPD.VoteCount, 0)) 
        END AS AdjustedScore
    FROM 
        Posts p
    LEFT JOIN (
        SELECT 
            PostId, 
            COUNT(*) AS VoteCount 
        FROM Votes 
        WHERE VoteTypeId = 2 
        GROUP BY PostId
    ) AS UPD ON p.Id = UPD.PostId
    LEFT JOIN (
        SELECT 
            ParentId, 
            COUNT(*) AS AnswerCount 
        FROM Posts 
        WHERE PostTypeId = 2 
        GROUP BY ParentId
    ) AS ANS ON p.Id = ANS.ParentId
    LEFT JOIN (
        SELECT 
            PostId, 
            COUNT(*) AS EditCount 
        FROM PostHistory 
        WHERE PostHistoryTypeId IN (4, 5, 6) 
        GROUP BY PostId
    ) AS EDT ON p.Id = EDT.PostId
    WHERE p.OwnerUserId IS NOT NULL
),
TopPosts AS (
    SELECT 
        pd.PostId,
        pd.PostTypeId,
        pd.OwnerUserId,
        pd.VoteCount,
        pd.AnswerCount,
        pd.EditCount,
        pd.PostAgeInSeconds,
        pd.AdjustedScore,
        ROW_NUMBER() OVER (ORDER BY pd.AdjustedScore DESC) AS PostRank
    FROM PostDetails pd
    WHERE pd.AdjustedScore IS NOT NULL
)
SELECT 
    tu.UserId,
    tu.Reputation AS UserReputation,
    pp.PostId,
    pp.VoteCount,
    pp.AnswerCount,
    pp.EditCount,
    pp.PostAgeInSeconds,
    pp.AdjustedScore,
    pp.PostRank
FROM TopUsers tu
JOIN TopPosts pp ON pp.OwnerUserId = tu.UserId
WHERE pp.PostRank <= 10
GROUP BY 
    tu.UserId,
    tu.Reputation,
    pp.PostId,
    pp.VoteCount,
    pp.AnswerCount,
    pp.EditCount,
    pp.PostAgeInSeconds,
    pp.AdjustedScore,
    pp.PostRank
HAVING COUNT(*) > 2 
AND (MAX(pp.AdjustedScore) - MIN(pp.AdjustedScore) <= 50)
LIMIT 1000;
