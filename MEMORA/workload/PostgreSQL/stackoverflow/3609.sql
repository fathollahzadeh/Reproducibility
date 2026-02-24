WITH UserVoteStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS DownVotes,
        COUNT(*) AS TotalVotes,
        COALESCE(SUM(V.BountyAmount), 0) AS TotalBountyAmount
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    GROUP BY 
        U.Id, U.DisplayName
),
PostStats AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(COALESCE(P.FavoriteCount, 0)) AS FavoritePosts
    FROM 
        Posts P
    GROUP BY 
        P.OwnerUserId
),
CombinedStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COALESCE(P.TotalPosts, 0) AS TotalPosts,
        COALESCE(P.Questions, 0) AS Questions,
        COALESCE(P.Answers, 0) AS Answers,
        COALESCE(UV.UpVotes, 0) AS UpVotes,
        COALESCE(UV.DownVotes, 0) AS DownVotes,
        COALESCE(UV.TotalVotes, 0) AS TotalVotes,
        COALESCE(UV.TotalBountyAmount, 0) AS TotalBountyAmount,
        COALESCE(P.FavoritePosts, 0) AS FavoritePosts
    FROM 
        Users U
    LEFT JOIN 
        PostStats P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        UserVoteStats UV ON U.Id = UV.UserId
)
SELECT 
    C.UserId,
    C.DisplayName,
    C.TotalPosts,
    C.Questions,
    C.Answers,
    C.UpVotes,
    C.DownVotes,
    C.TotalVotes,
    C.TotalBountyAmount,
    C.FavoritePosts,
    CASE 
        WHEN C.UpVotes > C.DownVotes THEN 'Predominantly Positive'
        WHEN C.UpVotes < C.DownVotes THEN 'Predominantly Negative'
        ELSE 'Neutral'
    END AS VoteSentiment,
    CASE 
        WHEN C.TotalPosts > 100 THEN 'Veteran'
        WHEN C.TotalPosts BETWEEN 50 AND 100 THEN 'Experienced'
        ELSE 'Novice'
    END AS UserLevel
FROM 
    CombinedStats C
WHERE 
    C.TotalVotes > 10 AND 
    C.UpVotes / NULLIF(C.TotalVotes, 0) > 0.5
ORDER BY 
    C.TotalBountyAmount DESC, 
    C.UpVotes DESC;
