WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.AnswerCount,
        p.CreationDate,
        p.OwnerUserId,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.Score > 0
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.AnswerCount,
        rp.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        COALESCE(c.CommentCount, 0) AS CommentCount,
        COALESCE(v.UpVotes, 0) AS UpVotes
    FROM 
        RankedPosts rp
    JOIN 
        Users u ON rp.OwnerUserId = u.Id
    LEFT JOIN (
        SELECT 
            PostId, 
            COUNT(*) AS CommentCount 
        FROM 
            Comments 
        GROUP BY PostId
    ) c ON rp.PostId = c.PostId
    LEFT JOIN (
        SELECT 
            PostId, 
            COUNT(*) AS UpVotes 
        FROM 
            Votes 
        WHERE 
            VoteTypeId = 2
        GROUP BY PostId
    ) v ON rp.PostId = v.PostId
    WHERE 
        rp.Rank <= 5  
),
PostTags AS (
    SELECT 
        p.Id AS PostId,
        STRING_AGG(t.TagName, ', ') AS Tags
    FROM 
        Posts p
    JOIN 
        Tags t ON POSITION(t.TagName IN p.Tags) > 0  
    GROUP BY 
        p.Id
),
PostsWithTags AS (
    SELECT 
        tp.*,
        pt.Tags
    FROM 
        TopPosts tp
    LEFT JOIN 
        PostTags pt ON tp.PostId = pt.PostId
)
SELECT 
    pwt.PostId,
    pwt.Title,
    pwt.Score,
    pwt.AnswerCount,
    pwt.CreationDate,
    pwt.OwnerDisplayName,
    pwt.CommentCount,
    pwt.UpVotes,
    pwt.Tags,
    CASE 
        WHEN pwt.Score > 100 THEN 'Highly Active'
        WHEN pwt.Score BETWEEN 51 AND 100 THEN 'Moderately Active'
        ELSE 'Low Activity'
    END AS ActivityLevel
FROM 
    PostsWithTags pwt
ORDER BY 
    pwt.Score DESC, pwt.CreationDate DESC;