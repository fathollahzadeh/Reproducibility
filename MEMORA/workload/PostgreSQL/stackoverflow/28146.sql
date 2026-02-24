WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Body,
        p.Tags,
        u.DisplayName AS AuthorName,
        u.Reputation,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS ScoreRank,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount,
        COUNT(a.Id) OVER (PARTITION BY p.Id) AS AnswerCount
    FROM 
        Posts p
        JOIN Users u ON p.OwnerUserId = u.Id
        LEFT JOIN Comments c ON p.Id = c.PostId
        LEFT JOIN Posts a ON p.Id = a.ParentId AND a.PostTypeId = 2
    WHERE
        p.PostTypeId = 1  
),
PopularPosts AS (
    SELECT
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Body,
        rp.Tags,
        rp.AuthorName,
        rp.Reputation,
        rp.ScoreRank,
        rp.CommentCount,
        rp.AnswerCount,
        (CASE WHEN rp.ScoreRank = 1 THEN 'Top Question' ELSE 'Other' END) AS QuestionRank
    FROM 
        RankedPosts rp
    WHERE 
        rp.ScoreRank <= 5  
),
TagStats AS (
    SELECT
        unnest(string_to_array(rp.Tags, '><')) AS Tag,  
        COUNT(*) AS PostCount
    FROM
        PopularPosts rp
    GROUP BY Tag
),
FinalReport AS (
    SELECT
        pp.PostId,
        pp.Title,
        pp.AuthorName,
        pp.Reputation,
        pp.CreationDate,
        pp.CommentCount,
        pp.AnswerCount,
        ts.Tag,
        ts.PostCount
    FROM
        PopularPosts pp
    LEFT JOIN TagStats ts ON pp.Tags LIKE '%' || ts.Tag || '%'
)
SELECT 
    PostId,
    Title,
    AuthorName,
    Reputation,
    CreationDate,
    CommentCount,
    AnswerCount,
    Tag,
    PostCount
FROM 
    FinalReport
ORDER BY 
    Reputation DESC, CreationDate DESC, PostCount DESC
LIMIT 20;