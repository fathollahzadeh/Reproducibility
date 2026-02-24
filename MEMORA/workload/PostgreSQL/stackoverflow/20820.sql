
WITH RankedUsers AS (
    SELECT 
        Id,
        DisplayName,
        Reputation,
        CreationDate,
        ROW_NUMBER() OVER (PARTITION BY CASE 
            WHEN Reputation >= 10000 THEN 'High'
            WHEN Reputation >= 1000 THEN 'Medium'
            ELSE 'Low'
        END ORDER BY Reputation DESC) AS Rank
    FROM Users
),
PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate AS PostCreationDate,
        COALESCE(P.AcceptedAnswerId, -1) AS AcceptedAnswerId,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        SUM(V.BountyAmount) AS TotalBounties,
        COUNT(DISTINCT P2.Id) AS RelatedPostCount
    FROM Posts P
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN Votes V ON P.Id = V.PostId AND V.VoteTypeId IN (8, 9) 
    LEFT JOIN PostLinks PL ON P.Id = PL.PostId
    LEFT JOIN Posts P2 ON PL.RelatedPostId = P2.Id
    WHERE P.CreationDate >= '2020-01-01'
    GROUP BY P.Id, P.Title, P.CreationDate, P.AcceptedAnswerId
),
PostHistoryStats AS (
    SELECT 
        PH.PostId,
        STRING_AGG(PHT.Name, ', ' ORDER BY PH.CreationDate) AS HistoryTypes,
        COUNT(*) AS HistoryCount,
        MAX(PH.CreationDate) AS LastHistoryDate
    FROM PostHistory PH
    JOIN PostHistoryTypes PHT ON PH.PostHistoryTypeId = PHT.Id
    GROUP BY PH.PostId
),
FinalStats AS (
    SELECT 
        U.DisplayName,
        U.Reputation,
        P.Title,
        P.CommentCount,
        PH.HistoryCount,
        PH.HistoryTypes,
        U.Rank,
        CASE 
            WHEN P.TotalBounties > 0 THEN 'Has Bounties' 
            ELSE 'No Bounties' 
        END AS BountyStatus,
        EXTRACT(EPOCH FROM (TIMESTAMP '2024-10-01 12:34:56' - P.PostCreationDate)) / 3600 AS AgeInHours
    FROM RankedUsers U
    JOIN PostStats P ON U.Id = P.PostId
    JOIN PostHistoryStats PH ON P.PostId = PH.PostId
)
SELECT 
    DisplayName,
    Reputation,
    Title,
    CommentCount,
    HistoryCount,
    HistoryTypes,
    Rank,
    BountyStatus,
    AgeInHours,
    CASE 
        WHEN AgeInHours < 24 THEN 'New Post'
        WHEN AgeInHours >= 24 AND AgeInHours < 168 THEN 'Recent Post'
        ELSE 'Old Post'
    END AS PostAgeCategory
FROM FinalStats
WHERE Rank <= 10 
ORDER BY Reputation DESC, Title ASC;
