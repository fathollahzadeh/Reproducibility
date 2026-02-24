
WITH UserStatistics AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.Views,
        COALESCE(SUM(V.BountyAmount), 0) AS TotalBountySpent,
        COUNT(DISTINCT B.Id) AS BadgeCount,
        COUNT(DISTINCT P.Id) FILTER (WHERE P.AcceptedAnswerId IS NOT NULL) AS AcceptedAnswers,
        ROW_NUMBER() OVER (ORDER BY U.Reputation DESC) AS ReputationRank
    FROM Users U
    LEFT JOIN Votes V ON V.UserId = U.Id AND V.VoteTypeId IN (8, 9) 
    LEFT JOIN Badges B ON B.UserId = U.Id
    LEFT JOIN Posts P ON P.OwnerUserId = U.Id
    GROUP BY U.Id, U.DisplayName, U.Reputation, U.Views
),
HighScoringPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        P.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.Score DESC) AS PostRank
    FROM Posts P
    WHERE P.Score > 10
),
ClosedPostHistory AS (
    SELECT 
        PH.PostId,
        PH.CreationDate,
        PH.UserId,
        PH.Comment,
        RANK() OVER (PARTITION BY PH.PostId ORDER BY PH.CreationDate DESC) AS Rank
    FROM PostHistory PH 
    WHERE PH.PostHistoryTypeId = 10 
    AND PH.Comment IS NOT NULL 
),
PostAccessibility AS (
    SELECT 
        P.Id AS PostId,
        CASE 
            WHEN P.ClosedDate IS NOT NULL THEN 'Closed' 
            WHEN P.AcceptedAnswerId IS NOT NULL THEN 'Answered' 
            ELSE 'Open' 
        END AS PostState,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        COUNT(DISTINCT PL.RelatedPostId) AS RelatedLinks
    FROM Posts P
    LEFT JOIN Comments C ON C.PostId = P.Id
    LEFT JOIN PostLinks PL ON PL.PostId = P.Id
    GROUP BY P.Id
)

SELECT 
    US.UserId,
    US.DisplayName,
    US.Reputation,
    US.BadgeCount,
    US.AcceptedAnswers,
    HP.PostId,
    HP.Title,
    HP.Score,
    AP.PostState,
    CH.CreationDate AS CloseDate,
    CH.Comment AS CloseComment
FROM UserStatistics US
JOIN HighScoringPosts HP ON US.UserId = HP.PostId
LEFT JOIN PostAccessibility AP ON HP.PostId = AP.PostId
LEFT JOIN ClosedPostHistory CH ON HP.PostId = CH.PostId AND CH.Rank = 1
WHERE US.ReputationRank <= 100 
  AND (AP.PostState = 'Open' OR (AP.PostState = 'Closed' AND CH.Comment IS NOT NULL))
ORDER BY US.Reputation DESC, HP.Score DESC;
