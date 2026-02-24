WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN P.Score > 0 THEN P.Score ELSE 0 END) AS TotalScore,
        COUNT(DISTINCT C.Id) AS CommentCount,
        SUM(CASE WHEN B.Id IS NOT NULL THEN 1 ELSE 0 END) AS BadgeCount,
        AVG(COALESCE(P.ViewCount, 0)) AS AvgViewCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName
),
PostHistoryDetails AS (
    SELECT 
        PH.PostId,
        PH.UserId,
        PH.CreationDate,
        P.Title,
        P.Body,
        PH.Comment,
        ROW_NUMBER() OVER (PARTITION BY PH.PostId ORDER BY PH.CreationDate DESC) AS HistoryRank
    FROM 
        PostHistory PH
    INNER JOIN 
        Posts P ON PH.PostId = P.Id
    WHERE 
        PH.PostHistoryTypeId IN (10, 11, 12) 
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        PostCount,
        TotalScore,
        CommentCount,
        BadgeCount,
        AvgViewCount,
        ROW_NUMBER() OVER (ORDER BY TotalScore DESC) AS UserRank
    FROM 
        UserActivity
)
SELECT 
    TU.UserId,
    TU.DisplayName,
    TU.PostCount,
    TU.TotalScore,
    TU.CommentCount,
    TU.BadgeCount,
    TU.AvgViewCount,
    PHD.PostId,
    PHD.Title,
    PHD.Body,
    PHD.CreationDate AS PostHistoryDate,
    PHD.Comment AS HistoryComment
FROM 
    TopUsers TU
LEFT JOIN 
    PostHistoryDetails PHD ON TU.UserId = PHD.UserId
WHERE 
    TU.UserRank <= 5 
    AND PHD.HistoryRank = 1 
ORDER BY 
    TU.TotalScore DESC, PHD.PostId;