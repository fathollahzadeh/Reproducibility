
WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        P.AnswerCount,
        P.CommentCount,
        P.OwnerUserId,
        RANK() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS PostRank
    FROM 
        Posts P
),
UserStatistics AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(P.Score) AS TotalScore,
        SUM(COALESCE(V.BountyAmount, 0)) AS TotalBounty
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId AND V.VoteTypeId = 8 
    GROUP BY 
        U.Id, U.DisplayName
),
TopUserStats AS (
    SELECT 
        US.UserId,
        US.DisplayName,
        US.TotalPosts,
        US.TotalScore,
        US.TotalBounty,
        ROW_NUMBER() OVER (ORDER BY US.TotalScore DESC) AS ScoreRanking
    FROM 
        UserStatistics US
    WHERE 
        US.TotalPosts > 10 
),
RecentPostInfo AS (
    SELECT 
        RP.PostId,
        RP.Title,
        RP.CreationDate,
        RP.Score,
        RP.ViewCount,
        RP.OwnerUserId,
        US.TotalPosts
    FROM 
        RankedPosts RP
    JOIN 
        TopUserStats US ON RP.OwnerUserId = US.UserId
    WHERE 
        RP.PostRank = 1  
)
SELECT 
    RPI.Title,
    RPI.CreationDate,
    RPI.Score,
    RPI.ViewCount,
    US.DisplayName,
    US.TotalPosts,
    COALESCE(PHT.Name, 'No Change') AS PostHistoryType,
    COUNT(CM.Id) AS CommentCount,
    SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes, 
    SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes 
FROM 
    RecentPostInfo RPI
LEFT JOIN 
    PostHistory PH ON RPI.PostId = PH.PostId
LEFT JOIN 
    PostHistoryTypes PHT ON PH.PostHistoryTypeId = PHT.Id
LEFT JOIN 
    Comments CM ON RPI.PostId = CM.PostId
LEFT JOIN 
    Votes V ON RPI.PostId = V.PostId
JOIN 
    UserStatistics US ON RPI.OwnerUserId = US.UserId
GROUP BY 
    RPI.Title, RPI.CreationDate, RPI.Score, RPI.ViewCount, US.DisplayName, US.TotalPosts, PHT.Name
ORDER BY 
    RPI.CreationDate DESC;
