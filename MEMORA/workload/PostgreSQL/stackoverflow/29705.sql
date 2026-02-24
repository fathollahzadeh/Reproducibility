WITH TagCounts AS (
    SELECT 
        UNNEST(string_to_array(substring(Tags, 2, length(Tags)-2), '><')) AS Tag, 
        Id AS PostId
    FROM 
        Posts
    WHERE 
        PostTypeId = 1 
),
QuestionVotes AS (
    SELECT 
        PostId, 
        COUNT(CASE WHEN VoteTypeId = 2 THEN 1 END) AS UpVotes,  
        COUNT(CASE WHEN VoteTypeId = 3 THEN 1 END) AS DownVotes 
    FROM 
        Votes
    GROUP BY 
        PostId
),
QuestionDetails AS (
    SELECT 
        p.Id AS QuestionId,
        p.Title,
        p.CreationDate,
        p.Score,
        tc.Tag,
        qv.UpVotes,
        qv.DownVotes,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    JOIN 
        TagCounts tc ON p.Id = tc.PostId
    LEFT JOIN 
        QuestionVotes qv ON p.Id = qv.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, tc.Tag, qv.UpVotes, qv.DownVotes
),
Ranking AS (
    SELECT 
        QuestionId,
        Title,
        CreationDate,
        Score,
        Tag,
        UpVotes,
        DownVotes,
        CommentCount,
        RANK() OVER (PARTITION BY Tag ORDER BY (UpVotes - DownVotes) DESC, Score DESC) AS RankWithinTag
    FROM 
        QuestionDetails
)
SELECT 
    r.QuestionId,
    r.Title,
    r.CreationDate,
    r.Score,
    r.Tag,
    r.UpVotes,
    r.DownVotes,
    r.CommentCount,
    r.RankWithinTag
FROM 
    Ranking r
WHERE 
    r.RankWithinTag <= 5 
ORDER BY 
    r.Tag, r.RankWithinTag;