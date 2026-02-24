
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.OwnerUserId
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.CommentCount,
        rp.UpVotes,
        rp.DownVotes
    FROM 
        RankedPosts rp
    WHERE 
        rp.PostRank = 1
)
SELECT 
    u.DisplayName AS Author,
    tp.Title,
    tp.CreationDate,
    COALESCE(tp.CommentCount, 0) AS TotalComments,
    COALESCE(tp.UpVotes - tp.DownVotes, 0) AS NetVotes,
    CASE 
        WHEN tp.CreationDate < CURRENT_DATE - INTERVAL '6 months' THEN 'Old'
        ELSE 'Recent'
    END AS PostAgeCategory,
    STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
FROM 
    TopPosts tp
JOIN 
    Users u ON tp.PostId IN (SELECT p.Id FROM Posts p WHERE p.OwnerUserId = u.Id)
LEFT JOIN 
    Posts p ON tp.PostId = p.Id
LEFT JOIN 
    Tags t ON POSITION(t.TagName IN p.Tags) > 0
GROUP BY 
    u.DisplayName, tp.Title, tp.CreationDate, tp.CommentCount, tp.UpVotes, tp.DownVotes
ORDER BY 
    NetVotes DESC, tp.CreationDate DESC;
