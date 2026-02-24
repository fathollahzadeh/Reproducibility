
WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT C.Id) AS TotalComments,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpvotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownvotes
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Comments C ON U.Id = C.UserId
    LEFT JOIN Votes V ON P.Id = V.PostId
    GROUP BY U.Id, U.DisplayName
),
ActiveUsers AS (
    SELECT 
        UserId,
        DisplayName,
        TotalPosts,
        TotalComments,
        TotalUpvotes,
        TotalDownvotes,
        RANK() OVER (ORDER BY TotalPosts DESC) AS PostRank,
        RANK() OVER (ORDER BY TotalComments DESC) AS CommentRank
    FROM UserActivity
),
ActivePostStats AS (
    SELECT 
        P.Id AS PostId,
        P.Title AS PostTitle,
        P.CreationDate,
        P.Score,
        COALESCE(PV.VoteCount, 0) AS VoteCount,
        COALESCE(PC.CommentCount, 0) AS CommentCount,
        P.Tags,
        P.OwnerUserId
    FROM Posts P
    LEFT JOIN (
        SELECT PostId, COUNT(*) AS VoteCount
        FROM Votes
        GROUP BY PostId
    ) PV ON P.Id = PV.PostId
    LEFT JOIN (
        SELECT PostId, COUNT(*) AS CommentCount
        FROM Comments
        GROUP BY PostId
    ) PC ON P.Id = PC.PostId
    WHERE P.CreationDate >= CURRENT_DATE - INTERVAL '30 days'
)
SELECT 
    AU.DisplayName,
    AU.TotalPosts,
    AU.TotalComments,
    AU.TotalUpvotes,
    AU.TotalDownvotes,
    PPS.PostTitle,
    PPS.CreationDate AS PostDate,
    PPS.Score,
    PPS.VoteCount AS PostVoteCount,
    PPS.CommentCount AS PostCommentCount
FROM ActiveUsers AU
JOIN ActivePostStats PPS ON AU.UserId = PPS.OwnerUserId
WHERE AU.TotalPosts > 0 OR AU.TotalComments > 0
ORDER BY AU.TotalPosts DESC, AU.TotalComments DESC
LIMIT 100;
