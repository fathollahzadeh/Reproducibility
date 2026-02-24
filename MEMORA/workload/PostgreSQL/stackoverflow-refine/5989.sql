
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.AnswerCount,
        u.DisplayName AS Author,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank,
        p.Tags
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 AND  
        p.Score > 0          
),
TopTags AS (
    SELECT 
        Tags,
        COUNT(*) AS QuestionCount
    FROM 
        Posts
    WHERE 
        PostTypeId = 1
    GROUP BY 
        Tags
    ORDER BY 
        QuestionCount DESC
    LIMIT 10
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.AnswerCount,
    rp.Author,
    tt.Tags,
    (SELECT COUNT(*) FROM Comments c WHERE c.PostId = rp.PostId) AS CommentCount,
    (SELECT COUNT(*) FROM Votes v WHERE v.PostId = rp.PostId AND v.VoteTypeId = 2) AS UpVoteCount
FROM 
    RankedPosts rp
JOIN 
    TopTags tt ON rp.Tags = tt.Tags
WHERE 
    rp.Rank = 1
ORDER BY 
    rp.Score DESC, rp.CreationDate DESC;
