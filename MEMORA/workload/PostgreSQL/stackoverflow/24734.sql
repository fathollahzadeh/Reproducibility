
WITH UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        U.DisplayName,
        U.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY CASE 
            WHEN U.Reputation >= 1000 THEN 'High' 
            WHEN U.Reputation >= 100 THEN 'Medium' 
            ELSE 'Low' END 
            ORDER BY U.Reputation DESC) AS ReputationRank
    FROM Users U
),
PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        SUM(COALESCE(VB.BountyAmount, 0)) AS TotalBounty,
        COUNT(DISTINCT PL.RelatedPostId) AS RelatedPostCount
    FROM Posts P
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN Votes VB ON P.Id = VB.PostId AND VB.VoteTypeId IN (8, 9)
    LEFT JOIN PostLinks PL ON P.Id = PL.PostId
    WHERE P.CreationDate >= '2020-01-01'
    GROUP BY P.Id, P.Title
),
HighActivityUsers AS (
    SELECT 
        U.Id,
        U.DisplayName,
        U.Reputation,
        RANK() OVER (ORDER BY U.Views DESC) AS ActivityRank
    FROM Users U
    WHERE U.Views > 1000
),
UserPosts AS (
    SELECT 
        U.Id AS UserId,
        COUNT(P.Id) AS PostCount,
        SUM(COALESCE(C.CommentCount, 0)) AS TotalComments
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN (SELECT 
                    PostId, 
                    COUNT(*) AS CommentCount 
                FROM Comments 
                GROUP BY PostId) C ON P.Id = C.PostId
    GROUP BY U.Id
),
UserPostAnalytics AS (
    SELECT 
        U.DisplayName,
        UR.Reputation,
        UR.ReputationRank,
        UP.PostCount,
        UP.TotalComments,
        PS.CommentCount AS PostCommentCount,
        PS.RelatedPostCount,
        PS.TotalBounty
    FROM HighActivityUsers U 
    JOIN UserReputation UR ON UR.UserId = U.Id
    JOIN UserPosts UP ON UP.UserId = U.Id
    JOIN PostStats PS ON PS.PostId = (SELECT P.Id FROM Posts P WHERE P.OwnerUserId = U.Id ORDER BY P.CreationDate DESC LIMIT 1)
)

SELECT 
    UPA.DisplayName,
    UPA.Reputation,
    UPA.ReputationRank,
    UPA.PostCount,
    UPA.TotalComments,
    COALESCE(UPA.PostCommentCount, 0) AS AveragePostComments,
    COALESCE(UPA.RelatedPostCount, 0) AS RelatedPostLinks,
    COALESCE(UPA.TotalBounty, 0) AS TotalBounty
FROM UserPostAnalytics UPA
WHERE UPA.ReputationRank = 1 
ORDER BY UPA.TotalComments DESC, UPA.PostCount DESC;
