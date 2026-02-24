
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, p.Title, p.ViewCount, u.DisplayName, p.OwnerUserId, p.CreationDate
),
FilteredPosts AS (
    SELECT 
        PostId, Title, ViewCount, OwnerDisplayName, CommentCount, UpVotes, DownVotes
    FROM 
        RankedPosts
    WHERE 
        rn = 1 AND ViewCount > 100
),
TopPosts AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY ViewCount DESC) AS ViewRank
    FROM 
        FilteredPosts
)
SELECT 
    tp.Title,
    tp.ViewCount,
    tp.OwnerDisplayName,
    tp.CommentCount,
    tp.UpVotes,
    tp.DownVotes,
    COALESCE(tp.UpVotes - tp.DownVotes, 0) AS NetScore,
    CASE 
        WHEN tp.UpVotes IS NULL THEN 'No Votes'
        ELSE 'Voted'
    END AS VoteStatus
FROM 
    TopPosts tp
WHERE 
    tp.ViewRank <= 10
ORDER BY 
    tp.ViewCount DESC;
