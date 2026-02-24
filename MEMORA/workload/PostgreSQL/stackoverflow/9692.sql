WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER(PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS OwnerPostRank
    FROM Posts p
    JOIN Users u ON p.OwnerUserId = u.Id
    WHERE p.PostTypeId = 1 
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        rp.OwnerDisplayName
    FROM RankedPosts rp
    WHERE rp.OwnerPostRank <= 5
),
PostVotes AS (
    SELECT 
        v.PostId,
        vt.Name AS VoteType,
        COUNT(v.Id) AS VoteCount
    FROM Votes v
    JOIN VoteTypes vt ON v.VoteTypeId = vt.Id
    WHERE v.PostId IN (SELECT PostId FROM TopPosts)
    GROUP BY v.PostId, vt.Name
),
PostDetails AS (
    SELECT
        tp.PostId,
        tp.Title,
        tp.CreationDate,
        tp.ViewCount,
        tp.Score,
        tp.OwnerDisplayName,
        COALESCE(SUM(CASE WHEN pv.VoteType = 'UpMod' THEN pv.VoteCount ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN pv.VoteType = 'DownMod' THEN pv.VoteCount ELSE 0 END), 0) AS DownVotes
    FROM TopPosts tp
    LEFT JOIN PostVotes pv ON tp.PostId = pv.PostId
    GROUP BY tp.PostId, tp.Title, tp.CreationDate, tp.ViewCount, tp.Score, tp.OwnerDisplayName
)
SELECT 
    pd.PostId,
    pd.Title,
    pd.CreationDate,
    pd.ViewCount,
    pd.Score,
    pd.OwnerDisplayName,
    pd.UpVotes,
    pd.DownVotes,
    (pd.UpVotes - pd.DownVotes) AS NetVotes
FROM PostDetails pd
ORDER BY pd.Score DESC, pd.ViewCount DESC;