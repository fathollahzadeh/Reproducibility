WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        pt.Name AS PostTypeName,
        ROW_NUMBER() OVER (PARTITION BY pt.Id ORDER BY p.ViewCount DESC) AS rn
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    WHERE 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '30 days'
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.ViewCount,
        rp.OwnerDisplayName,
        rp.PostTypeName
    FROM 
        RankedPosts rp
    WHERE 
        rp.rn <= 5
),
PostStats AS (
    SELECT 
        tp.PostId,
        tp.Title,
        tp.ViewCount,
        tp.OwnerDisplayName,
        tp.PostTypeName,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        TopPosts tp
    LEFT JOIN 
        Comments c ON tp.PostId = c.PostId
    LEFT JOIN 
        Votes v ON tp.PostId = v.PostId
    GROUP BY 
        tp.PostId, tp.Title, tp.ViewCount, tp.OwnerDisplayName, tp.PostTypeName
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.ViewCount,
    ps.OwnerDisplayName,
    ps.PostTypeName,
    ps.CommentCount,
    ps.UpVotes,
    ps.DownVotes,
    (ps.UpVotes - ps.DownVotes) AS Score
FROM 
    PostStats ps
ORDER BY 
    ps.ViewCount DESC, Score DESC;