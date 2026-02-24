WITH RankedPosts AS (
    SELECT 
        p.Id AS PostID,
        p.Title,
        p.CreationDate,
        p.Body,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        COUNT(a.Id) AS AnswerCount,
        COUNT(c.Id) AS CommentCount,
        RANK() OVER (PARTITION BY p.Tags ORDER BY COUNT(a.Id) DESC) AS TagRank
    FROM Posts p
    LEFT JOIN Posts a ON p.Id = a.ParentId AND a.PostTypeId = 2
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Users u ON p.OwnerUserId = u.Id
    WHERE p.PostTypeId = 1  
    GROUP BY p.Id, p.Title, p.CreationDate, p.Body, p.Tags, u.DisplayName
),
MostCommented AS (
    SELECT 
        rp.PostID,
        rp.Title,
        rp.CreationDate,
        rp.OwnerDisplayName,
        rp.CommentCount,
        ROW_NUMBER() OVER (ORDER BY rp.CommentCount DESC) AS CommentRank
    FROM RankedPosts rp
),
MostAnswered AS (
    SELECT 
        rp.PostID,
        rp.Title,
        rp.CreationDate,
        rp.OwnerDisplayName,
        rp.AnswerCount,
        ROW_NUMBER() OVER (ORDER BY rp.AnswerCount DESC) AS AnswerRank
    FROM RankedPosts rp
),
FinalResults AS (
    SELECT 
        mc.PostID,
        mc.Title,
        mc.CreationDate,
        mc.OwnerDisplayName,
        mc.CommentCount,
        ma.AnswerCount,
        mc.CommentRank,
        ma.AnswerRank,
        CONCAT('Tags: ', rp.Tags) AS TagsInfo
    FROM MostCommented mc
    JOIN MostAnswered ma ON mc.PostID = ma.PostID
    JOIN RankedPosts rp ON mc.PostID = rp.PostID
)
SELECT 
    PostID,
    Title,
    CreationDate,
    OwnerDisplayName,
    CommentCount,
    AnswerCount,
    CONCAT('Rank by Comments: ', CommentRank, ' | Rank by Answers: ', AnswerRank) AS RankingDetails,
    TagsInfo
FROM FinalResults
WHERE (CommentRank <= 5 OR AnswerRank <= 5)
ORDER BY CommentRank, AnswerRank;