
WITH PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        pt.Name AS PostType,
        COALESCE(COUNT(c.Id), 0) AS CommentCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    LEFT JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    WHERE 
        p.CreationDate >= CURRENT_TIMESTAMP - INTERVAL '1 year'
    GROUP BY 
        p.Id, u.DisplayName, pt.Name, p.Title, p.CreationDate, p.ViewCount
),
TopPosts AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY ViewCount DESC) AS ViewRank
    FROM 
        PostDetails
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.CreationDate,
    tp.ViewCount,
    tp.OwnerDisplayName,
    tp.PostType,
    tp.CommentCount,
    tp.UpVotes,
    tp.DownVotes,
    CASE
        WHEN tp.ViewRank <= 10 THEN 'Top 10 Posts of the Year'
        ELSE 'Other Posts'
    END AS PostCategory
FROM 
    TopPosts tp
ORDER BY 
    tp.ViewCount DESC
LIMIT 50;
