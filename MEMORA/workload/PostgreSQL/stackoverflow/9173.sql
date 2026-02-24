WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS PostsCount,
        SUM(CASE WHEN P.Score > 0 THEN 1 ELSE 0 END) AS PositivePosts,
        SUM(CASE WHEN P.Score < 0 THEN 1 ELSE 0 END) AS NegativePosts,
        SUM(COALESCE(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END, 0)) AS UpVotesCount,
        SUM(COALESCE(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END, 0)) AS DownVotesCount,
        COUNT(CASE WHEN B.Id IS NOT NULL THEN 1 END) AS BadgesCount,
        AVG(U.Reputation) AS AvgReputation,
        MIN(P.CreationDate) AS FirstPostDate,
        MAX(P.LastActivityDate) AS LastActivityDate
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId AND V.UserId = U.Id
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    WHERE 
        U.CreationDate > '2020-01-01'
    GROUP BY 
        U.Id, U.DisplayName
),
AggregatedData AS (
    SELECT 
        UserId,
        DisplayName,
        PostsCount,
        PositivePosts,
        NegativePosts,
        UpVotesCount,
        DownVotesCount,
        BadgesCount,
        AvgReputation,
        DENSE_RANK() OVER (ORDER BY PostsCount DESC) AS PostRank,
        DENSE_RANK() OVER (ORDER BY UpVotesCount DESC) AS UpVotesRank
    FROM 
        UserActivity
),
FinalResults AS (
    SELECT 
        UserId,
        DisplayName,
        PostsCount,
        PositivePosts,
        NegativePosts,
        UpVotesCount,
        DownVotesCount,
        BadgesCount,
        AvgReputation,
        PostRank,
        UpVotesRank
    FROM 
        AggregatedData
    WHERE 
        PostsCount > 10
)
SELECT 
    *
FROM 
    FinalResults
ORDER BY 
    PostRank, UpVotesRank;
