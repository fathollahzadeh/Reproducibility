
WITH PostStatistics AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        P.ViewCount,
        COALESCE(P.AcceptedAnswerId, -1) AS AcceptedAnswerId,
        COUNT(V.Id) FILTER (WHERE V.VoteTypeId = 2) AS UpVotesCount,
        COUNT(V.Id) FILTER (WHERE V.VoteTypeId = 3) AS DownVotesCount,
        COUNT(C.Id) AS CommentsCount,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS OwnerRecentPostRanking
    FROM 
        Posts P
    LEFT JOIN Votes V ON P.Id = V.PostId
    LEFT JOIN Comments C ON P.Id = C.PostId
    WHERE 
        P.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        P.Id, P.Title, P.Score, P.ViewCount, P.AcceptedAnswerId
),
UserActivePostStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        SUM(CASE WHEN U.LastAccessDate > TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 month' THEN 1 ELSE 0 END) AS RecentLoginCount,
        COUNT(DISTINCT PS.PostId) AS TotalActivePosts,
        SUM(PS.ViewCount) AS TotalViews
    FROM 
        Users U
    LEFT JOIN PostStatistics PS ON U.Id = PS.AcceptedAnswerId OR U.Id = PS.OwnerRecentPostRanking
    GROUP BY 
        U.Id, U.DisplayName
),
TopUsers AS (
    SELECT 
        UserId, 
        DisplayName, 
        TotalActivePosts,
        TotalViews,
        ROW_NUMBER() OVER (ORDER BY TotalActivePosts DESC, TotalViews DESC) AS Ranking
    FROM 
        UserActivePostStats
)
SELECT 
    U.UserId,
    U.DisplayName,
    U.TotalActivePosts,
    U.TotalViews,
    P.PostId,
    P.Title,
    P.Score,
    P.UpVotesCount,
    P.DownVotesCount,
    P.CommentsCount,
    CASE 
        WHEN P.AcceptedAnswerId = -1 THEN 'No Accepted Answer' 
        ELSE 'Has Accepted Answer' 
    END AS AnswerStatus,
    CASE 
        WHEN P.Score > 10 THEN 'High Score'
        WHEN P.Score BETWEEN 5 AND 10 THEN 'Medium Score'
        ELSE 'Low Score' 
    END AS ScoreCategory
FROM 
    TopUsers U
JOIN PostStatistics P ON U.TotalActivePosts > 0
WHERE 
    U.Ranking <= 10
    AND U.TotalViews IS NOT NULL
ORDER BY 
    U.TotalActivePosts DESC, U.TotalViews DESC, P.Score DESC;
