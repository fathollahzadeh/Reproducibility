WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COUNT(DISTINCT c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) - COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) DESC) as Rank
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '30 days' 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.OwnerUserId
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.UpVotes,
        rp.DownVotes,
        rp.CommentCount,
        rp.Rank,
        u.DisplayName AS OwnerDisplayName,
        u.Reputation,
        CASE
            WHEN u.Reputation > 1000 THEN 'Experienced User'
            WHEN u.Reputation IS NULL THEN 'No Reputation'
            ELSE 'New User'
        END AS UserStatus
    FROM 
        RankedPosts rp
    INNER JOIN 
        Users u ON rp.OwnerUserId = u.Id
    WHERE 
        rp.Rank <= 5
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.UpVotes,
    tp.DownVotes,
    tp.CommentCount,
    tp.OwnerDisplayName,
    tp.Reputation,
    tp.UserStatus
FROM 
    TopPosts tp
ORDER BY 
    tp.UpVotes DESC, tp.CommentCount DESC;