WITH UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        RANK() OVER (ORDER BY U.Reputation DESC) AS ReputationRank
    FROM Users U
),
PostStats AS (
    SELECT 
        P.OwnerUserId,
        COUNT(*) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers
    FROM Posts P
    GROUP BY P.OwnerUserId
),
ClosedPostComments AS (
    SELECT 
        C.PostId,
        COUNT(*) AS CommentCount,
        MAX(C.CreationDate) AS LastCommentDate
    FROM Comments C
    JOIN Posts P ON C.PostId = P.Id
    WHERE P.ClosedDate IS NOT NULL
    GROUP BY C.PostId
),
TopUsers AS (
    SELECT 
        UR.UserId,
        UR.DisplayName,
        UR.Reputation,
        PS.TotalPosts,
        PS.Questions,
        PS.Answers,
        COALESCE(CPC.CommentCount, 0) AS ClosedCommentCount,
        COALESCE(CPC.LastCommentDate, '2000-01-01') AS LastCommentDate
    FROM UserReputation UR
    LEFT JOIN PostStats PS ON UR.UserId = PS.OwnerUserId
    LEFT JOIN ClosedPostComments CPC ON PS.TotalPosts > 0  
    WHERE UR.Reputation > 1000
)
SELECT 
    TU.DisplayName,
    TU.Reputation,
    TU.TotalPosts,
    TU.Questions,
    TU.Answers,
    TU.ClosedCommentCount,
    TU.LastCommentDate,
    CASE 
        WHEN TU.ClosedCommentCount > 5 THEN 'Highly Engaged'
        WHEN TU.ClosedCommentCount > 0 THEN 'Moderately Engaged'
        ELSE 'Not Engaged'
    END AS EngagementLevel
FROM TopUsers TU
ORDER BY TU.Reputation DESC
LIMIT 10
OFFSET 5;