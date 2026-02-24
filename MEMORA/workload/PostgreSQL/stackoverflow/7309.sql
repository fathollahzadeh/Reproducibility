
WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT C.Id) AS TotalComments,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes,
        SUM(CASE WHEN B.Id IS NOT NULL THEN 1 ELSE 0 END) AS TotalBadges
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId AND V.UserId = U.Id
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName
),
PostStatistics AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        COUNT(DISTINCT C.Id) AS CommentCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        P.Id, P.Title, P.CreationDate, P.Score, P.ViewCount
),
TopUsers AS (
    SELECT 
        UA.UserId,
        UA.DisplayName,
        UA.TotalPosts,
        UA.TotalComments,
        UA.TotalUpVotes,
        UA.TotalDownVotes,
        UA.TotalBadges,
        RANK() OVER (ORDER BY UA.TotalPosts DESC) AS PostRank,
        RANK() OVER (ORDER BY UA.TotalUpVotes DESC) AS UpVoteRank
    FROM 
        UserActivity UA
)
SELECT 
    TU.DisplayName,
    TU.TotalPosts,
    TU.TotalComments,
    TU.TotalUpVotes,
    TU.TotalDownVotes,
    TU.TotalBadges,
    PS.Title AS PopularPostTitle,
    PS.CreationDate AS PopularPostDate,
    PS.Score AS PopularPostScore,
    PS.ViewCount AS PopularPostViews,
    PS.CommentCount AS PopularPostComments,
    PS.UpVoteCount AS PopularPostUpVotes,
    PS.DownVoteCount AS PopularPostDownVotes
FROM 
    TopUsers TU
LEFT JOIN 
    PostStatistics PS ON PS.UpVoteCount = (
        SELECT MAX(PS2.UpVoteCount) 
        FROM PostStatistics PS2 
        WHERE PS2.CommentCount > 0
    )
WHERE 
    TU.PostRank <= 10 OR TU.UpVoteRank <= 10
ORDER BY 
    TU.TotalPosts DESC, TU.TotalUpVotes DESC;
