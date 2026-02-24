
WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        U.DisplayName AS OwnerDisplayName,
        COUNT(C.Id) AS CommentCount,
        RANK() OVER (PARTITION BY P.OwnerUserId ORDER BY P.Score DESC) AS PostRank
    FROM 
        Posts P
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    WHERE 
        P.CreationDate >= CURRENT_TIMESTAMP - INTERVAL '2 years'
        AND P.Score IS NOT NULL
    GROUP BY 
        P.Id, P.Title, P.Score, U.DisplayName
),

ClosedPosts AS (
    SELECT 
        PH.PostId,
        PH.CreationDate,
        CRT.Name AS CloseReason
    FROM 
        PostHistory PH
    JOIN 
        CloseReasonTypes CRT ON (PH.Comment::json->>'CloseReasonId')::int = CRT.Id
    WHERE 
        PH.PostHistoryTypeId = 10 
        AND PH.CreationDate >= CURRENT_TIMESTAMP - INTERVAL '6 months'
),

TopUsers AS (
    SELECT 
        U.Id,
        U.DisplayName,
        SUM(P.Score) AS TotalScore,
        SUM(CASE WHEN P.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedAnswers
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName
    HAVING 
        SUM(P.Score) > 100
)

SELECT 
    RP.PostId,
    RP.Title,
    RP.OwnerDisplayName,
    RP.Score,
    RP.CommentCount,
    COALESCE(CP.CloseReason, 'Open') AS CloseReason,
    TU.DisplayName AS TopUser,
    TU.TotalScore,
    TU.AcceptedAnswers,
    CASE
        WHEN RP.PostRank = 1 THEN 'Top Post'
        ELSE 'Regular Post'
    END AS PostCategory
FROM 
    RankedPosts RP
LEFT JOIN 
    ClosedPosts CP ON RP.PostId = CP.PostId
LEFT JOIN 
    TopUsers TU ON RP.OwnerDisplayName = TU.DisplayName
WHERE 
    RP.CommentCount > 5
    AND (RP.Score >= 10 OR RP.CommentCount >= 15)
ORDER BY 
    RP.Score DESC, RP.CommentCount DESC;
