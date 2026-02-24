WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        U.DisplayName AS OwnerDisplayName,
        P.Score,
        (SELECT COUNT(*) FROM Comments C WHERE C.PostId = P.Id) AS CommentCount,
        (SELECT COUNT(*) FROM Votes V WHERE V.PostId = P.Id AND V.VoteTypeId = 2) AS UpVoteCount,
        ROW_NUMBER() OVER (PARTITION BY P.PostTypeId ORDER BY P.Score DESC) AS PostRank
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.CreationDate >= cast('2024-10-01' as date) - INTERVAL '30 days' 
        AND P.Score > 0
),
PostStatistics AS (
    SELECT 
        PT.Name AS PostType,
        COUNT(RP.PostId) AS TotalPosts,
        AVG(RP.Score) AS AverageScore,
        SUM(RP.CommentCount) AS TotalComments,
        SUM(RP.UpVoteCount) AS TotalUpVotes
    FROM 
        RankedPosts RP
    JOIN 
        PostTypes PT ON RP.PostRank <= 10 AND RP.PostId IN (SELECT P.Id FROM Posts P WHERE P.PostTypeId = PT.Id)
    GROUP BY 
        PT.Name
)
SELECT 
    PS.PostType,
    PS.TotalPosts,
    PS.AverageScore,
    PS.TotalComments,
    PS.TotalUpVotes,
    H.Name AS PostHistoryType
FROM 
    PostStatistics PS
JOIN 
    PostHistoryTypes H ON H.Id IN (1, 2, 10)
ORDER BY 
    PS.TotalPosts DESC, PS.AverageScore DESC;