WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        U.CreationDate,
        U.LastAccessDate,
        U.Views,
        U.UpVotes,
        U.DownVotes,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT CASE WHEN P.PostTypeId = 1 THEN P.Id END) AS TotalQuestions,
        COUNT(DISTINCT CASE WHEN P.PostTypeId = 2 THEN P.Id END) AS TotalAnswers,
        SUM(COALESCE(P.Score, 0)) AS TotalScore
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.Reputation, U.CreationDate, U.LastAccessDate, U.Views, U.UpVotes, U.DownVotes
),
PostTypesStats AS (
    SELECT 
        PT.Id AS PostTypeId,
        PT.Name AS PostTypeName,
        COUNT(P.Id) AS PostCount,
        AVG(P.Score) AS AvgScore,
        SUM(P.ViewCount) AS TotalViews
    FROM 
        PostTypes PT
    LEFT JOIN 
        Posts P ON PT.Id = P.PostTypeId
    GROUP BY 
        PT.Id, PT.Name
),
TotalBadges AS (
    SELECT 
        U.Id AS UserId,
        COUNT(B.Id) AS BadgeCount
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id
)

SELECT 
    US.UserId,
    US.Reputation,
    US.CreationDate,
    US.LastAccessDate,
    US.Views,
    US.UpVotes,
    US.DownVotes,
    US.TotalPosts,
    US.TotalQuestions,
    US.TotalAnswers,
    US.TotalScore,
    TB.BadgeCount,
    PTS.PostTypeId,
    PTS.PostTypeName,
    PTS.PostCount,
    PTS.AvgScore,
    PTS.TotalViews
FROM 
    UserStats US
JOIN 
    TotalBadges TB ON US.UserId = TB.UserId
JOIN 
    PostTypesStats PTS ON US.TotalPosts > 0 
ORDER BY 
    US.TotalScore DESC;