
WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        COUNT(B.Id) AS BadgeCount,
        SUM(COALESCE(V.BountyAmount, 0)) AS TotalBounty,
        AVG(EXTRACT(EPOCH FROM (TIMESTAMP '2024-10-01 12:34:56' - U.CreationDate)) ) AS AvgAccountAgeInSeconds
    FROM Users U
    LEFT JOIN Badges B ON U.Id = B.UserId
    LEFT JOIN Votes V ON U.Id = V.UserId
    GROUP BY U.Id, U.Reputation
),
PostAnalysis AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        P.Score,
        P.AcceptedAnswerId,
        COUNT(C.Id) AS CommentCount,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpvoteCount,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownvoteCount,
        COUNT(DISTINCT PL.RelatedPostId) AS RelatedPostCount,
        CASE 
            WHEN P.ClosedDate IS NOT NULL THEN 'Closed'
            ELSE 'Open'
        END AS PostStatus
    FROM Posts P
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN Votes V ON P.Id = V.PostId
    LEFT JOIN PostLinks PL ON P.Id = PL.PostId
    GROUP BY P.Id, P.Title, P.CreationDate, P.ViewCount, P.Score, P.AcceptedAnswerId, P.ClosedDate
),
UserRanked AS (
    SELECT 
        U.UserId,
        U.Reputation,
        U.BadgeCount,
        U.TotalBounty,
        U.AvgAccountAgeInSeconds,
        RANK() OVER (ORDER BY U.Reputation DESC) AS ReputationRank
    FROM UserStats U
),
PostRanked AS (
    SELECT 
        PA.PostId,
        PA.Title,
        PA.CreationDate,
        PA.ViewCount,
        PA.Score,
        PA.CommentCount,
        PA.UpvoteCount,
        PA.DownvoteCount,
        PA.RelatedPostCount,
        PA.PostStatus,
        RANK() OVER (ORDER BY PA.Score DESC, PA.ViewCount DESC) AS PostRank
    FROM PostAnalysis PA
)
SELECT 
    UR.UserId,
    UR.Reputation,
    COALESCE(PR.Title, 'No Posts') AS TopPostTitle,
    PR.Score AS PostScore,
    UR.BadgeCount,
    UR.TotalBounty,
    UR.AvgAccountAgeInSeconds,
    PR.PostStatus,
    UR.ReputationRank,
    PR.PostRank
FROM UserRanked UR
LEFT JOIN PostRanked PR ON UR.UserId = (
    SELECT P.OwnerUserId 
    FROM Posts P 
    WHERE P.OwnerUserId IS NOT NULL 
    ORDER BY P.Score DESC 
    LIMIT 1
)
WHERE UR.Reputation > 1000
ORDER BY UR.ReputationRank, PR.PostRank;
