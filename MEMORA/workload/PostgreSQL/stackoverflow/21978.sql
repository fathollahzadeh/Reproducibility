WITH UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(COALESCE(CASE WHEN P.PostTypeId = 2 THEN V.BountyAmount ELSE 0 END, 0)) AS TotalBountyReward,
        AVG(COALESCE(P.Score, 0)) AS AverageScore
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId 
    LEFT JOIN Votes V ON P.Id = V.PostId AND V.VoteTypeId IN (9, 10) 
    WHERE U.Reputation > 0
    GROUP BY U.Id, U.Reputation
),
Bounties AS (
    SELECT 
        UserId,
        SUM(BountyAmount) AS UsedBounty
    FROM Votes
    WHERE VoteTypeId = 9 
    GROUP BY UserId
),
UserBadges AS (
    SELECT 
        U.Id AS UserId,
        ARRAY_AGG(DISTINCT B.Name) AS BadgeNames
    FROM Users U
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id
),
UserRanking AS (
    SELECT 
        UR.UserId,
        UR.Reputation,
        UR.PostCount,
        (COALESCE(B.UsedBounty, 0) * 1.1) AS AdjustedBounty, 
        UR.AverageScore,
        UB.BadgeNames
    FROM UserReputation UR
    LEFT JOIN Bounties B ON UR.UserId = B.UserId
    LEFT JOIN UserBadges UB ON UR.UserId = UB.UserId
),
RankedUsers AS (
    SELECT 
        UserId,
        Reputation,
        PostCount,
        AdjustedBounty,
        AverageScore,
        BadgeNames,
        RANK() OVER (ORDER BY (Reputation + AdjustedBounty + AverageScore) DESC) AS UserRank
    FROM UserRanking
)

SELECT 
    R.UserId,
    R.UserRank,
    R.Reputation,
    R.PostCount,
    R.AdjustedBounty,
    R.AverageScore,
    COALESCE(R.BadgeNames[1], 'No Badges') AS FirstBadge,
    COALESCE(R.BadgeNames[2], 'No Badges') AS SecondBadge
FROM RankedUsers R
WHERE R.Reputation IS NOT NULL
AND R.PostCount > 0
ORDER BY R.UserRank
LIMIT 10;