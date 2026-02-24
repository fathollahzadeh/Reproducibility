WITH PostStats AS (
    SELECT 
        P.PostTypeId,
        COUNT(P.Id) AS TotalPosts,
        SUM(P.ViewCount) AS TotalViews,
        AVG(P.Score) AS AverageScore,
        SUM(P.AnswerCount) AS TotalAnswers
    FROM 
        Posts P
    GROUP BY 
        P.PostTypeId
),
UserStats AS (
    SELECT 
        U.Id AS UserId,
        COUNT(B.Id) AS TotalBadges,
        SUM(U.Reputation) AS TotalReputation,
        AVG(U.Views) AS AverageViews
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id
),
VoteStats AS (
    SELECT 
        P.Id AS PostId,
        COUNT(V.Id) AS TotalVotes,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts P
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        P.Id
)

SELECT 
    PS.PostTypeId,
    PS.TotalPosts,
    PS.TotalViews,
    PS.AverageScore,
    PS.TotalAnswers,
    US.UserId,
    US.TotalBadges,
    US.TotalReputation,
    US.AverageViews,
    VS.TotalVotes,
    VS.UpVotes,
    VS.DownVotes
FROM 
    PostStats PS
JOIN 
    UserStats US ON US.UserId = (SELECT MIN(Id) FROM Users)  
JOIN 
    VoteStats VS ON VS.PostId = (SELECT MIN(Id) FROM Posts)  
ORDER BY 
    PS.TotalPosts DESC;