WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        ROW_NUMBER() OVER (ORDER BY COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) DESC) AS VoteRank
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1  
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount
),
TopPosts AS (
    SELECT 
        PostId, 
        Title, 
        ViewCount, 
        UpVotes, 
        DownVotes,
        VoteRank
    FROM 
        RankedPosts
    WHERE 
        VoteRank <= 10
),
PostComments AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentCount,
        STRING_AGG(c.Text, '; ') AS Comments
    FROM 
        Comments c
    JOIN 
        TopPosts tp ON c.PostId = tp.PostId
    GROUP BY 
        c.PostId
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.ViewCount,
    tp.UpVotes,
    tp.DownVotes,
    pc.CommentCount,
    COALESCE(pc.Comments, 'No comments') AS Comments,
    CASE 
        WHEN tp.UpVotes - tp.DownVotes > 0 THEN 'Positive'
        WHEN tp.UpVotes - tp.DownVotes < 0 THEN 'Negative'
        ELSE 'Neutral'
    END AS Sentiment
FROM 
    TopPosts tp
LEFT JOIN 
    PostComments pc ON tp.PostId = pc.PostId
ORDER BY 
    tp.ViewCount DESC;