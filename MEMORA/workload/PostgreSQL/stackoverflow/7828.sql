
WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT a.Id) AS AnswerCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        ROW_NUMBER() OVER (ORDER BY p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId AND a.PostTypeId = 2
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 AND 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, u.DisplayName
),
TopPosts AS (
    SELECT 
        Id, 
        Title, 
        OwnerDisplayName, 
        ViewCount, 
        CommentCount, 
        AnswerCount, 
        UpVotes, 
        DownVotes,
        Rank
    FROM 
        RankedPosts
    WHERE 
        Rank <= 10
)
SELECT 
    t.Title,
    t.OwnerDisplayName,
    t.ViewCount,
    t.CommentCount,
    t.AnswerCount,
    t.UpVotes,
    t.DownVotes,
    CASE 
        WHEN t.UpVotes - t.DownVotes > 0 THEN 'Positive'
        WHEN t.UpVotes - t.DownVotes < 0 THEN 'Negative'
        ELSE 'Neutral'
    END AS PostSentiment
FROM 
    TopPosts t
ORDER BY 
    t.ViewCount DESC;
