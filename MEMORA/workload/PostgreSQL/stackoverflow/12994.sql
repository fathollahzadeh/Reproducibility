
WITH PostSummary AS (
    SELECT
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        P.Score,
        U.DisplayName AS OwnerDisplayName,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        COUNT(I.Id) AS InteractionCount
    FROM
        Posts P
    LEFT JOIN
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN
        Comments C ON P.Id = C.PostId
    LEFT JOIN
        Votes V ON P.Id = V.PostId
    LEFT JOIN
        PostLinks I ON P.Id = I.PostId
    WHERE
        P.CreationDate >= DATE '2023-01-01'
    GROUP BY
        P.Id, P.Title, P.CreationDate, P.ViewCount, P.Score, U.DisplayName
),
PostTypeSummary AS (
    SELECT
        PT.Name AS PostTypeName,
        COUNT(PS.PostId) AS PostCount,
        SUM(PS.ViewCount) AS TotalViews,
        AVG(PS.Score) AS AverageScore
    FROM
        PostSummary PS
    JOIN
        PostTypes PT ON PS.PostId = PT.Id
    GROUP BY
        PT.Name
)
SELECT
    PTS.PostTypeName,
    PTS.PostCount,
    PTS.TotalViews,
    PTS.AverageScore
FROM
    PostTypeSummary PTS
ORDER BY
    PTS.PostCount DESC;
