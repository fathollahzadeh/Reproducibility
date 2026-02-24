
WITH RankedPosts AS (
    SELECT 
        P.Id AS PostID,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        P.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS RN
    FROM 
        Posts P
    WHERE 
        P.PostTypeId = 1
),
UserActivity AS (
    SELECT 
        U.Id AS UserID,
        U.DisplayName,
        U.Reputation,
        COUNT(P.Id) AS TotalQuestions,
        SUM(COALESCE(V.BountyAmount, 0)) AS TotalBounties,
        SUM(P.Score) AS TotalScore,
        AVG(P.ViewCount) AS AvgViewCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId AND P.PostTypeId = 1
    LEFT JOIN 
        Votes V ON P.Id = V.PostId AND V.VoteTypeId = 9  
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
RecentCloseReasons AS (
    SELECT 
        PH.PostId,
        PH.PostHistoryTypeId,
        CR.Name AS CloseReason,
        PH.CreationDate AS CloseDate,
        ROW_NUMBER() OVER (PARTITION BY PH.PostId ORDER BY PH.CreationDate DESC) AS CloseRank
    FROM 
        PostHistory PH
    JOIN 
        CloseReasonTypes CR ON CAST(PH.Comment AS INTEGER) = CR.Id
    WHERE 
        PH.PostHistoryTypeId IN (10, 11)
)
SELECT 
    R.Title,
    R.CreationDate,
    U.DisplayName AS UserName,
    U.TotalQuestions,
    U.TotalBounties,
    U.TotalScore,
    R.Score,
    COALESCE(R.ViewCount, 0) AS PostViewCount,
    C.CloseReason AS RecentCloseReason,
    C.CloseDate AS LastClosedDate
FROM 
    RankedPosts R
JOIN 
    UserActivity U ON R.OwnerUserId = U.UserID
LEFT JOIN 
    RecentCloseReasons C ON R.PostID = C.PostId AND C.CloseRank = 1
WHERE 
    R.RN = 1
ORDER BY 
    U.TotalScore DESC, R.CreationDate DESC
LIMIT 50;
