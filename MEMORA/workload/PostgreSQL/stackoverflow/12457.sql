SELECT
    PH.PostId,
    P.Title,
    PH.UserId,
    U.DisplayName AS EditorDisplayName,
    PH.CreationDate AS EditDate,
    P.Score,
    P.ViewCount,
    P.AnswerCount,
    P.CommentCount,
    P.FavoriteCount,
    PH.Comment AS EditComment,
    PH.Text AS NewText,
    P.Tags
FROM
    PostHistory PH
JOIN
    Posts P ON PH.PostId = P.Id
JOIN
    Users U ON PH.UserId = U.Id
WHERE
    PH.PostHistoryTypeId IN (4, 5, 6)  
ORDER BY
    PH.CreationDate DESC;