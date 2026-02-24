
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.LastActivityDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.LastActivityDate, p.Score, p.ViewCount, p.AnswerCount, p.CommentCount, u.DisplayName
), PostStats AS (
    SELECT 
        PostId,
        Title, 
        OwnerDisplayName,
        Rank,
        CASE 
            WHEN AnswerCount > 5 THEN 'High Answer Count' 
            WHEN Score > 10 THEN 'High Score' 
            ELSE 'Regular Post' 
        END AS PostCategory
    FROM 
        RankedPosts
    WHERE 
        Rank <= 10
)
SELECT 
    ps.Title,
    ps.OwnerDisplayName,
    ps.PostCategory,
    COUNT(v.Id) AS VoteCount,
    SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
    SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
FROM 
    PostStats ps
LEFT JOIN 
    Votes v ON ps.PostId = v.PostId
GROUP BY 
    ps.Title, ps.OwnerDisplayName, ps.PostCategory
ORDER BY 
    VoteCount DESC, ps.Title;
