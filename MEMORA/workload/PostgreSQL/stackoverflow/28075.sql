
WITH PostSummary AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Body,
        P.CreationDate,
        U.DisplayName AS OwnerName,
        P.ViewCount,
        P.AnswerCount,
        P.CommentCount,
        P.Score,
        P.Tags,
        PH.CreationDate AS LastEditDate,
        PT.Name AS PostTypeName,
        (SELECT COUNT(*) FROM PostHistory PH2 WHERE PH2.PostId = P.Id) AS EditCount,
        STRING_AGG(DISTINCT T.TagName, ', ') AS TagList
    FROM Posts P
    JOIN Users U ON P.OwnerUserId = U.Id
    JOIN PostHistory PH ON P.Id = PH.PostId
    JOIN PostTypes PT ON P.PostTypeId = PT.Id
    LEFT JOIN Tags T ON POSITION('|' || T.TagName || '|' IN '|' || P.Tags || '|') > 0
    WHERE P.CreationDate >= CURRENT_DATE - INTERVAL '5 years' 
    GROUP BY P.Id, P.Title, P.Body, P.CreationDate, U.DisplayName, P.ViewCount, P.AnswerCount, P.CommentCount, P.Score, P.Tags, PH.CreationDate, PT.Name
),
VoteSummary AS (
    SELECT 
        V.PostId,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM Votes V
    GROUP BY V.PostId
),
FinalSummary AS (
    SELECT 
        PS.PostId,
        PS.Title,
        PS.OwnerName,
        PS.CreationDate,
        PS.ViewCount,
        PS.AnswerCount,
        PS.CommentCount,
        PS.Score,
        PS.LastEditDate,
        PS.TagList,
        COALESCE(VS.UpVotes, 0) AS TotalUpVotes,
        COALESCE(VS.DownVotes, 0) AS TotalDownVotes,
        PS.EditCount,
        PS.PostTypeName
    FROM PostSummary PS
    LEFT JOIN VoteSummary VS ON PS.PostId = VS.PostId
)
SELECT 
    FS.PostId,
    FS.Title,
    FS.OwnerName,
    FS.CreationDate,
    FS.ViewCount,
    FS.AnswerCount,
    FS.CommentCount,
    FS.Score,
    FS.LastEditDate,
    FS.TagList,
    FS.TotalUpVotes,
    FS.TotalDownVotes,
    FS.EditCount,
    FS.PostTypeName,
    DENSE_RANK() OVER (ORDER BY FS.Score DESC) AS RankByScore,
    DENSE_RANK() OVER (ORDER BY FS.ViewCount DESC) AS RankByViewCount
FROM FinalSummary FS
WHERE FS.AnswerCount > 0 
ORDER BY FS.Score DESC, FS.ViewCount DESC;
