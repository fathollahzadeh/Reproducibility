WITH TagStatistics AS (
    SELECT
        T.TagName,
        COUNT(DISTINCT P.Id) AS PostCount,
        COUNT(DISTINCT C.Id) AS CommentCount,
        SUM(P.ViewCount) AS TotalViews,
        SUM(P.Score) AS TotalScore,
        STRING_AGG(DISTINCT U.DisplayName, ', ') AS TopContributors
    FROM
        Tags T
    LEFT JOIN
        Posts P ON P.Tags LIKE '%' || T.TagName || '%'
    LEFT JOIN
        Comments C ON C.PostId = P.Id
    LEFT JOIN
        Users U ON U.Id = P.OwnerUserId
    WHERE
        P.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY
        T.TagName
),
MostCommentedPosts AS (
    SELECT
        P.Id AS PostId,
        P.Title,
        C.Text AS LastComment,
        C.CreationDate AS LastCommentDate,
        COUNT(C.Id) AS CommentCount
    FROM
        Posts P
    LEFT JOIN
        Comments C ON C.PostId = P.Id
    WHERE
        P.PostTypeId = 1  
    GROUP BY
        P.Id, P.Title, C.Text, C.CreationDate
    ORDER BY
        CommentCount DESC
    LIMIT 5
)
SELECT
    TS.TagName,
    TS.PostCount,
    TS.CommentCount,
    TS.TotalViews,
    TS.TotalScore,
    TS.TopContributors,
    MCP.Title AS MostCommentedTitle,
    MCP.LastComment,
    MCP.LastCommentDate
FROM
    TagStatistics TS
JOIN
    MostCommentedPosts MCP ON TS.PostCount > 0
ORDER BY
    TS.TotalViews DESC, TS.PostCount DESC;