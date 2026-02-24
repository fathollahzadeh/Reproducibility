
WITH TaggedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Body,
        P.Tags,
        P.CreationDate,
        U.DisplayName AS Author,
        (SELECT COUNT(*) FROM Comments C WHERE C.PostId = P.Id) AS CommentCount,
        (SELECT COUNT(*) FROM Votes V WHERE V.PostId = P.Id AND V.VoteTypeId = 2) AS UpVotes,
        (SELECT COUNT(*) FROM Votes V WHERE V.PostId = P.Id AND V.VoteTypeId = 3) AS DownVotes
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.PostTypeId = 1 
),
TagStats AS (
    SELECT 
        unnest(string_to_array(substring(Tags, 2, length(Tags)-2), '><')) AS Tag,
        COUNT(*) AS PostCount
    FROM 
        TaggedPosts
    GROUP BY 
        Tag
),
TopTags AS (
    SELECT 
        Tag,
        PostCount,
        ROW_NUMBER() OVER (ORDER BY PostCount DESC) AS Rank
    FROM 
        TagStats
),
TopTaggedPosts AS (
    SELECT 
        TP.PostId,
        TP.Title,
        TP.Author,
        TP.CreationDate,
        TP.CommentCount,
        TP.UpVotes,
        TP.DownVotes,
        TT.Tag
    FROM 
        TaggedPosts TP
    JOIN 
        TopTags TT ON TT.Tag IN (SELECT unnest(string_to_array(substring(TP.Tags, 2, length(TP.Tags)-2), '><')))
    WHERE 
        TT.Rank <= 10 
)
SELECT 
    TTP.PostId,
    TTP.Title,
    TTP.Author,
    TTP.CreationDate,
    TTP.CommentCount,
    TTP.UpVotes,
    TTP.DownVotes,
    TTP.Tag,
    (SELECT SUM(P.Score) FROM Posts P WHERE P.ParentId = TTP.PostId) AS TotalScoreForAnswers
FROM 
    TopTaggedPosts TTP
ORDER BY 
    TTP.UpVotes DESC, 
    TTP.CommentCount DESC;
