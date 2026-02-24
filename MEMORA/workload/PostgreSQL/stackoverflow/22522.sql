
WITH UserReputation AS (
    SELECT 
        Id AS UserId,
        Reputation,
        ROW_NUMBER() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM Users
),

PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.PostTypeId,
        p.AnswerCount,
        p.ViewCount,
        COALESCE(SUM(CASE WHEN vote.VoteTypeId = 2 THEN 1 ELSE 0 END) - SUM(CASE WHEN vote.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS Score, 
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
    FROM Posts p
    LEFT JOIN Votes vote ON p.Id = vote.PostId
    LEFT JOIN LATERAL (
        SELECT unnest(string_to_array(SUBSTRING(p.Tags FROM 2 FOR LENGTH(p.Tags) - 2), '><')) AS TagName
    ) AS t ON TRUE
    GROUP BY p.Id, p.PostTypeId, p.AnswerCount, p.ViewCount
),

TopUsers AS (
    SELECT 
        u.DisplayName,
        u.Id AS UserId,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(COALESCE(ps.Score, 0)) AS TotalScore
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN PostStats ps ON p.Id = ps.PostId
    GROUP BY u.DisplayName, u.Id
),

ClosedPosts AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS CloseCount
    FROM PostHistory ph
    WHERE ph.PostHistoryTypeId = 10
    GROUP BY ph.PostId
),

FinalResults AS (
    SELECT 
        tu.DisplayName,
        tu.UserId,
        tu.PostCount,
        tu.TotalScore,
        COALESCE(cp.CloseCount, 0) AS CloseCount,
        CASE 
            WHEN tu.TotalScore > 100 THEN 'Highly Active'
            WHEN tu.TotalScore BETWEEN 50 AND 100 THEN 'Moderately Active'
            ELSE 'Less Active'
        END AS ActivityLevel
    FROM TopUsers tu
    LEFT JOIN ClosedPosts cp ON tu.UserId = cp.PostId 
)

SELECT 
    fr.DisplayName,
    fr.PostCount,
    fr.TotalScore,
    fr.CloseCount,
    fr.ActivityLevel,
    u.ReputationRank,
    CASE 
        WHEN fr.PostCount > 0 THEN ((fr.TotalScore / NULLIF(fr.PostCount, 0)) * 100) 
        ELSE 0
    END AS ScorePerPost
FROM FinalResults fr
JOIN UserReputation u ON fr.UserId = u.UserId
ORDER BY fr.TotalScore DESC, fr.PostCount DESC, fr.CloseCount ASC;
