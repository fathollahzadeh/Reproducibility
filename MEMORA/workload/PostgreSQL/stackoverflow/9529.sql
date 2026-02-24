
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        u.DisplayName AS Author,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        RANK() OVER (ORDER BY COUNT(c.Id) DESC) AS RankByComments
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= '2023-01-01' 
        AND p.PostTypeId = 1
    GROUP BY 
        p.Id, p.Title, p.CreationDate, u.DisplayName
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        Author,
        CommentCount,
        UpVotes,
        DownVotes
    FROM 
        RankedPosts 
    WHERE 
        RankByComments <= 10
)
SELECT 
    tp.Title,
    tp.Author,
    tp.CommentCount,
    tp.UpVotes,
    tp.DownVotes,
    CASE 
        WHEN (tp.UpVotes + tp.DownVotes) > 0 THEN ROUND((tp.UpVotes * 1.0 / (tp.UpVotes + tp.DownVotes)) * 100, 2) 
        ELSE 0 
    END AS UpvotePercentage
FROM 
    TopPosts tp
ORDER BY 
    tp.CommentCount DESC, 
    tp.UpVotes DESC;
