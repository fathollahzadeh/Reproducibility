
WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(COALESCE(P.Score, 0)) AS TotalScore,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        ROW_NUMBER() OVER (ORDER BY SUM(COALESCE(P.Score, 0)) DESC) AS Rank
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        U.Reputation > 1000 
        AND U.CreationDate < TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        U.Id, U.DisplayName
), ClosedPosts AS (
    SELECT 
        PH.PostId,
        PH.CreationDate,
        PH.UserId,
        P.Title,
        COUNT(CASE WHEN PH.PostHistoryTypeId = 10 THEN 1 END) AS CloseCount
    FROM 
        PostHistory PH
    JOIN 
        Posts P ON PH.PostId = P.Id
    WHERE 
        PH.PostHistoryTypeId IN (10, 11)  
    GROUP BY 
        PH.PostId, PH.CreationDate, PH.UserId, P.Title
), AverageVotes AS (
    SELECT 
        PostId,
        AVG(VoteCount) AS AvgVoteCount
    FROM (
        SELECT 
            PostId, 
            COUNT(V.Id) AS VoteCount
        FROM 
            Votes V
        GROUP BY 
            PostId
    ) AS VoteSummary
    GROUP BY 
        PostId
)
SELECT 
    UA.UserId,
    UA.DisplayName,
    UA.PostCount,
    UA.TotalScore,
    COALESCE(CP.CloseCount, 0) AS ClosedPostCount,
    AVG(AV.AvgVoteCount) AS AverageVotes,
    CASE 
        WHEN UA.TotalScore > 100 THEN 'High performer'
        WHEN UA.TotalScore BETWEEN 50 AND 100 THEN 'Medium performer'
        ELSE 'Low performer' 
    END AS PerformanceCategory
FROM 
    UserActivity UA
LEFT JOIN 
    ClosedPosts CP ON UA.UserId = CP.UserId
LEFT JOIN 
    AverageVotes AV ON UA.UserId = AV.PostId
WHERE 
    UA.Rank <= 10
GROUP BY 
    UA.UserId, UA.DisplayName, UA.PostCount, UA.TotalScore, CP.CloseCount
ORDER BY 
    UA.TotalScore DESC;
