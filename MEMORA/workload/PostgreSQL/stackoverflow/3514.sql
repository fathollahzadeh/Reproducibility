
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS RankByScore,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) OVER (PARTITION BY p.Id) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) OVER (PARTITION BY p.Id) AS DownVotes,
        p.OwnerUserId
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),
QualifiedPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.CommentCount,
        rp.UpVotes,
        rp.DownVotes,
        CASE 
            WHEN rp.Score >= 100 THEN 'Hot' 
            ELSE 'Regular' 
        END AS PostType,
        COALESCE(u.DisplayName, 'Anonymous') AS OwnerDisplayName
    FROM 
        RankedPosts rp
    LEFT JOIN 
        Users u ON rp.OwnerUserId = u.Id
    WHERE 
        rp.RankByScore = 1
),
PostHistories AS (
    SELECT 
        ph.PostId,
        ph.CreationDate AS EditDate,
        ph.Comment,
        ph.UserDisplayName
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6, 10, 11) 
        AND ph.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '6 months'
)
SELECT 
    qp.Title,
    qp.CreationDate,
    qp.Score,
    qp.ViewCount,
    qp.CommentCount,
    qp.UpVotes,
    qp.DownVotes,
    qp.PostType,
    qp.OwnerDisplayName,
    ph.EditDate,
    ph.Comment AS EditComment,
    ph.UserDisplayName AS EditorName
FROM 
    QualifiedPosts qp
LEFT JOIN 
    PostHistories ph ON qp.PostId = ph.PostId
ORDER BY 
    qp.Score DESC, qp.ViewCount DESC
LIMIT 100;
