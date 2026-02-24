WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        SUM(COALESCE(P.AnswerCount, 0)) AS TotalAnswers,
        SUM(COALESCE(P.ViewCount, 0)) AS TotalViews,
        DENSE_RANK() OVER (ORDER BY SUM(COALESCE(P.ViewCount, 0)) DESC) AS ViewRank
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    WHERE 
        U.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY 
        U.Id, U.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        TotalAnswers,
        TotalViews
    FROM 
        UserActivity
    WHERE 
        TotalAnswers > 5
),
ExpandedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        COALESCE(COUNT(C.Id), 0) AS CommentCount,
        COALESCE(PH.UserId, -1) AS LastEditorId,
        P.LastEditDate,
        ROW_NUMBER() OVER (PARTITION BY P.Id ORDER BY P.LastEditDate DESC) AS EditHistory
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        PostHistory PH ON P.Id = PH.PostId AND PH.PostHistoryTypeId IN (4, 5)
    WHERE 
        P.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '6 months'
    GROUP BY 
        P.Id, P.Title, PH.UserId, P.LastEditDate
)
SELECT 
    U.DisplayName AS ActiveUser,
    TP.PostId,
    TP.Title,
    TP.CommentCount,
    CASE 
        WHEN TP.LastEditorId = U.UserId THEN 'This user edited the post.'
        ELSE 'This user did not edit the post.'
    END AS EditStatus,
    CASE 
        WHEN TP.CommentCount > 10 THEN 'Highly discussed'
        WHEN TP.CommentCount > 0 THEN 'Some discussion'
        ELSE 'No discussions'
    END AS DiscussionLevel
FROM 
    TopUsers U
JOIN 
    ExpandedPosts TP ON U.UserId = TP.LastEditorId
WHERE 
    TP.EditHistory = 1
ORDER BY 
    U.DisplayName, TP.CommentCount DESC
LIMIT 50;