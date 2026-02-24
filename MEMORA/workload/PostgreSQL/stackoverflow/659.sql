
WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        P.ViewCount,
        P.CreationDate,
        P.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS PostRank
    FROM 
        Posts P
    WHERE 
        P.PostTypeId = 1
        AND P.Score > 5
),
UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS QuestionCount,
        SUM(P.ViewCount) AS TotalViews,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes
    FROM 
        Users U 
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId AND P.PostTypeId = 1
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
CloseReasons AS (
    SELECT 
        PH.PostId,
        C.Name AS CloseReason,
        COUNT(PH.Id) AS CloseCount
    FROM 
        PostHistory PH
    JOIN 
        CloseReasonTypes C ON CAST(PH.Comment AS INT) = C.Id
    WHERE 
        PH.PostHistoryTypeId = 10
    GROUP BY 
        PH.PostId, C.Name
),
FinalStats AS (
    SELECT 
        U.UserId,
        U.DisplayName,
        U.Reputation,
        U.QuestionCount,
        U.TotalViews,
        COALESCE(CR.CloseReason, 'No Close Reason') AS CloseReason,
        COALESCE(CR.CloseCount, 0) AS CloseCount
    FROM 
        UserStats U
    LEFT JOIN 
        CloseReasons CR ON U.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = CR.PostId LIMIT 1)
)
SELECT 
    R.PostId,
    R.Title,
    R.Score,
    R.ViewCount,
    F.DisplayName,
    F.Reputation,
    F.QuestionCount,
    F.TotalViews,
    F.CloseReason,
    F.CloseCount,
    CASE 
        WHEN F.CloseCount > 0 THEN 'Closed Posts'
        ELSE 'Active Posts'
    END AS PostStatus
FROM 
    RankedPosts R
JOIN 
    FinalStats F ON R.OwnerUserId = F.UserId
WHERE 
    R.PostRank = 1
ORDER BY 
    R.Score DESC, 
    R.ViewCount DESC;
