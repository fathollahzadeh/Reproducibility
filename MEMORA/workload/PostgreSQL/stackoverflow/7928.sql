WITH UserVoteStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT C.Id) AS TotalComments,
        COUNT(DISTINCT B.Id) AS TotalBadges
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName
),
PostStats AS (
    SELECT 
        P.OwnerUserId,
        P.PostTypeId,
        COUNT(*) AS TotalPostsOfType,
        AVG(P.Score) AS AverageScore,
        SUM(P.ViewCount) AS TotalViews
    FROM 
        Posts P
    GROUP BY 
        P.OwnerUserId, P.PostTypeId
),
CombinedStats AS (
    SELECT 
        U.DisplayName,
        U.TotalUpVotes,
        U.TotalDownVotes,
        COALESCE(S.TotalPostsOfType, 0) AS TotalPostsOfType,
        COALESCE(S.AverageScore, 0) AS AverageScore,
        COALESCE(S.TotalViews, 0) AS TotalViews
    FROM 
        UserVoteStats U
    LEFT JOIN 
        PostStats S ON U.UserId = S.OwnerUserId
)
SELECT 
    C.DisplayName,
    C.TotalUpVotes,
    C.TotalDownVotes,
    C.TotalPostsOfType,
    C.AverageScore,
    C.TotalViews
FROM 
    CombinedStats C
ORDER BY 
    C.TotalUpVotes DESC, C.TotalViews DESC
LIMIT 10;
