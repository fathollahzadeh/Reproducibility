WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(P.ViewCount) AS TotalViews,
        SUM(P.Score) AS TotalScore
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName
),
BadgeCounts AS (
    SELECT 
        B.UserId,
        COUNT(B.Id) AS TotalBadges
    FROM 
        Badges B
    GROUP BY 
        B.UserId
),
VotingActivity AS (
    SELECT 
        V.UserId,
        COUNT(V.Id) AS TotalVotes,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes V
    GROUP BY 
        V.UserId
)

SELECT 
    UA.UserId,
    UA.DisplayName,
    UA.TotalPosts,
    UA.Questions,
    UA.Answers,
    UA.TotalViews,
    UA.TotalScore,
    COALESCE(BC.TotalBadges, 0) AS TotalBadges,
    COALESCE(VA.TotalVotes, 0) AS TotalVotes,
    COALESCE(VA.UpVotes, 0) AS UpVotes,
    COALESCE(VA.DownVotes, 0) AS DownVotes
FROM 
    UserActivity UA
LEFT JOIN 
    BadgeCounts BC ON UA.UserId = BC.UserId
LEFT JOIN 
    VotingActivity VA ON UA.UserId = VA.UserId
ORDER BY 
    UA.TotalScore DESC, UA.TotalPosts DESC;