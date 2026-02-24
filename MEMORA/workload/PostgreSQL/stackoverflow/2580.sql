
WITH RankedUsers AS (
    SELECT 
        U.Id,
        U.DisplayName,
        U.Reputation,
        U.CreationDate,
        RANK() OVER (ORDER BY U.Reputation DESC) AS ReputationRank
    FROM 
        Users U
    WHERE 
        U.Reputation IS NOT NULL
),
PostDetails AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate AS PostCreationDate,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentsCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotesCount,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotesCount,
        COUNT(DISTINCT L.RelatedPostId) AS RelatedPostsCount
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    LEFT JOIN 
        PostLinks L ON P.Id = L.PostId
    GROUP BY 
        P.Id, P.Title, P.CreationDate
),
UserPostStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS PostsCount,
        SUM(P.ViewCount) AS TotalViews,
        SUM(P.AnswerCount) AS TotalAnswers,
        SUM(P.FavoriteCount) AS TotalFavorites
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName
)
SELECT 
    R.DisplayName AS UserName,
    R.Reputation,
    COALESCE(PD.CommentsCount, 0) AS TotalComments,
    COALESCE(PD.UpVotesCount, 0) AS TotalUpVotes,
    COALESCE(PD.DownVotesCount, 0) AS TotalDownVotes,
    COALESCE(UPS.PostsCount, 0) AS TotalPosts,
    COALESCE(UPS.TotalViews, 0) AS TotalViews,
    COALESCE(UPS.TotalAnswers, 0) AS TotalAnswers,
    COALESCE(UPS.TotalFavorites, 0) AS TotalFavorites,
    R.ReputationRank
FROM 
    RankedUsers R
LEFT JOIN 
    UserPostStats UPS ON R.Id = UPS.UserId
LEFT JOIN 
    PostDetails PD ON PD.PostId = (SELECT P.Id FROM Posts P WHERE P.OwnerUserId = R.Id ORDER BY P.CreationDate DESC LIMIT 1)
WHERE 
    R.Reputation > 1000
ORDER BY 
    R.ReputationRank, R.DisplayName;
