WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title,
        p.Body, 
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId IN (2, 6)) AS UpVotes,  
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 3) AS DownVotes,
        ROW_NUMBER() OVER (ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, u.DisplayName, p.ViewCount
),
FilteredPosts AS (
    SELECT 
        *,
        (UpVotes - DownVotes) AS NetVotes
    FROM 
        RankedPosts
    WHERE 
        ViewCount > 100  
),
TopPosts AS (
    SELECT 
        PostId, 
        Title, 
        OwnerDisplayName, 
        CreationDate,
        ViewCount, 
        CommentCount, 
        NetVotes,
        RANK() OVER (ORDER BY NetVotes DESC) AS VoteRank
    FROM 
        FilteredPosts
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.OwnerDisplayName,
    tp.CreationDate,
    tp.ViewCount,
    tp.CommentCount,
    tp.NetVotes,
    CASE 
        WHEN tp.VoteRank <= 10 THEN 'Top Trending'
        WHEN tp.VoteRank BETWEEN 11 AND 50 THEN 'Popular'
        ELSE 'Less Active'
    END AS PostCategory
FROM 
    TopPosts tp
WHERE 
    tp.VoteRank <= 50  
ORDER BY 
    tp.VoteRank;