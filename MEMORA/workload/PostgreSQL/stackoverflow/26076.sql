WITH TagStats AS (
    SELECT
        T.TagName,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(P.ViewCount) AS TotalViews,
        SUM(P.AnswerCount) AS TotalAnswers,
        SUM(P.CommentCount) AS TotalComments
    FROM
        Tags T
    LEFT JOIN
        Posts P ON P.Tags LIKE '%' || T.TagName || '%'
    WHERE
        P.PostTypeId = 1 
    GROUP BY
        T.TagName
),
UserEngagement AS (
    SELECT
        U.Id AS UserId,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotesReceived,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotesReceived,
        SUM(CASE WHEN C.Id IS NOT NULL THEN 1 ELSE 0 END) AS CommentsReceived
    FROM
        Users U
    LEFT JOIN
        Votes V ON V.UserId = U.Id
    LEFT JOIN
        Comments C ON C.UserId = U.Id
    GROUP BY
        U.Id
),
PostHistorySummary AS (
    SELECT
        PH.UserDisplayName,
        COUNT(PH.Id) AS EditCount,
        STRING_AGG(DISTINCT P.Title, ', ') AS EditedPostTitles,
        STRING_AGG(DISTINCT PH.Comment, ', ') AS EditComments
    FROM
        PostHistory PH
    JOIN
        Posts P ON PH.PostId = P.Id
    WHERE
        PH.PostHistoryTypeId IN (4, 5, 6) 
    GROUP BY
        PH.UserDisplayName
)
SELECT
    TS.TagName,
    TS.PostCount,
    TS.TotalViews,
    TS.TotalAnswers,
    TS.TotalComments,
    UE.UserId,
    UE.UpVotesReceived,
    UE.DownVotesReceived,
    UE.CommentsReceived,
    PHS.EditCount,
    PHS.EditedPostTitles,
    PHS.EditComments
FROM
    TagStats TS
JOIN
    UserEngagement UE ON UE.UpVotesReceived + UE.DownVotesReceived > 10
JOIN
    PostHistorySummary PHS ON PHS.EditCount > 5
ORDER BY
    TS.TotalViews DESC, TS.PostCount DESC, UE.UpVotesReceived DESC;