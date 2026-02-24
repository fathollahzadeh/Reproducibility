
WITH TagStats AS (
    SELECT 
        unnest(string_to_array(trim(both '<>' FROM Tags), '><')) AS TagName,
        COUNT(*) AS PostCount
    FROM 
        Posts
    WHERE 
        PostTypeId = 1 
    GROUP BY 
        TagName
),
UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN C.Id IS NOT NULL THEN 1 ELSE 0 END) AS CommentCount,
        SUM(CASE WHEN P.Score >= 0 THEN 1 ELSE 0 END) AS UpVotedPosts,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotesReceived,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotesReceived
    FROM 
        Users U
        LEFT JOIN Posts P ON U.Id = P.OwnerUserId
        LEFT JOIN Comments C ON P.Id = C.PostId
        LEFT JOIN Votes V ON P.Id = V.PostId AND V.UserId = U.Id
    GROUP BY 
        U.Id, U.DisplayName
),
TagEnhancements AS (
    SELECT 
        T.TagName,
        COUNT(DISTINCT PH.UserId) AS UsersEdited,
        MAX(PH.CreationDate) AS LastEdited
    FROM 
        PostHistory PH
        JOIN Tags T ON PH.PostId = T.ExcerptPostId OR PH.PostId = T.WikiPostId
    WHERE 
        PH.PostHistoryTypeId IN (4, 5, 6) 
    GROUP BY 
        T.TagName
)
SELECT 
    TS.TagName,
    TS.PostCount,
    UA.UserId,
    UA.DisplayName,
    UA.QuestionCount,
    UA.AnswerCount,
    UA.CommentCount,
    UA.UpVotedPosts,
    UA.UpVotesReceived,
    UA.DownVotesReceived,
    TE.UsersEdited,
    TE.LastEdited
FROM 
    TagStats TS
JOIN 
    UserActivity UA ON UA.QuestionCount > 0 
LEFT JOIN 
    TagEnhancements TE ON TS.TagName = TE.TagName
ORDER BY 
    TS.PostCount DESC, UA.UpVotesReceived DESC
LIMIT 20;
