
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        pt.Name AS PostType,
        ROW_NUMBER() OVER (PARTITION BY pt.Name ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),
TopRankedPosts AS (
    SELECT 
        PostId,
        Title,
        Score,
        ViewCount,
        CreationDate,
        OwnerDisplayName,
        PostType
    FROM 
        RankedPosts
    WHERE 
        Rank <= 5
),
PostVoteCounts AS (
    SELECT 
        postId,
        COUNT(CASE WHEN vt.Name = 'UpMod' THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN vt.Name = 'DownMod' THEN 1 END) AS DownVotes
    FROM 
        Votes v
    JOIN 
        VoteTypes vt ON v.VoteTypeId = vt.Id
    GROUP BY 
        postId
)
SELECT 
    trp.PostId,
    trp.Title,
    trp.Score,
    trp.ViewCount,
    trp.CreationDate,
    trp.OwnerDisplayName,
    trp.PostType,
    pvc.UpVotes,
    pvc.DownVotes,
    COALESCE(b.Name, 'No Badge') AS UserBadge,
    COUNT(c.Id) AS CommentCount
FROM 
    TopRankedPosts trp
LEFT JOIN 
    PostVoteCounts pvc ON trp.PostId = pvc.postId
LEFT JOIN 
    Users u ON trp.OwnerDisplayName = u.DisplayName
LEFT JOIN 
    Badges b ON u.Id = b.UserId AND b.Date >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
LEFT JOIN 
    Comments c ON trp.PostId = c.PostId
GROUP BY 
    trp.PostId, trp.Title, trp.Score, trp.ViewCount, trp.CreationDate, trp.OwnerDisplayName, trp.PostType, pvc.UpVotes, pvc.DownVotes, b.Name
ORDER BY 
    trp.Score DESC, trp.ViewCount DESC;
