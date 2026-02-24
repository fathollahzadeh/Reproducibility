WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS RankByType
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE
        p.PostTypeId IN (1, 2) 
        AND p.Score > 0
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.OwnerDisplayName
    FROM 
        RankedPosts rp
    WHERE 
        rp.RankByType <= 5
),
PostWithVotes AS (
    SELECT 
        tp.*,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes
    FROM 
        TopPosts tp
    LEFT JOIN 
        Votes v ON tp.PostId = v.PostId
    GROUP BY 
        tp.PostId, tp.Title, tp.CreationDate, tp.Score, tp.ViewCount, tp.OwnerDisplayName
)
SELECT 
    pwv.PostId,
    pwv.Title,
    pwv.CreationDate,
    pwv.Score,
    pwv.ViewCount,
    pwv.OwnerDisplayName,
    pwv.UpVotes,
    pwv.DownVotes,
    (pwv.UpVotes - pwv.DownVotes) AS NetVotes
FROM 
    PostWithVotes pwv
ORDER BY 
    pwv.Score DESC, pwv.ViewCount DESC;
