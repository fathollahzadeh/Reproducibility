
WITH UserVoteStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS DownVotes,
        COUNT(CASE WHEN V.VoteTypeId = 5 THEN 1 END) AS Favorites,
        COUNT(V.Id) AS TotalVotes
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
        COUNT(P.Id) AS PostCount,
        SUM(P.Score) AS TotalScore,
        AVG(P.ViewCount) AS AvgViewCount,
        MAX(P.CreationDate) AS LastPostDate
    FROM 
        Posts P
    GROUP BY 
        P.OwnerUserId
),
CombinedStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COALESCE(UV.UpVotes, 0) AS UpVotes,
        COALESCE(UV.DownVotes, 0) AS DownVotes,
        COALESCE(UV.Favorites, 0) AS Favorites,
        COALESCE(PS.PostCount, 0) AS PostCount,
        COALESCE(PS.TotalScore, 0) AS TotalScore,
        COALESCE(PS.AvgViewCount, 0) AS AvgViewCount,
        PS.LastPostDate
    FROM 
        Users U
    LEFT JOIN 
        UserVoteStats UV ON U.Id = UV.UserId
    LEFT JOIN 
        PostStats PS ON U.Id = PS.OwnerUserId
)
SELECT 
    C.UserId,
    C.DisplayName,
    C.UpVotes,
    C.DownVotes,
    C.Favorites,
    C.PostCount,
    C.TotalScore,
    C.AvgViewCount,
    C.LastPostDate,
    CASE 
        WHEN C.PostCount = 0 THEN 'No Posts'
        ELSE CONCAT('Posts: ', C.PostCount, ', Score: ', C.TotalScore)
    END AS PostSummary,
    RANK() OVER (ORDER BY C.TotalScore DESC) AS ScoreRank
FROM 
    CombinedStats C
WHERE 
    C.UpVotes - C.DownVotes > 5
ORDER BY 
    C.TotalScore DESC
LIMIT 10 OFFSET 0;
