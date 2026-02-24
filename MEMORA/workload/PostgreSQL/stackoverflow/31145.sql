
WITH RECURSIVE UserReputationChanges AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        PH.CreationDate,
        PH.PostHistoryTypeId,
        ROW_NUMBER() OVER (PARTITION BY U.Id ORDER BY PH.CreationDate DESC) AS RowNum
    FROM Users U
    JOIN PostHistory PH ON U.Id = PH.UserId
    WHERE PH.PostHistoryTypeId IN (10, 11, 12, 13)  
),
AggregatedReputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        SUM(CASE 
            WHEN PH.PostHistoryTypeId = 10 THEN -U.Reputation * 0.1  
            WHEN PH.PostHistoryTypeId = 11 THEN U.Reputation * 0.15 
            ELSE 0
        END) AS TotalReputationChange
    FROM Users U
    JOIN PostHistory PH ON U.Id = PH.UserId
    WHERE PH.PostHistoryTypeId IN (10, 11)
    GROUP BY U.Id, U.DisplayName
    HAVING SUM(CASE 
        WHEN PH.PostHistoryTypeId = 10 THEN -1
        WHEN PH.PostHistoryTypeId = 11 THEN 1
        ELSE 0
    END) > 0  
),
UserBadges AS (
    SELECT 
        U.Id AS UserId,
        COUNT(B.Id) AS BadgeCount,
        SUM(CASE 
            WHEN B.Class = 1 THEN 1  
            WHEN B.Class = 2 THEN 2  
            WHEN B.Class = 3 THEN 1  
            ELSE 0
        END) AS BadgeScore  
    FROM Users U
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id
),
UserActivity AS (
    SELECT
        U.Id AS UserId,
        COUNT(P.Id) AS PostCount,
        COALESCE(SUM(V.BountyAmount), 0) AS TotalBounties
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Votes V ON P.Id = V.PostId
    GROUP BY U.Id
),
FinalResults AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COALESCE(URC.TotalReputationChange, 0) + COALESCE(UB.BadgeScore, 0) AS FinalScore,
        UA.PostCount,
        UA.TotalBounties
    FROM Users U
    LEFT JOIN AggregatedReputation URC ON U.Id = URC.UserId
    LEFT JOIN UserBadges UB ON U.Id = UB.UserId
    LEFT JOIN UserActivity UA ON U.Id = UA.UserId
)

SELECT 
    UserId,
    DisplayName,
    FinalScore,
    PostCount,
    TotalBounties
FROM FinalResults
WHERE FinalScore > 0
ORDER BY FinalScore DESC, TotalBounties DESC
LIMIT 10;
