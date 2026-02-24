WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.PostTypeId,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY COUNT(c.Id) DESC) AS RankByComments
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year' 
        AND p.ViewCount > 100
    GROUP BY 
        p.Id, p.Title, p.PostTypeId
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.PostTypeId,
        rp.CommentCount,
        rp.UpVotes,
        rp.DownVotes,
        CASE 
            WHEN rp.CommentCount = 0 THEN 0 
            ELSE (CAST(rp.UpVotes AS FLOAT) / NULLIF(rp.CommentCount, 0))
        END AS UpvoteToCommentRatio
    FROM 
        RankedPosts rp
    WHERE 
        rp.RankByComments <= 5
)

SELECT 
    tp.PostId,
    tp.Title,
    pt.Name AS PostType,
    tp.CommentCount,
    tp.UpVotes,
    tp.DownVotes,
    tp.UpvoteToCommentRatio,
    u.DisplayName AS OwnerDisplayName,
    u.Reputation AS OwnerReputation
FROM 
    TopPosts tp
JOIN 
    PostTypes pt ON tp.PostTypeId = pt.Id
JOIN 
    Users u ON u.Id = (SELECT p.OwnerUserId FROM Posts p WHERE p.Id = tp.PostId)
ORDER BY 
    tp.UpvoteToCommentRatio DESC, 
    tp.CommentCount DESC;