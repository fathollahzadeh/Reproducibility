WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY u.Id ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
        AND p.Score > 0
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.OwnerDisplayName
    FROM 
        RankedPosts rp
    WHERE 
        rp.rn = 1
),
RecentVotes AS (
    SELECT 
        v.PostId,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotes
    FROM 
        Votes v
    WHERE 
        v.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days' 
    GROUP BY 
        v.PostId
)
SELECT 
    tp.Title,
    tp.CreationDate,
    tp.OwnerDisplayName,
    COALESCE(rv.UpVotes, 0) AS UpVotes,
    COALESCE(rv.DownVotes, 0) AS DownVotes,
    CASE 
        WHEN COALESCE(rv.UpVotes, 0) > COALESCE(rv.DownVotes, 0) THEN 'Positive Feedback'
        WHEN COALESCE(rv.UpVotes, 0) < COALESCE(rv.DownVotes, 0) THEN 'Negative Feedback'
        ELSE 'No Feedback'
    END AS FeedbackStatus
FROM 
    TopPosts tp
LEFT JOIN 
    RecentVotes rv ON tp.PostId = rv.PostId
ORDER BY 
    tp.Score DESC, 
    tp.CreationDate DESC
LIMIT 10;