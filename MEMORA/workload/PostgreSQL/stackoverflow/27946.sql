
WITH Tag_Posts AS (
    SELECT
        P.Id AS PostId,
        P.Title,
        P.Body,
        P.CreationDate,
        P.Tags,
        COUNT(DISTINCT C.Id) AS CommentCount,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVoteCount,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVoteCount,
        (SELECT COUNT(*) FROM Votes V2 WHERE V2.PostId = P.Id AND V2.VoteTypeId = 4) AS BountyCount,
        U.DisplayName AS OwnerDisplayName,
        P.OwnerUserId
    FROM
        Posts P
    LEFT JOIN
        Comments C ON P.Id = C.PostId
    LEFT JOIN
        Votes V ON P.Id = V.PostId
    LEFT JOIN
        Users U ON P.OwnerUserId = U.Id
    WHERE
        P.PostTypeId = 1 
    GROUP BY
        P.Id, P.Title, P.Body, P.CreationDate, P.Tags, U.DisplayName, P.OwnerUserId
),
Tag_Split AS (
    SELECT
        PostId,
        TRIM(UNNEST(string_to_array(Tags, '>'))) AS TagName
    FROM
        Tag_Posts
)
SELECT
    T.TagName,
    COUNT(DISTINCT TP.PostId) AS PostCount,
    AVG(TP.CommentCount) AS AvgCommentCount,
    SUM(TP.UpVoteCount) AS TotalUpVotes,
    SUM(TP.DownVoteCount) AS TotalDownVotes,
    SUM(TP.BountyCount) AS TotalBounties
FROM
    Tag_Split T
JOIN
    Tag_Posts TP ON T.PostId = TP.PostId
WHERE
    T.TagName IS NOT NULL AND T.TagName <> ''
GROUP BY
    T.TagName
ORDER BY
    PostCount DESC, TotalUpVotes DESC;
