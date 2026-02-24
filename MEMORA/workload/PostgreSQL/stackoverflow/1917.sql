WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(P.Score) AS TotalScore,
        SUM(COALESCE(C.CommentCount, 0)) AS TotalComments,
        SUM(COALESCE(V.VoteCount, 0)) AS TotalVotes
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN (
        SELECT PostId, COUNT(*) AS CommentCount
        FROM Comments
        GROUP BY PostId
    ) C ON P.Id = C.PostId
    LEFT JOIN (
        SELECT PostId, COUNT(*) AS VoteCount
        FROM Votes
        GROUP BY PostId
    ) V ON P.Id = V.PostId
    WHERE U.Reputation > 100
    GROUP BY U.Id, U.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        TotalPosts,
        TotalScore,
        TotalComments,
        TotalVotes,
        RANK() OVER (ORDER BY TotalScore DESC) AS ScoreRank,
        RANK() OVER (ORDER BY TotalPosts DESC) AS PostRank
    FROM UserActivity
),
UserBadges AS (
    SELECT 
        B.UserId,
        STRING_AGG(B.Name, ', ') AS BadgeNames,
        COUNT(B.Id) AS BadgeCount
    FROM Badges B
    GROUP BY B.UserId
)
SELECT 
    TU.DisplayName,
    TU.TotalPosts,
    TU.TotalScore,
    TU.TotalComments,
    TU.TotalVotes,
    COALESCE(UB.BadgeNames, 'No Badges') AS BadgeNames,
    TU.ScoreRank,
    TU.PostRank
FROM TopUsers TU
LEFT JOIN UserBadges UB ON TU.UserId = UB.UserId
WHERE TU.ScoreRank <= 10 OR TU.PostRank <= 10
ORDER BY TU.ScoreRank, TU.PostRank;
